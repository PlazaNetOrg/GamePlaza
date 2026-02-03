import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresenceForegroundService {
  static const MethodChannel _channel = MethodChannel('org.plazanet.gameplaza/presence');
  static const String _enabledKey = 'presence_foreground_service_enabled';
  static const String _baseUrlKey = 'plazanet_url';
  static const String _tokenKey = 'plazanet_auth_token';
  
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }
  
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
  
  static Future<bool> startService({
    required String gameName,
    int intervalSeconds = 30,
  }) async {
    try {
      if (!await isEnabled()) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString(_baseUrlKey) ?? 'https://accounts.plazanet.org';
      final token = prefs.getString(_tokenKey);
      
      if (token == null) {
        return false;
      }
      
      await _channel.invokeMethod('startPresenceService', {
        'baseUrl': baseUrl,
        'token': token,
        'game': gameName,
        'interval': intervalSeconds,
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopPresenceService');
    } catch (e) {}
  }
}
