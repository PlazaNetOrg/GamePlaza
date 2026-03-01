enum LayoutMode {
  classic,
  handheld,
  compact,
  console,
}

const String layoutModePrefKey = 'ui_layout';

LayoutMode layoutModeFromString(String? value) {
  switch (value) {
    case 'compact':
      return LayoutMode.compact;
    case 'handheld':
      return LayoutMode.handheld;
    case 'console':
      return LayoutMode.console;
    case 'arcade':
      return LayoutMode.console;
    case 'classic':
    default:
      return LayoutMode.classic;
  }
}

String layoutModeToString(LayoutMode mode) {
  switch (mode) {
    case LayoutMode.classic:
      return 'classic';
    case LayoutMode.handheld:
      return 'handheld';
    case LayoutMode.compact:
      return 'compact';
    case LayoutMode.console:
      return 'console';
  }
}