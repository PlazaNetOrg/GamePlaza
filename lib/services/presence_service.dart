import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
enum PresenceStatus { offline, online }

class PresenceService {
  static const String _defaultBaseUrl = 'https://accounts.plazanet.org';
  static const String _baseUrlKey = 'plazanet_url';
  static const String _tokenKey = 'plazanet_auth_token';
  static const String _overallPresenceEnabledKey = 'presence_overall_enabled';
  static const int _heartbeatSeconds = 20;

  Timer? _heartbeatTimer;
  PresenceStatus _currentStatus = PresenceStatus.offline;

  Future<bool> isOverallPresenceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_overallPresenceEnabledKey) ?? false;
  }

  Future<void> setOverallPresenceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_overallPresenceEnabledKey, enabled);
    if (!enabled) {
      await goOffline();
    }
  }

  Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasAuthToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await getAuthToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<http.Response> _postJson(String endpoint, Map<String, dynamic> body) async {
    final baseUrl = await getBaseUrl();
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
  }

  Future<http.Response> _get(String endpoint) async {
    final baseUrl = await getBaseUrl();
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  Future<String?> login(String baseUrl, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _sendHeartbeat() async {
    try {
      if (!await hasAuthToken()) return false;

      final body = {
        'client_type': 'gameplaza',
        'status': 'online',
      };

      final response = await _postJson('/api/presence/heartbeat', body);
      if (response.statusCode == 200) {
        _currentStatus = PresenceStatus.online;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _startLocalTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatSeconds),
      (_) => _sendHeartbeat(),
    );
  }

  Future<void> _setPresence() async {
    await stopHeartbeat();

    if (!await hasAuthToken() || !await isOverallPresenceEnabled()) {
      return;
    }

    _currentStatus = PresenceStatus.online;
    _startLocalTimer();
    await _sendHeartbeat();
  }

  Future<void> stopHeartbeat() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<bool> goOnline() async {
    await _setPresence();
    return true;
  }

  Future<void> goOffline() async {
    await stopHeartbeat();
    if (await hasAuthToken()) {
      await _postJson('/api/presence/update', {
        'status': 'offline',
        'client_type': 'gameplaza',
      });
      _currentStatus = PresenceStatus.offline;
    }
  }

  Future<Map<String, dynamic>?> getMyPresence() async {
    try {
      final response = await _get('/api/presence/me');
      return response.statusCode == 200 ? json.decode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserPresence(String username) async {
    try {
      final response = await _get('/api/presence/$username');
      return response.statusCode == 200 ? json.decode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  PresenceStatus get currentStatus => _currentStatus;
  void dispose() {
    stopHeartbeat();
  }
}
