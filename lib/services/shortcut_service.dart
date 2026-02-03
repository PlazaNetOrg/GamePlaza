import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ShortcutInfo {
  final String type;
  final String name;
  final String uri;
  final String? package;
  final String? iconUri;
  final String? action;
  final String? shortcutId;

  ShortcutInfo({
    required this.type,
    required this.name,
    required this.uri,
    this.package,
    this.iconUri,
    this.action,
    this.shortcutId,
  });

  factory ShortcutInfo.fromMap(Map<dynamic, dynamic> map) {
    return ShortcutInfo(
      type: map['type'] as String? ?? '',
      name: map['name'] as String? ?? '',
      uri: map['uri'] as String? ?? '',
      package: map['package'] as String?,
      iconUri: map['iconUri'] as String?,
      action: map['action'] as String?,
      shortcutId: map['id'] as String?,
    );
  }

  @override
  String toString() => 'ShortcutInfo(type: $type, name: $name, uri: $uri, package: $package, shortcutId: $shortcutId)';
}

class ShortcutService {
  static const _channel = MethodChannel('org.plazanet.gameplaza/shortcuts');
  static const _eventChannel = EventChannel('org.plazanet.gameplaza/shortcuts/events');
  
  static final ShortcutService _instance = ShortcutService._internal();
  factory ShortcutService() => _instance;
  ShortcutService._internal();

  final _shortcutController = StreamController<ShortcutInfo>.broadcast();
  Stream<ShortcutInfo> get onShortcutReceived => _shortcutController.stream;
  
  StreamSubscription? _eventSubscription;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final shortcut = ShortcutInfo.fromMap(event);
          _shortcutController.add(shortcut);
        }
      },
      onError: (error) {},
    );

    _checkPendingShortcut();
  }

  Future<void> _checkPendingShortcut() async {
    try {
      final result = await _channel.invokeMethod('getPendingShortcut');
      if (result != null && result is Map) {
        final shortcut = ShortcutInfo.fromMap(result);
        _shortcutController.add(shortcut);
      }
    } on PlatformException catch (e) {}
  }

  void dispose() {
    _eventSubscription?.cancel();
    _shortcutController.close();
  }

  Future<bool> startShortcut(String packageName, String shortcutId) async {
    try {
      final result = await _channel.invokeMethod('startShortcut', {
        'packageName': packageName,
        'shortcutId': shortcutId,
      });
      return result == true;
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<bool> unpinShortcut(String packageName, String shortcutId) async {
    try {
      final result = await _channel.invokeMethod('unpinShortcut', {
        'packageName': packageName,
        'shortcutId': shortcutId,
      });
      return result == true;
    } on PlatformException catch (e) {
      return false;
    }
  }
}
