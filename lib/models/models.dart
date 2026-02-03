import 'package:flutter/material.dart';

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({required this.icon, required this.label});
}

class ActionHint {
  final String button;
  final String label;

  const ActionHint({required this.button, required this.label});
}
