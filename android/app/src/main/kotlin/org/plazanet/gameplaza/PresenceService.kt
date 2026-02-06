package org.plazanet.gameplaza

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

class PresenceService : Service() {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var heartbeatJob: Job? = null
    private lateinit var prefs: SharedPreferences
    
    companion object {
        const val CHANNEL_ID = "presence_service_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "START_PRESENCE"
        const val ACTION_STOP = "STOP_PRESENCE"
        
        const val EXTRA_BASE_URL = "base_url"
        const val EXTRA_TOKEN = "token"
        const val EXTRA_GAME = "game"
        const val EXTRA_INTERVAL = "interval"
        
        private const val TAG = "PresenceService"
        private const val PREFS_NAME = "presence_service_prefs"
        private const val PREF_BASE_URL = "base_url"
        private const val PREF_TOKEN = "token"
        private const val PREF_GAME = "game"
        private const val PREF_INTERVAL = "interval"
    }
    
    private var baseUrl: String? = null
    private var token: String? = null
    private var gameName: String? = null
    private var intervalSeconds: Int = 30
    private var screenReceiver: BroadcastReceiver? = null
    private var serviceStopped = false
    
    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        createNotificationChannel()
        registerScreenReceiver()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                serviceStopped = false
                baseUrl = intent.getStringExtra(EXTRA_BASE_URL)
                token = intent.getStringExtra(EXTRA_TOKEN)
                gameName = intent.getStringExtra(EXTRA_GAME)
                intervalSeconds = intent.getIntExtra(EXTRA_INTERVAL, 30)
                
                prefs.edit().apply {
                    baseUrl?.let { putString(PREF_BASE_URL, it) }
                    token?.let { putString(PREF_TOKEN, it) }
                    gameName?.let { putString(PREF_GAME, it) }
                    putInt(PREF_INTERVAL, intervalSeconds)
                    apply()
                }
                
                startForeground(NOTIFICATION_ID, createNotification())
                startHeartbeats()
                Log.d(TAG, "Service started for game: $gameName")
            }
            ACTION_STOP -> {
                serviceStopped = true
                stopHeartbeats()
                prefs.edit().clear().apply()
                stopForeground(true)
                stopSelf()
                Log.d(TAG, "Service stopped")
            }
            null -> {
                baseUrl = prefs.getString(PREF_BASE_URL, null)
                token = prefs.getString(PREF_TOKEN, null)
                gameName = prefs.getString(PREF_GAME, null)
                intervalSeconds = prefs.getInt(PREF_INTERVAL, 30)
                
                if (baseUrl != null && token != null && gameName != null) {
                    startForeground(NOTIFICATION_ID, createNotification())
                    startHeartbeats()
                    Log.d(TAG, "Service restarted for game: $gameName")
                } else {
                    stopSelf()
                }
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Game Presence",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Tracks your gaming activity on PlazaNet"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Playing on PlazaNet")
            .setContentText(gameName ?: "Playing a game")
            .setSmallIcon(android.R.drawable.ic_menu_upload)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    private fun startHeartbeats() {
        if (heartbeatJob?.isActive == true) return
        heartbeatJob = scope.launch {
            while (isActive && !serviceStopped) {
                sendHeartbeat()
                delay(intervalSeconds * 1000L)
            }
        }
    }
    
    private fun stopHeartbeats() {
        heartbeatJob?.cancel()
        heartbeatJob = null
    }

    private fun registerScreenReceiver() {
        if (screenReceiver != null) return
        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        stopHeartbeats()
                        Log.d(TAG, "Screen off - heartbeats paused")
                    }
                    Intent.ACTION_USER_PRESENT, Intent.ACTION_SCREEN_ON -> {
                        if (!serviceStopped) {
                            startHeartbeats()
                            Log.d(TAG, "Screen on - ensuring heartbeats active")
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)
    }
    
    private suspend fun sendHeartbeat() {
        try {
            val url = URL("$baseUrl/api/presence/heartbeat")
            val connection = url.openConnection() as HttpURLConnection
            
            connection.apply {
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Authorization", "Bearer $token")
                doOutput = true
                
                val jsonBody = JSONObject().apply {
                    put("client_type", "gameplaza")
                    put("status", if (!gameName.isNullOrEmpty()) "playing" else "online")
                    gameName?.let { put("game", it) }
                }
                
                outputStream.use { os ->
                    os.write(jsonBody.toString().toByteArray())
                }
                
                val responseCode = responseCode
                if (responseCode != 200) {
                    val errorBody = errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                    Log.e(TAG, "Heartbeat failed: $responseCode - $errorBody")
                }
            }
            
            connection.disconnect()
        } catch (e: Exception) {
            Log.e(TAG, "Heartbeat failed: ${e.message}")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopHeartbeats()
        scope.cancel()
        screenReceiver?.let { unregisterReceiver(it) }
        screenReceiver = null
    }
}
