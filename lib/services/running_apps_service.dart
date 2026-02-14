import 'package:flutter/services.dart';

class RunningAppInfo {
  final String packageName;
  final String label;

  const RunningAppInfo({
    required this.packageName,
    required this.label,
  });

  factory RunningAppInfo.fromMap(Map<dynamic, dynamic> map) {
    return RunningAppInfo(
      packageName: (map['packageName'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
    );
  }
}

class RunningAppsService {
  static const MethodChannel _channel = MethodChannel('org.plazanet.gameplaza/android');

  Future<bool> hasUsageAccess() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsageAccess');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException {
      return;
    }
  }

  Future<List<RunningAppInfo>> getRecentApps({int limit = 8}) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getRecentApps',
        {
          'limit': limit,
          'maxAgeMs': 120000,
        },
      );
      if (result == null) return [];
      return result
          .whereType<Map<dynamic, dynamic>>()
          .map(RunningAppInfo.fromMap)
          .where((app) => app.packageName.isNotEmpty)
          .toList();
    } on PlatformException {
      return [];
    }
  }
}
