import 'package:flutter/services.dart';

class SystemControlState {
  final double volume;
  final bool muted;
  final double batteryLevel;
  final bool charging;

  const SystemControlState({
    required this.volume,
    required this.muted,
    required this.batteryLevel,
    required this.charging,
  });

  factory SystemControlState.fromMap(Map<dynamic, dynamic> map) {
    return SystemControlState(
      volume: (map['volume'] as num?)?.toDouble() ?? 0,
      muted: map['muted'] as bool? ?? false,
      batteryLevel: (map['batteryLevel'] as num?)?.toDouble() ?? 0,
      charging: map['charging'] as bool? ?? false,
    );
  }
}

class SystemControlsService {
  static const MethodChannel _channel = MethodChannel('org.plazanet.gameplaza/android');

  Future<SystemControlState?> getSystemStatus() async {
    try {
      final result = await _channel.invokeMethod('getSystemStatus');
      if (result is Map) {
        return SystemControlState.fromMap(result);
      }
    } on PlatformException {
      return null;
    }
    return null;
  }

  Future<SystemControlState?> setVolume(double value) async {
    try {
      final result = await _channel.invokeMethod('setVolume', {'value': value});
      if (result is Map) {
        return SystemControlState.fromMap(result);
      }
    } on PlatformException {
      return null;
    }
    return null;
  }

  Future<SystemControlState?> setMuted(bool muted) async {
    try {
      final result = await _channel.invokeMethod('setMuted', {'muted': muted});
      if (result is Map) {
        return SystemControlState.fromMap(result);
      }
    } on PlatformException {
      return null;
    }
    return null;
  }

}
