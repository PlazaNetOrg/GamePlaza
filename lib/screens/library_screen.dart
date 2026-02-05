import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/game_library_service.dart';
import '../services/installed_apps_service.dart';
import '../widgets/library_tabs/library_tabs_manager.dart';

class LibraryScreen extends StatelessWidget {
  final List<Game> games;
  final List<AppInfo> installedApps;
  final bool isLoadingGames;
  final bool isLoadingApps;
  final String gamesSearchQuery;
  final String appsSearchQuery;
  final VoidCallback onGamesSearchPressed;
  final VoidCallback onAppsSearchPressed;
  final VoidCallback onAppsReloadPressed;
  final ValueChanged<String> onGamesSearchQueryChanged;
  final ValueChanged<String> onAppsSearchQueryChanged;
  final Function(Game) onGameCardPressed;
  final ImageProvider? Function(Game) coverImageProvider;
  final ImageProvider? Function(AppInfo) streamingCoverImageProvider;
  final String Function(AppInfo) streamingDisplayNameProvider;
  final InstalledAppsService appsService;
  final Function(String appName, String packageName)? onAddAsGame;
  final void Function(AppInfo app, bool isGameStreaming, String displayName)? onAddAsStreaming;
  final void Function(AppInfo app, bool isGameStreaming)? onRemoveStreaming;
  final Function(AppInfo app, String? coverPath)? onSetStreamingCover;
  final List<String> gameStreamingApps;
  final List<String> videoStreamingApps;
  final TabController? tabController;
  final bool showGameStreaming;
  final bool showVideoStreaming;

  const LibraryScreen({
    super.key,
    required this.games,
    required this.installedApps,
    required this.isLoadingGames,
    required this.isLoadingApps,
    required this.gamesSearchQuery,
    required this.appsSearchQuery,
    required this.onGamesSearchPressed,
    required this.onAppsSearchPressed,
    required this.onAppsReloadPressed,
    required this.onGamesSearchQueryChanged,
    required this.onAppsSearchQueryChanged,
    required this.onGameCardPressed,
    required this.coverImageProvider,
    required this.streamingCoverImageProvider,
    required this.streamingDisplayNameProvider,
    required this.appsService,
    this.onAddAsGame,
    this.onAddAsStreaming,
    this.onRemoveStreaming,
    this.onSetStreamingCover,
    this.gameStreamingApps = const [],
    this.videoStreamingApps = const [],
    this.tabController,
    this.showGameStreaming = false,
    this.showVideoStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return LibraryTabsManager(
      games: games,
      installedApps: installedApps,
      isLoadingGames: isLoadingGames,
      isLoadingApps: isLoadingApps,
      gamesSearchQuery: gamesSearchQuery,
      appsSearchQuery: appsSearchQuery,
      onGamesSearchPressed: onGamesSearchPressed,
      onAppsSearchPressed: onAppsSearchPressed,
      onAppsReloadPressed: onAppsReloadPressed,
      onGamesSearchQueryChanged: onGamesSearchQueryChanged,
      onAppsSearchQueryChanged: onAppsSearchQueryChanged,
      onGameCardPressed: onGameCardPressed,
      coverImageProvider: coverImageProvider,
      streamingCoverImageProvider: streamingCoverImageProvider,
      streamingDisplayNameProvider: streamingDisplayNameProvider,
      appsService: appsService,
      onAddAsGame: onAddAsGame,
      onAddAsStreaming: onAddAsStreaming,
      onRemoveStreaming: onRemoveStreaming,
      onSetStreamingCover: onSetStreamingCover,
      gameStreamingApps: gameStreamingApps,
      videoStreamingApps: videoStreamingApps,
      tabController: tabController,
      showGameStreaming: showGameStreaming,
      showVideoStreaming: showVideoStreaming,
    );
  }
}
