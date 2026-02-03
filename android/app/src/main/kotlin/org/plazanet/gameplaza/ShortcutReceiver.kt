package org.plazanet.gameplaza

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ShortcutReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        android.util.Log.d("GamePlaza", "ShortcutReceiver: action=${intent?.action}, extras=${intent?.extras?.keySet()?.joinToString()}")
        
        if (intent?.action == "com.android.launcher.action.INSTALL_SHORTCUT") {
            val forwardIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.android.launcher.action.INSTALL_SHORTCUT"
                if (intent.extras != null) {
                    putExtras(intent.extras!!)
                }
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            android.util.Log.d("GamePlaza", "ShortcutReceiver: Forwarding to MainActivity")
            context?.startActivity(forwardIntent)
        }
    }
}
