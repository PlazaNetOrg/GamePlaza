import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String heartbeatTaskName = 'presence_heartbeat_task';
const String heartbeatTaskId = 'presence_heartbeat';

class PresenceWorkManager {
  static Future<void> initializeWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> scheduleHeartbeatTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        heartbeatTaskId,
        heartbeatTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        initialDelay: const Duration(seconds: 30),
      );
    } catch (e) {}
  }

  static Future<void> cancelHeartbeatTask() async {
    try {
      await Workmanager().cancelByUniqueName(heartbeatTaskId);
    } catch (e) {}
  }

  static Future<void> sendHeartbeat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('plazanet_auth_token');
      final baseUrl = prefs.getString('plazanet_url');
      final currentGame = prefs.getString('current_game');

      if (token == null || token.isEmpty) {
        return;
      }

      final body = {
        'client_type': 'gameplaza',
        if (currentGame != null && currentGame.isNotEmpty) 'game': currentGame,
      };

      await http.post(
        Uri.parse('$baseUrl/api/presence/heartbeat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {}
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == heartbeatTaskName) {
        await PresenceWorkManager.sendHeartbeat();
      }
      return true;
    } catch (e) {
      return false;
    }
  });
}
