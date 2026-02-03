import 'package:flutter/services.dart';

class DeviceInfoData {
  final String? manufacturer;
  final String? model;
  final String? device;
  final String? brand;
  final String? androidVersion;
  final int? sdkInt;

  const DeviceInfoData({
    this.manufacturer,
    this.model,
    this.device,
    this.brand,
    this.androidVersion,
    this.sdkInt,
  });

  factory DeviceInfoData.fromMap(Map<dynamic, dynamic> map) {
    return DeviceInfoData(
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      device: map['device'] as String?,
      brand: map['brand'] as String?,
      androidVersion: map['androidVersion'] as String?,
      sdkInt: map['sdkInt'] as int?,
    );
  }

  String get displayName {
    final maker = (manufacturer ?? '').trim();
    final modelName = (model ?? '').trim();
    final combined = [maker, modelName].where((part) => part.isNotEmpty).join(' ');
    return combined.isNotEmpty ? combined : 'Android device';
  }
}

class SystemInfoService {
  static const MethodChannel _channel = MethodChannel('org.plazanet.gameplaza/android');

  Future<DeviceInfoData?> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod('getDeviceInfo');
      if (result is Map) {
        return DeviceInfoData.fromMap(result);
      }
      return null;
    } on PlatformException {
      return null;
    }
  }
}
