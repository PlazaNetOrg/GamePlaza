import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/display_service.dart';
import '../services/installed_apps_service.dart';
import '../services/notification_service.dart';
import '../services/system_controls_service.dart';
import '../theme/app_colors.dart';

class DesktopModeScreen extends StatefulWidget {
  const DesktopModeScreen({super.key});

  @override
  State<DesktopModeScreen> createState() => _DesktopModeScreenState();
}

class _DesktopModeScreenState extends State<DesktopModeScreen> {
  static const double _taskbarHeight = 56;
  static const String _shortcutsKey = 'desktop_shortcuts';

  final InstalledAppsService _appsService = InstalledAppsService();
  final DisplayService _displayService = DisplayService();
  final SystemControlsService _systemControlsService = SystemControlsService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();

  List<AppInfo> _apps = [];
  final Set<String> _shortcutPackages = {};
  bool _menuOpen = false;
  String _query = '';
  Timer? _timer;
  Timer? _systemStatusTimer;
  String _time = '';
  int? _displayId;
  StreamSubscription<DisplayState>? _displaySubscription;
  StreamSubscription<List<NotificationItem>>? _notificationSubscription;
  double _volume = 0.65;
  bool _muted = false;
  double _batteryLevel = 0.78;
  bool _charging = true;
  bool _notificationsOpen = false;
  bool _hasNotificationAccess = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
    _loadShortcuts();
    _updateTime();
    _refreshSystemStatus();
    _initNotifications();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
    _systemStatusTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshSystemStatus());
    _initDisplayTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _systemStatusTimer?.cancel();
    _displaySubscription?.cancel();
    _notificationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    final apps = await _appsService.getAllApps(includeSystemApps: true);
    if (!mounted) return;
    setState(() => _apps = apps);
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_shortcutsKey) ?? [];
    if (!mounted) return;
    setState(() => _shortcutPackages
      ..clear()
      ..addAll(items));
  }

  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shortcutsKey, _shortcutPackages.toList());
  }

  void _updateTime() {
    if (!mounted) return;
    final now = TimeOfDay.now();
    setState(() => _time = now.format(context));
  }

  void _initDisplayTracking() async {
    final state = await _displayService.getDisplayState();
    if (state != null && mounted) {
      setState(() => _displayId = state.currentDisplayId);
    }
    _displaySubscription = _displayService.displayChanges().listen((state) {
      if (!mounted) return;
      setState(() => _displayId = state.currentDisplayId);
    });
  }

  Future<void> _launchApp(AppInfo app) async {
    final success = await _appsService.launchAppOnDisplay(
      app.packageName,
      displayId: _displayId,
      requestFreeform: true,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to launch ${app.name}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<AppInfo> get _filteredApps {
    if (_query.isEmpty) return _apps;
    return _apps.where((app) => app.name.toLowerCase().contains(_query)).toList();
  }

  List<AppInfo> get _desktopShortcuts {
    final map = {for (final app in _apps) app.packageName: app};
    return _shortcutPackages
        .map((pkg) => map[pkg])
        .whereType<AppInfo>()
        .toList();
  }

  Future<void> _toggleShortcut(AppInfo app) async {
    setState(() {
      if (_shortcutPackages.contains(app.packageName)) {
        _shortcutPackages.remove(app.packageName);
      } else {
        _shortcutPackages.add(app.packageName);
      }
    });
    await _saveShortcuts();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(),
        _buildDesktopShortcuts(),
        if (_menuOpen) _buildAppMenu(),
        if (_notificationsOpen) _buildNotificationsPanel(),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildTaskbar(),
        ),
      ],
    );
  }

  Widget _buildDesktopShortcuts() {
    final shortcuts = _desktopShortcuts;
    if (shortcuts.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 24,
      left: 24,
      right: 24,
      bottom: _taskbarHeight + 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double tileWidth = 88;
          const double tileHeight = 104;
          const double spacing = 18;
          final availableHeight = constraints.maxHeight;
          final maxRows = ((availableHeight + spacing) / (tileHeight + spacing)).floor();
          final rows = maxRows < 1 ? 1 : maxRows;

          return Stack(
            children: [
              for (var i = 0; i < shortcuts.length; i++)
                Positioned(
                  left: (i ~/ rows) * (tileWidth + spacing),
                  top: (i % rows) * (tileHeight + spacing),
                  child: _buildShortcutTile(shortcuts[i]),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShortcutTile(AppInfo app) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _launchApp(app),
      onLongPressStart: (details) => _showAppContextMenuAt(app, details.globalPosition),
      onSecondaryTapDown: (details) => _showAppContextMenuAt(app, details.globalPosition),
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: app.icon != null
                  ? Image.memory(app.icon!, width: 36, height: 36)
                  : Icon(Icons.apps, color: AppColors.textSecondary, size: 34),
            ),
            const SizedBox(height: 6),
            Text(
              app.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(color: AppColors.darkSurface);
  }

  Widget _buildTaskbar() {
    return Container(
      height: _taskbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface.withOpacity(0.92),
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Apps',
            onPressed: () => setState(() => _menuOpen = !_menuOpen),
            icon: Icon(Icons.apps, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          _buildTaskbarRightArea(),
        ],
      ),
    );
  }

  Widget _buildTaskbarRightArea() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVolumeControl(),
        const SizedBox(width: 10),
        _buildStatusIcons(),
        const SizedBox(width: 12),
        Text(
          _time,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    final icon = _muted || _volume == 0
        ? Icons.volume_off
        : _volume < 0.5
            ? Icons.volume_down
            : Icons.volume_up;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Volume',
            onPressed: _toggleMuted,
            icon: Icon(icon, color: AppColors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 90,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: AppColors.secondaryBlue,
                inactiveTrackColor: AppColors.divider,
                thumbColor: AppColors.secondaryBlue,
              ),
              child: Slider(
                value: _muted ? 0 : _volume,
                onChanged: (value) => setState(() {
                  _volume = value;
                  if (_volume > 0) _muted = false;
                }),
                onChangeEnd: (value) => _setVolume(value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcons() {
    final batteryIcon = _charging
      ? Icons.battery_charging_full
      : _batteryLevel <= 0.2
        ? Icons.battery_alert
        : _batteryLevel <= 0.6
          ? Icons.battery_std
          : Icons.battery_full;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(batteryIcon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 4),
        Text(
          '${(_batteryLevel * 100).round()}%',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Notifications',
          onPressed: _toggleNotificationsPanel,
          icon: Icon(
            Icons.notifications_none,
            color: AppColors.textSecondary,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  Future<void> _refreshSystemStatus() async {
    final status = await _systemControlsService.getSystemStatus();
    if (!mounted || status == null) return;
    _applySystemStatus(status);
  }

  void _applySystemStatus(SystemControlState status) {
    setState(() {
      _volume = status.volume.clamp(0, 1);
      _muted = status.muted;
      _batteryLevel = status.batteryLevel.clamp(0, 1);
      _charging = status.charging;
    });
  }

  Future<void> _setVolume(double value) async {
    final status = await _systemControlsService.setVolume(value);
    if (!mounted || status == null) return;
    _applySystemStatus(status);
  }

  Future<void> _toggleMuted() async {
    final status = await _systemControlsService.setMuted(!_muted);
    if (!mounted || status == null) return;
    _applySystemStatus(status);
  }

  Future<void> _toggleNotificationsPanel() async {
    setState(() => _notificationsOpen = !_notificationsOpen);
    if (_notificationsOpen) {
      await _refreshNotifications();
    }
  }

  Future<void> _refreshNotifications() async {
    final hasAccess = await _notificationService.hasNotificationAccess();
    if (!mounted) return;
    setState(() => _hasNotificationAccess = hasAccess);
    if (!hasAccess) return;
    final items = await _notificationService.getNotifications();
    if (!mounted || items == null) return;
    setState(() => _notifications = items);
  }

  Future<void> _initNotifications() async {
    _notificationSubscription = _notificationService.notificationStream.listen((items) {
      if (!mounted) return;
      setState(() => _notifications = items);
    });
    await _refreshNotifications();
  }

  Widget _buildNotificationsPanel() {
    final maxHeight = math.min(MediaQuery.of(context).size.height * 0.5, 360.0);
    return Positioned(
      right: 16,
      bottom: _taskbarHeight + 12,
      child: Material(
        elevation: 10,
        color: AppColors.elevatedSurface.withOpacity(0.98),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 320,
          height: maxHeight,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text('Notifications', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => setState(() => _notificationsOpen = false),
                      icon: Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: !_hasNotificationAccess
                    ? _buildNotificationAccessPrompt()
                    : _notifications.isEmpty
                        ? Center(
                            child: Text('No notifications', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) => _buildNotificationTile(_notifications[index]),
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemCount: _notifications.length,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationAccessPrompt() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 30),
          const SizedBox(height: 12),
          Text(
            'Enable notification access to read system notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await _notificationService.openNotificationAccessSettings();
              await _refreshNotifications();
            },
            child: Text('Open settings', style: TextStyle(color: AppColors.secondaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    final time = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
    final timeLabel = TimeOfDay.fromDateTime(time).format(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.appName,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(timeLabel, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          if (item.title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          if (item.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.text, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildAppMenu() {
    final maxHeight = math.min(MediaQuery.of(context).size.height * 0.6, 520.0);
    return Positioned(
      left: 16,
      bottom: _taskbarHeight + 12,
      child: Material(
        elevation: 10,
        color: AppColors.elevatedSurface.withOpacity(0.98),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 420,
          height: maxHeight,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search apps',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: _filteredApps.isEmpty
                    ? Center(
                        child: Text(
                          'No apps found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _menuOpen = false);
                              _launchApp(app);
                            },
                            onLongPressStart: (details) => _showAppContextMenuAt(app, details.globalPosition),
                            onSecondaryTapDown: (details) => _showAppContextMenuAt(app, details.globalPosition),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  app.icon != null
                                      ? Image.memory(app.icon!, width: 40, height: 40)
                                      : Icon(Icons.apps, color: AppColors.textSecondary, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    app.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAppContextMenuAt(AppInfo app, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final isShortcut = _shortcutPackages.contains(app.packageName);
    final result = await showMenu<String>(
      context: context,
      color: AppColors.elevatedSurface,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'info',
          child: Row(
            children: [
              app.icon != null
                  ? Image.memory(app.icon!, width: 20, height: 20)
                  : Icon(Icons.apps, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text('App info', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'shortcut',
          child: Row(
            children: [
              Icon(
                isShortcut ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isShortcut ? 'Remove from desktop' : 'Add to desktop',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );

    if (result == 'info') {
      await _appsService.openAppSettings(app.packageName);
    } else if (result == 'shortcut') {
      await _toggleShortcut(app);
    }
  }

}