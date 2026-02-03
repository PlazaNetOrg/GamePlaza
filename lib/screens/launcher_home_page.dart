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
import '../services/game_library_service.dart';
import '../services/game_art_service.dart';
import '../services/installed_apps_service.dart';
import '../services/shortcut_service.dart';
import '../services/presence_service.dart';
import '../shortcuts/app_intents.dart';
import 'package:collection/collection.dart';
import '_widgets/sidebar_widget.dart';
import '_widgets/top_bar_widget.dart';
import '_widgets/action_guide_widget.dart';
import '../l10n/app_localizations.dart';

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

  // Play session tracking
  static const String _playSessionStartKey = 'play_session_start_ms';
  static const String _playSessionGameIdKey = 'play_session_game_id';
  DateTime? _playSessionStart;
  String? _playSessionGameId;

  List<NavigationItem> _navItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      NavigationItem(icon: Icons.home, label: l10n.navHome),
      NavigationItem(icon: Icons.library_books, label: l10n.navLibrary),
      NavigationItem(icon: Icons.cloud, label: l10n.navPlazaNet),
      NavigationItem(icon: Icons.store, label: l10n.navStore),
      NavigationItem(icon: Icons.settings, label: l10n.navSettings),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => mounted ? setState(() {}) : null);

    _loadLibrary();
    _loadInstalledApps();
    _updateTime();
    _updateBattery();
    _initShortcutService();
    _restorePendingPlaySession();
    _initializePresence();

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

  void _restorePendingPlaySession() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_playSessionStartKey);
    if (startMs != null) {
      _playSessionStart = DateTime.fromMillisecondsSinceEpoch(startMs);
      _playSessionGameId = prefs.getString(_playSessionGameIdKey);
      await _completePlaySession();
    }
  }

  void _initializePresence() async {
    if (await _presenceService.hasAuthToken()) {
      await _presenceService.goOnline();
    }
  }

  Future<void> _launchGame(Game game) async {
    await _startPlaySession(game);
    await _markGamePlayed(game);
    
    await _presenceService.startPlayingGame(game.title);

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

    await _presenceService.stopPlayingGame();
  }

  Future<void> _markGamePlayed(Game game) async {
    final updated = game.copyWith(lastPlayed: DateTime.now());
    await _libraryService.updateGame(updated);
    await _loadLibrary();
  }

  Future<Game?> _updateGameArt(Game game, String imageUrl, GameArtType type) async {
    try {
      final deletePath = type == GameArtType.cover ? game.localCoverPath : game.localBannerPath;
      if (deletePath != null) await _gameArtService.deleteArt(deletePath);

      final savedPath = await _gameArtService.saveGameArt(
        gameId: game.id,
        imageUrl: imageUrl,
        type: type,
      );

      final updated = type == GameArtType.cover
          ? game.copyWith(coverUrl: imageUrl, localCoverPath: savedPath)
          : game.copyWith(bannerUrl: imageUrl, localBannerPath: savedPath);

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
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Type to filter...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
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
    if (_selectedIndex != 1) return [];
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {
      if (_playSessionStart == null || _playSessionGameId == null) {
        _presenceService.goOnline();
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
            if (_selectedIndex == 1 && _tabController.index == 0) {
              _showSearchDialog('Search games', (v) => setState(() => _searchQuery = v));
            } else if (_selectedIndex == 1) {
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
              body: Row(
                children: [
                  SidebarWidget(
                    selectedIndex: _selectedIndex,
                    navItems: _navItems(context),
                    userName: _userName,
                    currentTime: _currentTime,
                    batteryLevel: _batteryLevel,
                    batteryState: _batteryState,
                    onNavItemPressed: (index) => setState(() {
                      _selectedIndex = index;
                      _selectedGame = null;
                    }),
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
              ),
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
          child: GameDetailDialog(
            game: _selectedGame!,
            onClose: () {
              setState(() => _selectedGame = null);
              _loadLibrary();
            },
            onLaunch: _launchGame,
            onSetBanner: _setBannerForGameDetail,
            onSetCover: _setCoverForGameDetail,
            libraryService: _libraryService,
            focusNode: _playButtonFocusNode,
          ),
        ),
        ActionGuideWidget(hints: _detailActionHints()),
      ],
    );
  }

  Widget _buildScreenContent() {
    Widget body;
    if (_selectedIndex == 0) {
      body = HomeScreen(
        games: _games,
        allAppsCount: _installedApps.length,
        isLoading: _isLoading,
        onGoToLibrary: () => setState(() => _selectedIndex = 1),
        onOpenGameDetail: _openGameDetail,
        onLaunchGame: _launchGame,
        coverImageProvider: _coverImage,
        formatLastPlayed: _formatLastPlayed,
      );
    } else if (_selectedIndex == 1) {
      body = LibraryScreen(
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
        coverImageProvider: _coverImage,
        appsService: _appsService,
        onAddAsGame: _addGameFromApp,
        tabController: _tabController,
      );
    } else if (_selectedIndex == 2) {
      final items = _navItems(context);
      body = PlazaNetScreen(label: items[2].label, icon: items[2].icon);
    } else if (_selectedIndex == 3) {
      final items = _navItems(context);
      body = StoreScreen(label: items[3].label, icon: items[3].icon);
    } else {
      body = SettingsScreen(
        libraryService: _libraryService,
        appsService: _appsService,
        presenceService: _presenceService,
      );
    }

    return Column(
      children: [
        TopBarWidget(label: _navItems(context)[_selectedIndex].label),
        Expanded(child: body),
        ActionGuideWidget(hints: _currentActionHints()),
      ],
    );
  }
}
