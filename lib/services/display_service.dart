import 'dart:async';
import 'package:flutter/services.dart';

class DisplayState {
  final int displayCount;
  final bool hasExternalDisplay;
  final bool isOnExternalDisplay;
  final int? currentDisplayId;
  final int? defaultDisplayId;

  const DisplayState({
    required this.displayCount,
    required this.hasExternalDisplay,
    required this.isOnExternalDisplay,
    this.currentDisplayId,
    this.defaultDisplayId,
  });

  factory DisplayState.fromMap(Map<dynamic, dynamic> map) {
    return DisplayState(
      displayCount: (map['displayCount'] as int?) ?? 1,
      hasExternalDisplay: (map['hasExternalDisplay'] as bool?) ?? false,
      isOnExternalDisplay: (map['isOnExternalDisplay'] as bool?) ?? false,
      currentDisplayId: map['currentDisplayId'] as int?,
      defaultDisplayId: map['defaultDisplayId'] as int?,
    );
  }
}

class DisplayService {
  static const MethodChannel _channel = MethodChannel('org.plazanet.gameplaza/display');
  static const EventChannel _eventChannel = EventChannel('org.plazanet.gameplaza/display/events');

  Future<DisplayState?> getDisplayState() async {
    try {
      final result = await _channel.invokeMethod('getDisplayState');
      if (result is Map) {
        return DisplayState.fromMap(result);
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  Stream<DisplayState> displayChanges() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return DisplayState.fromMap(event);
      }
      return const DisplayState(
        displayCount: 1,
        hasExternalDisplay: false,
        isOnExternalDisplay: false,
      );
    });
  }
}
