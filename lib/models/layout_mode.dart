enum LayoutMode {
  classic,
  handheld,
  compact,
}

const String layoutModePrefKey = 'ui_layout';

LayoutMode layoutModeFromString(String? value) {
  switch (value) {
    case 'compact':
      return LayoutMode.compact;
    case 'handheld':
      return LayoutMode.handheld;
    case 'classic':
    default:
      return LayoutMode.classic;
  }
}

String layoutModeToString(LayoutMode mode) {
  switch (mode) {
    case LayoutMode.handheld:
      return 'handheld';
    case LayoutMode.compact:
      return 'compact';
    case LayoutMode.classic:
    default:
      return 'classic';
  }
}