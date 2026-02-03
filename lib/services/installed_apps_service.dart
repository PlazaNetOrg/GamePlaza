import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfo {
  final String name;
  final String packageName;
  final Uint8List? icon;

  AppInfo({
    required this.name,
    required this.packageName,
    this.icon,
  });
}

class InstalledAppsService {
  Future<List<AppInfo>> getAllApps({bool includeSystemApps = true}) async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: !includeSystemApps,
        withIcon: true,
      );
      
      apps.sort((a, b) => a.name.compareTo(b.name));
      
      return apps.map((app) {
        return AppInfo(
          name: app.name,
          packageName: app.packageName,
          icon: app.icon,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> launchApp(String packageName) async {
    try {
      final result = await InstalledApps.startApp(packageName);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> openAppSettings(String packageName) async {
    try {
      InstalledApps.openSettings(packageName);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uninstallApp(String packageName) async {
    try {
      final result = await InstalledApps.uninstallApp(packageName);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await InstalledApps.isAppInstalled(packageName);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<AppInfo?> getApp(String packageName) async {
    try {
      final app = await InstalledApps.getAppInfo(packageName);
      if (app == null) return null;
      
      return AppInfo(
        name: app.name,
        packageName: app.packageName,
        icon: app.icon,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> openAndroidSettings() async {
    try {
      const platform = MethodChannel('org.plazanet.gameplaza/android');
      await platform.invokeMethod('openSettings');
      return true;
    } catch (e) {
      return false;
    }
  }
}
