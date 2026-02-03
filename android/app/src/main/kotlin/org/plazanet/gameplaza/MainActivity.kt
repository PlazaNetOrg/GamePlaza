package org.plazanet.gameplaza

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.LauncherApps
import android.content.pm.ShortcutInfo
import android.os.Build
import android.os.Bundle
import android.os.UserHandle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.plazanet.gameplaza/shortcuts"
    private val PRESENCE_CHANNEL = "org.plazanet.gameplaza/presence"
    private val ANDROID_CHANNEL = "org.plazanet.gameplaza/android"
    private var pendingShortcut: Map<String, Any?>? = null
    private var eventSink: EventChannel.EventSink? = null
    private var dynamicReceiver: BroadcastReceiver? = null
    private var launcherAppsCallback: LauncherApps.Callback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Android settings channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Presence service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRESENCE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPresenceService" -> {
                    val baseUrl = call.argument<String>("baseUrl")
                    val token = call.argument<String>("token")
                    val game = call.argument<String>("game")
                    val interval = call.argument<Int>("interval") ?: 30
                    
                    if (baseUrl != null && token != null && game != null) {
                        startPresenceService(baseUrl, token, game, interval)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing required parameters", null)
                    }
                }
                "stopPresenceService" -> {
                    stopPresenceService()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Method channel for one-time queries
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingShortcut" -> {
                    result.success(pendingShortcut)
                    pendingShortcut = null
                }
                "startShortcut" -> {
                    val packageName = call.argument<String>("packageName")
                    val shortcutId = call.argument<String>("shortcutId")
                    if (packageName != null && shortcutId != null) {
                        val success = startPinnedShortcut(packageName, shortcutId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "packageName and shortcutId required", null)
                    }
                }
                "unpinShortcut" -> {
                    val packageName = call.argument<String>("packageName")
                    val shortcutId = call.argument<String>("shortcutId")
                    if (packageName != null && shortcutId != null) {
                        val success = unpinShortcut(packageName, shortcutId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "packageName and shortcutId required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Event channel for streaming shortcuts
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "$CHANNEL/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingShortcut?.let {
                        eventSink?.success(it)
                        pendingShortcut = null
                    }
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerDynamicShortcutReceiver()
        registerLauncherAppsCallback()
        handleIntent(intent)
    }
    
    private fun registerLauncherAppsCallback() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
            
            launcherAppsCallback = object : LauncherApps.Callback() {
                override fun onPackageRemoved(packageName: String?, user: UserHandle?) {
                    android.util.Log.d("GamePlaza", "LauncherApps: Package removed: $packageName")
                }

                override fun onPackageAdded(packageName: String?, user: UserHandle?) {
                    android.util.Log.d("GamePlaza", "LauncherApps: Package added: $packageName")
                }

                override fun onPackageChanged(packageName: String?, user: UserHandle?) {
                    android.util.Log.d("GamePlaza", "LauncherApps: Package changed: $packageName")
                }

                override fun onPackagesAvailable(packageNames: Array<out String>?, user: UserHandle?, replacing: Boolean) {
                    android.util.Log.d("GamePlaza", "LauncherApps: Packages available: ${packageNames?.joinToString()}")
                }

                override fun onPackagesUnavailable(packageNames: Array<out String>?, user: UserHandle?, replacing: Boolean) {
                    android.util.Log.d("GamePlaza", "LauncherApps: Packages unavailable: ${packageNames?.joinToString()}")
                }

                override fun onShortcutsChanged(packageName: String, shortcuts: MutableList<ShortcutInfo>, user: UserHandle) {
                    android.util.Log.d("GamePlaza", "LauncherApps: Shortcuts changed for $packageName, count: ${shortcuts.size}")
                    for (shortcut in shortcuts) {
                        if (shortcut.isPinned) {
                            val fullShortcut = getFullShortcutInfo(packageName, shortcut.id, user)
                            val name = fullShortcut?.shortLabel?.toString() 
                                ?: fullShortcut?.longLabel?.toString() 
                                ?: shortcut.shortLabel?.toString()
                                ?: shortcut.longLabel?.toString()
                                ?: shortcut.id
                            
                            val shortcutData = mapOf(
                                "type" to "launcher_apps_shortcut",
                                "name" to name,
                                "uri" to (shortcut.intent?.toUri(0) ?: ""),
                                "package" to packageName,
                                "id" to shortcut.id
                            )
                            android.util.Log.d("GamePlaza", "LauncherApps: Pinned shortcut: $shortcutData")
                            sendShortcutData(shortcutData)
                        }
                    }
                }
            }
            
            try {
                launcherApps.registerCallback(launcherAppsCallback!!)
                android.util.Log.d("GamePlaza", "LauncherApps callback registered successfully")
            } catch (e: Exception) {
                android.util.Log.e("GamePlaza", "Failed to register LauncherApps callback: ${e.message}")
            }
        }
    }
    
    private fun registerDynamicShortcutReceiver() {
        dynamicReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                android.util.Log.d("GamePlaza", "Dynamic receiver: action=${intent?.action}")
                if (intent?.action == "com.android.launcher.action.INSTALL_SHORTCUT") {
                    handleInstallShortcutIntent(intent)
                }
            }
        }
        
        val filter = IntentFilter("com.android.launcher.action.INSTALL_SHORTCUT")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(dynamicReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(dynamicReceiver, filter)
        }
        android.util.Log.d("GamePlaza", "Dynamic shortcut receiver registered")
    }
    
    override fun onDestroy() {
        dynamicReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
            }
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            launcherAppsCallback?.let {
                try {
                    val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
                    launcherApps.unregisterCallback(it)
                } catch (e: Exception) {
                }
            }
        }
        
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        
        val action = intent.action
        val data = intent.data
        
        android.util.Log.d("GamePlaza", "Received intent: action=$action, data=$data, extras=${intent.extras?.keySet()?.joinToString()}")
        
        // Handle CREATE_SHORTCUT action (legacy shortcut creation)
        if (action == Intent.ACTION_CREATE_SHORTCUT) {
            val shortcutData = mapOf(
                "type" to "create_shortcut",
                "name" to (intent.getStringExtra(Intent.EXTRA_SHORTCUT_NAME) ?: ""),
                "uri" to (intent.getStringExtra("shortcut_uri") ?: data?.toString() ?: ""),
                "iconUri" to (intent.getStringExtra("shortcut_icon") ?: "")
            )
            android.util.Log.d("GamePlaza", "CREATE_SHORTCUT: $shortcutData")
            sendShortcutData(shortcutData)
        }
        
        // Handle pinned shortcut confirmation (Android 8.0+)
        else if (action == "android.content.pm.action.CONFIRM_PIN_SHORTCUT") {
            android.util.Log.d("GamePlaza", "CONFIRM_PIN_SHORTCUT received!")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val launcherApps = getSystemService(android.content.pm.LauncherApps::class.java)
                val pinRequest = launcherApps?.getPinItemRequest(intent)
                
                android.util.Log.d("GamePlaza", "Pin request: $pinRequest, shortcutInfo: ${pinRequest?.shortcutInfo}")
                
                if (pinRequest != null) {
                    val shortcutInfo = pinRequest.shortcutInfo
                    if (shortcutInfo != null) {
                        val shortcutData = mapOf(
                            "type" to "pin_shortcut",
                            "name" to (shortcutInfo.shortLabel?.toString() ?: shortcutInfo.longLabel?.toString() ?: ""),
                            "uri" to (shortcutInfo.intent?.toUri(0) ?: ""),
                            "package" to (shortcutInfo.`package` ?: ""),
                            "id" to shortcutInfo.id
                        )
                        android.util.Log.d("GamePlaza", "PIN_SHORTCUT: $shortcutData")
                        sendShortcutData(shortcutData)
                        val accepted = pinRequest.accept()
                        android.util.Log.d("GamePlaza", "Pin request accepted: $accepted")
                    }
                }
            }
        }
        
        else if (action == Intent.ACTION_VIEW && data != null && data.scheme == "gameplaza") {
            val shortcutData = mapOf(
                "type" to "launch_shortcut",
                "name" to (data.getQueryParameter("name") ?: ""),
                "uri" to (data.getQueryParameter("uri") ?: data.toString()),
                "package" to (data.getQueryParameter("package") ?: "")
            )
            android.util.Log.d("GamePlaza", "VIEW_SHORTCUT: $shortcutData")
            sendShortcutData(shortcutData)
        }
        
        else if (action == "com.android.launcher.action.INSTALL_SHORTCUT") {
            handleInstallShortcutIntent(intent)
        }
        
        else if (action == Intent.ACTION_MAIN && intent.hasExtra("shortcut_name")) {
            val shortcutData = mapOf(
                "type" to "main_shortcut",
                "name" to (intent.getStringExtra("shortcut_name") ?: ""),
                "uri" to (intent.getStringExtra("shortcut_uri") ?: ""),
                "package" to (intent.getStringExtra("shortcut_package") ?: "")
            )
            android.util.Log.d("GamePlaza", "MAIN_SHORTCUT: $shortcutData")
            sendShortcutData(shortcutData)
        }
    }
    
    private fun handleInstallShortcutIntent(intent: Intent) {
        val name = intent.getStringExtra(Intent.EXTRA_SHORTCUT_NAME) ?: ""
        @Suppress("DEPRECATION")
        val shortcutIntent = intent.getParcelableExtra<Intent>(Intent.EXTRA_SHORTCUT_INTENT)
        
        val shortcutData = mapOf(
            "type" to "install_shortcut",
            "name" to name,
            "uri" to (shortcutIntent?.dataString ?: shortcutIntent?.toUri(0) ?: ""),
            "package" to (shortcutIntent?.`package` ?: shortcutIntent?.component?.packageName ?: ""),
            "action" to (shortcutIntent?.action ?: "")
        )
        android.util.Log.d("GamePlaza", "INSTALL_SHORTCUT: $shortcutData")
        sendShortcutData(shortcutData)
    }
    
    private fun sendShortcutData(data: Map<String, Any?>) {
        if (eventSink != null) {
            runOnUiThread {
                eventSink?.success(data)
            }
        } else {
            pendingShortcut = data
        }
    }
    
    private fun startPinnedShortcut(packageName: String, shortcutId: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            try {
                val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
                val userHandle = android.os.Process.myUserHandle()
                
                android.util.Log.d("GamePlaza", "Starting shortcut: package=$packageName, id=$shortcutId")
                
                launcherApps.startShortcut(packageName, shortcutId, null, null, userHandle)
                return true
            } catch (e: Exception) {
                android.util.Log.e("GamePlaza", "Failed to start shortcut: ${e.message}")
                return false
            }
        }
        return false
    }
    
    private fun unpinShortcut(packageName: String, shortcutId: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            try {
                val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
                val userHandle = android.os.Process.myUserHandle()
                val query = LauncherApps.ShortcutQuery()
                    .setPackage(packageName)
                    .setQueryFlags(LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED)
                
                val pinnedShortcuts = launcherApps.getShortcuts(query, userHandle) ?: emptyList()
                val remainingIds = pinnedShortcuts
                    .filter { it.id != shortcutId }
                    .map { it.id }
                
                android.util.Log.d("GamePlaza", "Unpinning shortcut: package=$packageName, id=$shortcutId, remaining=${remainingIds.size}")
                
                launcherApps.pinShortcuts(packageName, remainingIds, userHandle)
                return true
            } catch (e: Exception) {
                android.util.Log.e("GamePlaza", "Failed to unpin shortcut: ${e.message}")
                return false
            }
        }
        return false
    }
    
    private fun getFullShortcutInfo(packageName: String, shortcutId: String, user: UserHandle): ShortcutInfo? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            try {
                val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
                val query = LauncherApps.ShortcutQuery()
                    .setPackage(packageName)
                    .setShortcutIds(listOf(shortcutId))
                    .setQueryFlags(
                        LauncherApps.ShortcutQuery.FLAG_MATCH_DYNAMIC or
                        LauncherApps.ShortcutQuery.FLAG_MATCH_MANIFEST or
                        LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED
                    )
                
                val shortcuts = launcherApps.getShortcuts(query, user)
                return shortcuts?.firstOrNull()
            } catch (e: Exception) {
                android.util.Log.e("GamePlaza", "Failed to get shortcut info: ${e.message}")
            }
        }
        return null
    }
    
    private fun startPresenceService(baseUrl: String, token: String, game: String, interval: Int) {
        val intent = Intent(this, PresenceService::class.java).apply {
            action = PresenceService.ACTION_START
            putExtra(PresenceService.EXTRA_BASE_URL, baseUrl)
            putExtra(PresenceService.EXTRA_TOKEN, token)
            putExtra(PresenceService.EXTRA_GAME, game)
            putExtra(PresenceService.EXTRA_INTERVAL, interval)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun stopPresenceService() {
        val intent = Intent(this, PresenceService::class.java).apply {
            action = PresenceService.ACTION_STOP
        }
        startService(intent)
    }
}
