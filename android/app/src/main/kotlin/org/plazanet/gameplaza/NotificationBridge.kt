package org.plazanet.gameplaza

import io.flutter.plugin.common.EventChannel

object NotificationBridge {
    private var eventSink: EventChannel.EventSink? = null
    private var notifications: List<Map<String, Any?>> = emptyList()

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        if (sink != null) {
            sink.success(notifications)
        }
    }

    fun updateNotifications(items: List<Map<String, Any?>>) {
        notifications = items
        eventSink?.success(items)
    }

    fun getNotifications(): List<Map<String, Any?>> = notifications
}
