import 'dart:async';

import 'package:flutter/services.dart';

class NotificationItem {
  final String key;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final int timestamp;

  const NotificationItem({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.timestamp,
  });

  factory NotificationItem.fromMap(Map<dynamic, dynamic> map) {
    return NotificationItem(
      key: map['key'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }
}

class NotificationService {
  static const MethodChannel _channel = MethodChannel('org.plazanet.gameplaza/notifications');
  static const EventChannel _eventChannel = EventChannel('org.plazanet.gameplaza/notifications/events');

  Stream<List<NotificationItem>> get notificationStream async* {
    final stream = _eventChannel.receiveBroadcastStream();
    await for (final event in stream) {
      if (event is List) {
        yield event
            .whereType<Map>()
            .map((item) => NotificationItem.fromMap(item))
            .toList();
      }
    }
  }

  Future<List<NotificationItem>?> getNotifications() async {
    try {
      final result = await _channel.invokeMethod('getNotifications');
      if (result is List) {
        return result
            .whereType<Map>()
            .map((item) => NotificationItem.fromMap(item))
            .toList();
      }
    } on PlatformException {
      return null;
    }
    return null;
  }

  Future<bool> hasNotificationAccess() async {
    try {
      final result = await _channel.invokeMethod('hasNotificationAccess');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> openNotificationAccessSettings() async {
    try {
      final result = await _channel.invokeMethod('openNotificationAccessSettings');
      return result == true;
    } on PlatformException {
      return false;
    }
  }
}
