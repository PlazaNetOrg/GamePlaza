import 'package:flutter/material.dart';

class NavigationItem {
  final IconData? icon;
  final String? assetPath;
  final String label;

  const NavigationItem({this.icon, this.assetPath, required this.label})
      : assert(icon != null || assetPath != null);
}

class ActionHint {
  final String button;
  final String label;

  const ActionHint({required this.button, required this.label});
}
