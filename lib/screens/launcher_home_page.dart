import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../models/models.dart';
import '../dialogs/game_dialogs.dart';
import '../dialogs/game_detail_dialog.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'plaza_net_screen.dart';
import 'store_screen.dart';
import 'settings_screen.dart';
import '../models/layout_mode.dart';
import '../services/game_library_service.dart';
import '../services/game_art_service.dart';
import '../services/installed_apps_service.dart';
import '../services/shortcut_service.dart';
import '../services/presence_service.dart';
import '../services/display_service.dart';
import '../shortcuts/app_intents.dart';
import 'package:collection/collection.dart';
import '_widgets/sidebar_widget.dart';
import '_widgets/top_bar_widget.dart';
import '_widgets/action_guide_widget.dart';
import '../l10n/app_localizations.dart';
import '../widgets/profile_avatar.dart';
import 'desktop_mode_screen.dart';

class LauncherHomePage extends StatefulWidget {
  const LauncherHomePage({super.key});

  @override
  State<LauncherHomePage> createState() => _LauncherHomePageState();
}

class _LauncherHomePageState extends State<LauncherHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Services
  final GameLibraryService _libraryService = GameLibraryService();
  final InstalledAppsService _appsService = InstalledAppsService();
  final GameArtService _gameArtService = GameArtService();
  final ShortcutService _shortcutService = ShortcutService();
  final PresenceService _presenceService = PresenceService();
  final DisplayService _displayService = DisplayService();

  // Game data
  List<Game> _games = [];
  List<AppInfo> _installedApps = [];
  Game? _selectedGame;

  // UI State
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _appsSearchQuery = '';
  bool _isLoading = true;
  bool _isLoadingApps = true;
  String? _userName;
  String? _apiKey;
  bool _showGameStreaming = false;
  bool _showVideoStreaming = false;
  LayoutMode _layoutMode = LayoutMode.classic;
  bool _useHomeAsLibrary = false;
  List<String> _gameStreamingApps = [];
  List<String> _videoStreamingApps = [];
  late TabController _tabController;
  final FocusNode _playButtonFocusNode = FocusNode();

  // Sidebar state
  String _currentTime = '';
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  Timer? _timer;
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;
  StreamSubscription<ShortcutInfo>? _shortcutSubscription;
  StreamSubscription<DisplayState>? _displaySubscription;
  bool _isAppActive = true;

  // Desktop mode
  bool _desktopMode = false;

  // Play session tracking
  static const String _playSessionStartKey = 'play_session_start_ms';
  static const String _playSessionGameIdKey = 'play_session_game_id';
  DateTime? _playSessionStart;
  String? _playSessionGameId;
  
  // Streaming app covers cache
  final Map<String, String?> _streamingAppCoversCache = {};
  final Map<String, String?> _streamingAppIconsCache = {};
  final Map<String, String> _streamingAppNamesCache = {};

  List<NavigationItem> _navItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      NavigationItem(assetPath: 'assets/images/home.png', label: l10n.navHome),
      if (!_useHomeAsLibrary)
        NavigationItem(assetPath: 'assets/images/library.png', label: l10n.navLibrary),
      NavigationItem(assetPath: 'assets/images/plazanet.png', label: l10n.navPlazaNet),
      NavigationItem(assetPath: 'assets/images/store.png', label: l10n.navStore),
      NavigationItem(assetPath: 'assets/images/settings.png', label: l10n.navSettings),
    ];
    return items;
  }

  Widget _buildNavIcon(NavigationItem item, {required bool isSelected, double size = 24}) {
    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        width: size + 4,
        height: size + 4,
        fit: BoxFit.contain,
      );
    }
    final color = isSelected ? Colors.white : AppColors.textPrimary;
    return Icon(
      item.icon,
      size: size + 4,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => mounted ? setState(() {}) : null);

    _loadLibrary();
    _loadInstalledApps();
    _loadStreamingSettings();
    _loadStreamingApps();
    _loadLayoutMode();
    _updateTime();
    _updateBattery();
    _initShortcutService();
    _initDisplayMode();
    _restorePendingPlaySession();
    _updatePresenceForSelectedTab();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _batteryState = state);
      _updateBattery();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _batterySubscription?.cancel();
    _shortcutSubscription?.cancel();
    _displaySubscription?.cancel();
    _tabController.dispose();
    _playButtonFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initShortcutService() {
    _shortcutService.initialize();
    _shortcutSubscription = _shortcutService.onShortcutReceived.listen((info) {
      if (info.type == 'pin_shortcut' && info.package != null && info.shortcutId != null) {
        _addGameFromShortcut(info);
        return;
      }

      final game = _games.firstWhereOrNull((g) {
        if (g.packageName != info.package) return false;
        if (info.shortcutId != null && g.shortcutId != null) {
          return g.shortcutId == info.shortcutId;
        }
        return g.shortcutId == null;
      });
      if (game != null) _launchGame(game);
    });
  }

  void _initDisplayMode() async {
    final state = await _displayService.getDisplayState();
    if (state != null && mounted) {
      _applyDisplayState(state);
    }
    _displaySubscription = _displayService.displayChanges().listen((state) {
      if (!mounted) return;
      _applyDisplayState(state);
    });
  }

  void _applyDisplayState(DisplayState state) {
    setState(() {
      _desktopMode = state.isOnExternalDisplay;
    });
  }

  Future<void> _addGameFromShortcut(ShortcutInfo info) async {
    final packageName = info.package;
    final shortcutId = info.shortcutId;
    if (packageName == null || shortcutId == null) return;

    final gameId = '$packageName.$shortcutId';
    final existing = _games.firstWhereOrNull((g) => g.id == gameId);
    if (existing != null) {
      final updated = existing.copyWith(title: info.name);
      await _libraryService.updateGame(updated);
    } else {
      final newGame = Game(
        id: gameId,
        title: info.name,
        coverUrl: '',
        bannerUrl: '',
        playTimeSeconds: 0,
        packageName: packageName,
        shortcutId: shortcutId,
      );
      await _libraryService.addGame(newGame);
    }
    await _loadLibrary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).msgShortcutAdded}: ${info.name}'),
          backgroundColor: AppColors.elevatedSurface,
        ),
      );
    }
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() => _currentTime = DateFormat('HH:mm').format(DateTime.now()));
  }

  Future<void> _updateBattery() async {
    final level = await _battery.batteryLevel;
    if (!mounted) return;
    setState(() => _batteryLevel = level);
  }

  Future<void> _loadLibrary() async {
    final games = await _libraryService.loadGames();
    final userName = await _libraryService.getUserName();
    final apiKey = await _libraryService.loadApiKey();
    if (!mounted) return;
    setState(() {
      _games = games;
      _userName = userName;
      _apiKey = apiKey;
      _isLoading = false;
    });
  }

  Future<void> _loadInstalledApps() async {
    final apps = await _appsService.getAllApps();
    if (!mounted) return;
    setState(() {
      _installedApps = apps;
      _isLoadingApps = false;
    });
  }

  Future<void> _loadStreamingSettings() async {
    final gameStreaming = await _libraryService.isGameStreamingEnabled();
    final videoStreaming = await _libraryService.isVideoStreamingEnabled();
    if (!mounted) return;

    _applyStreamingTabSettings(gameStreaming, videoStreaming);
  }

  Future<void> _loadStreamingApps() async {
    final gameApps = await _libraryService.getGameStreamingApps();
    final videoApps = await _libraryService.getVideoStreamingApps();
    if (!mounted) return;
    setState(() {
      _gameStreamingApps = gameApps;
      _videoStreamingApps = videoApps;
    });
    await _loadStreamingAppCovers();
    await _loadStreamingAppIcons();
    await _loadStreamingAppNames();
  }

  Future<void> _reloadAppData() async {
    await _loadLibrary();
    await _loadStreamingSettings();
    await _loadStreamingApps();
    await _loadLayoutMode();
  }

  Future<void> _loadLayoutMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(layoutModePrefKey);
    final useHomeAsLibrary = prefs.getBool('use_home_as_library') ?? false;
    if (!mounted) return;
    final previousUseHomeAsLibrary = _useHomeAsLibrary;
    setState(() {
      _layoutMode = layoutModeFromString(raw);
      _useHomeAsLibrary = useHomeAsLibrary;
    });
    if (previousUseHomeAsLibrary != _useHomeAsLibrary) {
      final mappedIndex = _useHomeAsLibrary
          ? (_selectedIndex == 0 ? 0 : _selectedIndex - 1)
          : (_selectedIndex == 0 ? 0 : _selectedIndex + 1);
      setState(() => _selectedIndex = mappedIndex);
    }
    final maxIndex = _navItems(context).length - 1;
    if (_selectedIndex > maxIndex) {
      setState(() => _selectedIndex = maxIndex);
    }
    _updatePresenceForSelectedTab();
  }

  void _applyStreamingTabSettings(bool gameStreaming, bool videoStreaming) {
    final showStreaming = gameStreaming || videoStreaming;
    final tabCount = showStreaming ? 3 : 2;

    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
      _tabController.addListener(() => mounted ? setState(() {}) : null);
    }

    setState(() {
      _showGameStreaming = gameStreaming;
      _showVideoStreaming = videoStreaming;
    });
  }

  Future<void> _addStreamingApp(AppInfo app, bool isGameStreaming, String displayName) async {
    if (isGameStreaming) {
      await _libraryService.addGameStreamingApp(app.packageName);
    } else {
      await _libraryService.addVideoStreamingApp(app.packageName);
    }
    await _libraryService.setStreamingAppName(app.packageName, displayName);
    _streamingAppNamesCache[app.packageName] = displayName;
    await _loadStreamingApps();
  }

  Future<void> _removeStreamingApp(AppInfo app, bool isGameStreaming) async {
    if (isGameStreaming) {
      await _libraryService.removeGameStreamingApp(app.packageName);
    } else {
      await _libraryService.removeVideoStreamingApp(app.packageName);
    }
    await _libraryService.removeStreamingAppName(app.packageName);
    await _libraryService.setStreamingAppCoverPath(app.packageName, null);
    _streamingAppNamesCache.remove(app.packageName);
    _streamingAppCoversCache.remove(app.packageName);
    await _loadStreamingApps();
  }

  Future<void> _setStreamingAppCover(AppInfo app, String? coverPath) async {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    
    final useIcon = _layoutMode == LayoutMode.handheld || _layoutMode == LayoutMode.compact;
    
    showDialog(
      context: context,
      builder: (context) => useIcon
          ? IconPickerDialog(
              apiKey: _apiKey!,
              appName: app.name,
              packageName: app.packageName,
              onIconSelected: (url) async {
                try {
                  final savedPath = await _gameArtService.saveGameArt(
                    gameId: app.packageName,
                    imageUrl: url,
                    type: GameArtType.icon,
                  );
                  await _libraryService.setStreamingAppIconPath(app.packageName, savedPath);
                  
                  if (mounted) {
                    setState(() {
                      _streamingAppIconsCache[app.packageName] = savedPath;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).gameDialogsIconUpdated),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${AppLocalizations.of(context).msgArtworkError}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            )
          : CoverPickerDialog(
              apiKey: _apiKey!,
              appName: app.name,
              packageName: app.packageName,
              onCoverSelected: (url) async {
                try {
                  final savedPath = await _gameArtService.saveGameArt(
                    gameId: app.packageName,
                    imageUrl: url,
                    type: GameArtType.cover,
                  );
                  await _libraryService.setStreamingAppCoverPath(app.packageName, savedPath);
                  
                  if (mounted) {
                    setState(() {
                      _streamingAppCoversCache[app.packageName] = savedPath;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).gameDialogsCoverUpdated),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${AppLocalizations.of(context).msgArtworkError}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
    );
  }

  void _restorePendingPlaySession() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_playSessionStartKey);
    if (startMs != null) {
      _playSessionStart = DateTime.fromMillisecondsSinceEpoch(startMs);
      _playSessionGameId = prefs.getString(_playSessionGameIdKey);
      await _completePlaySession();
    }
  }

  bool _isPlazaNetSelected() {
    return _selectedIndex == (_useHomeAsLibrary ? 1 : 2);
  }

  Future<void> _updatePresenceForSelectedTab() async {
    if (!_isAppActive) return;
    if (_isPlazaNetSelected()) {
      await _presenceService.goOnline();
    } else {
      await _presenceService.goOffline();
    }
  }

  Future<void> _launchGame(Game game) async {
    await _startPlaySession(game);
    await _markGamePlayed(game);

    if (game.packageName != null) {
      final success = game.shortcutId != null
          ? await _shortcutService.startShortcut(game.packageName!, game.shortcutId!)
          : false;
      if (!success) await _appsService.launchApp(game.packageName!);
    }
  }

  Future<void> _addGameFromApp(String title, String packageName) async {
    final gameId = packageName;
    final existing = _games.firstWhereOrNull((g) => g.id == gameId);
    if (existing != null) {
      final updated = existing.copyWith(title: title);
      await _libraryService.updateGame(updated);
    } else {
      final newGame = Game(
        id: gameId,
        title: title,
        coverUrl: '',
        bannerUrl: '',
        playTimeSeconds: 0,
        packageName: packageName,
      );
      await _libraryService.addGame(newGame);
    }
    await _loadLibrary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).msgGameAdded),
          backgroundColor: AppColors.elevatedSurface,
        ),
      );
    }
  }

  Future<void> _startPlaySession(Game game) async {
    _playSessionStart = DateTime.now();
    _playSessionGameId = game.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playSessionStartKey, _playSessionStart!.millisecondsSinceEpoch);
    await prefs.setString(_playSessionGameIdKey, _playSessionGameId!);
  }

  Future<void> _completePlaySession() async {
    final prefs = await SharedPreferences.getInstance();
    final start = _playSessionStart ?? 
        (prefs.getInt(_playSessionStartKey) != null
            ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_playSessionStartKey)!)
            : null);
    final gameId = _playSessionGameId ?? prefs.getString(_playSessionGameIdKey);
    if (start == null || gameId == null) return;

    _playSessionStart = null;
    _playSessionGameId = null;
    await prefs.remove(_playSessionStartKey);
    await prefs.remove(_playSessionGameIdKey);

    final elapsed = DateTime.now().difference(start).inSeconds;
    if (elapsed <= 0) return;

    final games = await _libraryService.loadGames();
    final game = games.firstWhereOrNull((g) => g.id == gameId);
    if (game != null) {
      final updated = game.copyWith(playTimeSeconds: game.playTimeSeconds + elapsed);
      await _libraryService.updateGame(updated);
      await _loadLibrary();
      if (mounted && _selectedGame?.id == updated.id) {
        setState(() => _selectedGame = updated);
      }
    }
  }

  Future<void> _markGamePlayed(Game game) async {
    final updated = game.copyWith(lastPlayed: DateTime.now());
    await _libraryService.updateGame(updated);
    await _loadLibrary();
  }

  Future<Game?> _updateGameArt(Game game, String imageUrl, GameArtType type) async {
    try {
      final deletePath = type == GameArtType.cover
          ? game.localCoverPath
          : type == GameArtType.banner
              ? game.localBannerPath
              : game.localIconPath;
      if (deletePath != null) await _gameArtService.deleteArt(deletePath);

      final savedPath = await _gameArtService.saveGameArt(
        gameId: game.id,
        imageUrl: imageUrl,
        type: type,
      );

        final updated = type == GameArtType.cover
          ? game.copyWith(coverUrl: imageUrl, localCoverPath: savedPath)
          : type == GameArtType.banner
            ? game.copyWith(bannerUrl: imageUrl, localBannerPath: savedPath)
            : game.copyWith(iconUrl: imageUrl, localIconPath: savedPath);

      await _libraryService.updateGame(updated);
      await _loadLibrary();
      if (mounted && _selectedGame?.id == updated.id) {
        setState(() => _selectedGame = updated);
      }
      return updated;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).msgArtworkError}: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  ImageProvider? _coverImage(Game game) {
    if (game.localCoverPath != null) {
      return FileImage(File(game.localCoverPath!));
    }
    return null;
  }

  ImageProvider? _iconImage(Game game) {
    if (game.localIconPath != null) {
      final file = File(game.localIconPath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    if (game.packageName != null) {
      final app = _installedApps.firstWhereOrNull((a) => a.packageName == game.packageName);
      if (app?.icon != null) {
        return MemoryImage(app!.icon!);
      }
    }
    return null;
  }

  ImageProvider? _streamingAppCoverImage(AppInfo app) {
    final coverPath = _streamingAppCoversCache[app.packageName];
    if (coverPath != null) {
      final file = File(coverPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  ImageProvider? _streamingAppIconImage(AppInfo app) {
    final iconPath = _streamingAppIconsCache[app.packageName];
    if (iconPath != null) {
      final file = File(iconPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  String _streamingAppDisplayName(AppInfo app) {
    return _streamingAppNamesCache[app.packageName] ?? app.name;
  }

  Future<void> _loadStreamingAppCovers() async {
    for (final packageName in [..._gameStreamingApps, ..._videoStreamingApps]) {
      final coverPath = await _libraryService.getStreamingAppCoverPath(packageName);
      _streamingAppCoversCache[packageName] = coverPath;
    }
  }

  Future<void> _loadStreamingAppIcons() async {
    for (final packageName in [..._gameStreamingApps, ..._videoStreamingApps]) {
      final iconPath = await _libraryService.getStreamingAppIconPath(packageName);
      _streamingAppIconsCache[packageName] = iconPath;
    }
  }

  Future<void> _loadStreamingAppNames() async {
    final names = await _libraryService.getStreamingAppNames();
    _streamingAppNamesCache
      ..clear()
      ..addAll(names);
  }

  String _formatLastPlayed(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  void _openGameDetail(Game game) {
    setState(() => _selectedGame = game);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_playButtonFocusNode.canRequestFocus) {
        _playButtonFocusNode.requestFocus();
      }
    });
  }

  Future<void> _showSearchDialog(String title, ValueChanged<String> onApply) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Type to filter...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ''), child: Text(AppLocalizations.of(context).actionClear)),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(AppLocalizations.of(context).actionApply)),
        ],
      ),
    );
    if (result != null && mounted) {
      onApply(result.trim().toLowerCase());
    }
    controller.dispose();
  }

  List<ActionHint> _currentActionHints() {
    final isLibraryScreen = _useHomeAsLibrary ? (_selectedIndex == 0) : (_selectedIndex == 1);
    
    if (!isLibraryScreen) return [];
    if (_tabController.index == 1) {
      return [
        ActionHint(button: 'A', label: AppLocalizations.of(context).actionOpenApp),
        ActionHint(button: 'X', label: AppLocalizations.of(context).actionReload),
        ActionHint(button: 'Y', label: AppLocalizations.of(context).actionSearch),
      ];
    }
    return [
      ActionHint(button: 'A', label: AppLocalizations.of(context).actionOpen),
      ActionHint(button: 'Y', label: AppLocalizations.of(context).actionSearch),
    ];
  }

  List<ActionHint> _detailActionHints() {
    final canLaunch = _selectedGame != null &&
        (_selectedGame!.packageName != null || _selectedGame!.shortcutId != null);
    return canLaunch
        ? [ActionHint(button: 'A', label: AppLocalizations.of(context).actionPlay), ActionHint(button: 'B', label: AppLocalizations.of(context).actionBack)]
        : [ActionHint(button: 'B', label: AppLocalizations.of(context).actionBack)];
  }

  void _setBannerForGameDetail(Game game) {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => BannerPickerDialog(
        apiKey: _apiKey!,
        appName: game.title,
        packageName: game.packageName ?? game.title,
        imageType: ImageType.hero,
        onBannerSelected: (url) => _updateGameArt(game, url, GameArtType.banner),
      ),
    );
  }

  void _setCoverForGameDetail(Game game) {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => CoverPickerDialog(
        apiKey: _apiKey!,
        appName: game.title,
        packageName: game.packageName ?? game.title,
        onCoverSelected: (url) => _updateGameArt(game, url, GameArtType.cover),
      ),
    );
  }

  void _setIconForGameDetail(Game game) {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => IconPickerDialog(
        apiKey: _apiKey!,
        appName: game.title,
        packageName: game.packageName ?? game.title,
        onIconSelected: (url) => _updateGameArt(game, url, GameArtType.icon),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isAppActive = false;
      _presenceService.goOffline();
    } else if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      if (_playSessionStart != null || _playSessionGameId != null) {
        unawaited(_completePlaySession());
      } else {
        _updatePresenceForSelectedTab();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(TraversalDirection.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(TraversalDirection.down),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(TraversalDirection.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(TraversalDirection.right),
        const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonB): const ExitDetailIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const ExitDetailIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace): const ExitDetailIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonX): const ReloadAppsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX): const ReloadAppsIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonY): const SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyY): const SearchIntent(),
      },
      child: Actions(
        actions: {
          ExitDetailIntent: CallbackAction<ExitDetailIntent>(onInvoke: (_) {
            if (_selectedGame != null) {
              setState(() => _selectedGame = null);
            }
            return null;
          }),
          ReloadAppsIntent: CallbackAction<ReloadAppsIntent>(onInvoke: (_) {
            _loadInstalledApps();
            return null;
          }),
          SearchIntent: CallbackAction<SearchIntent>(onInvoke: (_) {
            final isLibraryScreen = _useHomeAsLibrary ? (_selectedIndex == 0) : (_selectedIndex == 1);
            if (isLibraryScreen && _tabController.index == 0) {
              _showSearchDialog('Search games', (v) => setState(() => _searchQuery = v));
            } else if (isLibraryScreen) {
              _showSearchDialog('Search apps', (v) => setState(() => _appsSearchQuery = v));
            }
            return null;
          }),
        },
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: PopScope(
            canPop: _selectedGame == null,
            onPopInvoked: (didPop) {
              if (didPop) return;
              if (_selectedGame != null) {
                setState(() => _selectedGame = null);
              }
            },
            child: Scaffold(
              body: _desktopMode ? _buildDesktopMode() : _buildNormalBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameDetailView() {
    return Column(
      children: [
        Expanded(
          child: _buildGameDetailContent(),
        ),
        ActionGuideWidget(hints: _detailActionHints()),
      ],
    );
  }

  Widget _buildGameDetailContent() {
    return GameDetailDialog(
      game: _selectedGame!,
      onClose: () {
        setState(() => _selectedGame = null);
        _loadLibrary();
      },
      onLaunch: _launchGame,
      onSetBanner: _setBannerForGameDetail,
      onSetCover: _setCoverForGameDetail,
      onSetIcon: _setIconForGameDetail,
      libraryService: _libraryService,
      focusNode: _playButtonFocusNode,
    );
  }

  Widget _buildHomeContent() {
    final gamePackageNames = _games
        .where((g) => g.packageName != null && g.shortcutId == null)
        .map((g) => g.packageName!)
        .toSet();
    final appsCount = _installedApps
        .where((app) => !gamePackageNames.contains(app.packageName))
        .length;
    return HomeScreen(
      games: _games,
      allAppsCount: appsCount,
      isLoading: _isLoading,
      onGoToLibrary: () => setState(() => _selectedIndex = 1),
      onOpenGameDetail: _openGameDetail,
      onLaunchGame: _launchGame,
      coverImageProvider: _coverImage,
      formatLastPlayed: _formatLastPlayed,
    );
  }

  Widget _buildLibraryContent() {
    return LibraryScreen(
      games: _games,
      installedApps: _installedApps,
      isLoadingGames: _isLoading,
      isLoadingApps: _isLoadingApps,
      gamesSearchQuery: _searchQuery,
      appsSearchQuery: _appsSearchQuery,
      onGamesSearchPressed: () => _showSearchDialog('Search games', (v) => setState(() => _searchQuery = v)),
      onAppsSearchPressed: () => _showSearchDialog('Search apps', (v) => setState(() => _appsSearchQuery = v)),
      onAppsReloadPressed: _loadInstalledApps,
      onGamesSearchQueryChanged: (v) => setState(() => _searchQuery = v),
      onAppsSearchQueryChanged: (v) => setState(() => _appsSearchQuery = v),
      onGameCardPressed: _openGameDetail,
      onGameLaunch: _launchGame,
      coverImageProvider: _coverImage,
      iconImageProvider: _iconImage,
      streamingCoverImageProvider: _streamingAppCoverImage,
      streamingIconImageProvider: _streamingAppIconImage,
      streamingDisplayNameProvider: _streamingAppDisplayName,
      appsService: _appsService,
      onAddAsGame: _addGameFromApp,
      onAddAsStreaming: _addStreamingApp,
      onRemoveStreaming: _removeStreamingApp,
      onSetStreamingCover: _setStreamingAppCover,
      gameStreamingApps: _gameStreamingApps,
      videoStreamingApps: _videoStreamingApps,
      tabController: _tabController,
      showGameStreaming: _showGameStreaming,
      showVideoStreaming: _showVideoStreaming,
      layoutMode: _layoutMode,
    );
  }

  Widget _buildPlazaNetContent() {
    final items = _navItems(context);
    final plazaNetItem = items.firstWhere(
      (item) => item.assetPath == 'assets/images/plazanet.png',
      orElse: () => NavigationItem(assetPath: 'assets/images/plazanet.png', label: AppLocalizations.of(context).navPlazaNet),
    );
    return PlazaNetScreen(
      label: plazaNetItem.label,
      icon: plazaNetItem.icon ?? Icons.cloud,
    );
  }

  Widget _buildStoreContent() {
    final items = _navItems(context);
    final storeItem = items.firstWhere(
      (item) => item.assetPath == 'assets/images/store.png',
      orElse: () => NavigationItem(assetPath: 'assets/images/store.png', label: AppLocalizations.of(context).navStore),
    );
    return StoreScreen(
      label: storeItem.label,
      icon: storeItem.icon ?? Icons.store,
    );
  }

  Widget _buildSettingsContent() {
    return SettingsScreen(
      libraryService: _libraryService,
      appsService: _appsService,
      presenceService: _presenceService,
      onStreamingSettingsChanged: _applyStreamingTabSettings,
      onSettingsChanged: _reloadAppData,
    );
  }

  Widget _buildScreenContent() {
    Widget body;
    
    if (_useHomeAsLibrary) {
      if (_selectedIndex == 0) {
        body = _buildLibraryContent(); // Show library on home
      } else if (_selectedIndex == 1) {
        body = _buildPlazaNetContent();
      } else if (_selectedIndex == 2) {
        body = _buildStoreContent();
      } else {
        body = _buildSettingsContent();
      }
    } else {
      if (_selectedIndex == 0) {
        body = _buildHomeContent();
      } else if (_selectedIndex == 1) {
        body = _buildLibraryContent();
      } else if (_selectedIndex == 2) {
        body = _buildPlazaNetContent();
      } else if (_selectedIndex == 3) {
        body = _buildStoreContent();
      } else {
        body = _buildSettingsContent();
      }
    }

    final showTopBar = _layoutMode != LayoutMode.handheld;
    final l10n = AppLocalizations.of(context);
    final displayLabel = (_useHomeAsLibrary && _selectedIndex == 0) 
        ? l10n.navLibrary 
        : _navItems(context)[_selectedIndex].label;
    
    return Column(
      children: [
        if (showTopBar) TopBarWidget(label: displayLabel),
        Expanded(child: body),
        ActionGuideWidget(hints: _currentActionHints()),
      ],
    );
  }

  Widget _buildNormalBody() {
    if (_layoutMode == LayoutMode.handheld) {
      return _buildHandheldBody();
    }

    return Row(
      children: [
        SidebarWidget(
          selectedIndex: _selectedIndex,
          navItems: _navItems(context),
          userName: _userName,
          currentTime: _currentTime,
          batteryLevel: _batteryLevel,
          batteryState: _batteryState,
          onNavItemPressed: _onNavItemSelected,
        ),
        Expanded(
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: _selectedGame != null
                ? _buildGameDetailView()
                : _buildScreenContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildHandheldBody() {
    final items = _navItems(context);
    return Column(
      children: [
        const _HandheldBezelEdge(isTop: true),
        Expanded(
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: _selectedGame != null
                ? _buildGameDetailView()
                : _buildScreenContent(),
          ),
        ),
        _HandheldNavBar(
          items: items,
          selectedIndex: _selectedIndex,
          currentTime: _currentTime,
          batteryLevel: _batteryLevel,
          batteryState: _batteryState,
          userName: _userName,
          onSelected: _onNavItemSelected,
        ),
        const _HandheldBezelEdge(isTop: false),
      ],
    );
  }

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedGame = null;
    });
    _updatePresenceForSelectedTab();
  }

  Widget _buildDesktopMode() {
    return const DesktopModeScreen();
  }
}

class _HandheldNavBar extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final String? userName;
  final String currentTime;
  final int batteryLevel;
  final BatteryState batteryState;
  final ValueChanged<int> onSelected;

  const _HandheldNavBar({
    required this.items,
    required this.selectedIndex,
    required this.currentTime,
    required this.batteryLevel,
    required this.batteryState,
    required this.userName,
    required this.onSelected,
  });

  Widget _buildNavIcon(NavigationItem item, {required bool isSelected, double size = 24}) {
    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        width: size + 4,
        height: size + 4,
        fit: BoxFit.contain,
      );
    }
    final color = isSelected ? Colors.white : AppColors.textPrimary;
    return Icon(
      item.icon,
      size: size + 4,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkBattery = batteryState == BatteryState.discharging && batteryLevel < 15;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              ProfileAvatar(userName: userName, size: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'Player',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = selectedIndex == index;
                  return InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue : AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryBlue : AppColors.divider,
                        ),
                      ),
                      child: _buildNavIcon(item, isSelected: isSelected, size: 24),
                    ),
                  );
                }),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentTime,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(
                    batteryState == BatteryState.charging
                        ? Icons.battery_charging_full
                        : Icons.battery_std,
                    color: isDarkBattery ? Colors.red : AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$batteryLevel%',
                    style: TextStyle(
                      color: isDarkBattery ? Colors.red : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HandheldBezelEdge extends StatelessWidget {
  final bool isTop;

  const _HandheldBezelEdge({required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            AppColors.darkSurface,
            AppColors.darkSurface.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
