import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_library_service.dart';
import '../../services/installed_apps_service.dart';
import '../../shortcuts/app_intents.dart';
import '../../models/layout_mode.dart';
import 'games_tab.dart';
import 'all_apps_tab.dart';
import 'streaming_tab.dart';

class LibraryTabsManager extends StatefulWidget {
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
  final Function(Game) onGameLaunch;
  final ImageProvider? Function(Game) coverImageProvider;
  final ImageProvider? Function(Game) iconImageProvider;
  final ImageProvider? Function(AppInfo) streamingCoverImageProvider;
  final ImageProvider? Function(AppInfo) streamingIconImageProvider;
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
  final LayoutMode layoutMode;

  const LibraryTabsManager({
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
    required this.onGameLaunch,
    required this.coverImageProvider,
    required this.iconImageProvider,
    required this.streamingCoverImageProvider,
    required this.streamingIconImageProvider,
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
    required this.layoutMode,
  });

  @override
  State<LibraryTabsManager> createState() => _LibraryTabsManagerState();
}

class _LibraryTabsManagerState extends State<LibraryTabsManager> {
  bool get _showStreamingTab => widget.showGameStreaming || widget.showVideoStreaming;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingGames) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    final tabLabels = <String>[
      AppLocalizations.of(context).libraryTabGames,
      if (_showStreamingTab)
        AppLocalizations.of(context).libraryTabStreaming,
      AppLocalizations.of(context).libraryTabAllApps,
    ];

    final tabIcons = <IconData>[
      Icons.videogame_asset_outlined,
      if (_showStreamingTab)
        Icons.cloud_circle_outlined,
      Icons.apps_outlined,
    ];

    final tabs = tabLabels.map((label) => Tab(text: label)).toList();

    final tabChildren = <Widget>[
      GamesTab(
        games: widget.games,
        searchQuery: widget.gamesSearchQuery,
        onSearchPressed: widget.onGamesSearchPressed,
        onGameCardPressed: widget.onGameCardPressed,
        onGameLaunch: widget.onGameLaunch,
        coverImageProvider: widget.coverImageProvider,
        iconImageProvider: widget.iconImageProvider,
        useIconLayout: widget.layoutMode == LayoutMode.handheld || widget.layoutMode == LayoutMode.compact,
        onSearchQueryChanged: widget.onGamesSearchQueryChanged,
      ),
      if (_showStreamingTab)
        StreamingTab(
          installedApps: widget.installedApps,
          searchQuery: widget.gamesSearchQuery,
          isLoading: widget.isLoadingApps,
          onReloadPressed: widget.onAppsReloadPressed,
          onSearchPressed: widget.onAppsSearchPressed,
          onSearchQueryChanged: widget.onGamesSearchQueryChanged,
          appsService: widget.appsService,
          showGameStreaming: widget.showGameStreaming,
          showVideoStreaming: widget.showVideoStreaming,
          onRemoveStreaming: widget.onRemoveStreaming,
          onSetStreamingCover: widget.onSetStreamingCover,
          coverImageProvider: widget.streamingCoverImageProvider,
          iconImageProvider: widget.streamingIconImageProvider,
          useIconLayout: widget.layoutMode == LayoutMode.handheld || widget.layoutMode == LayoutMode.compact,
          displayNameProvider: widget.streamingDisplayNameProvider,
          gameStreamingApps: widget.gameStreamingApps,
          videoStreamingApps: widget.videoStreamingApps,
        ),
      AllAppsTab(
        installedApps: widget.installedApps,
        searchQuery: widget.appsSearchQuery,
        isLoading: widget.isLoadingApps,
        onReloadPressed: widget.onAppsReloadPressed,
        onSearchPressed: widget.onAppsSearchPressed,
        onSearchQueryChanged: widget.onAppsSearchQueryChanged,
        appsService: widget.appsService,
        onAddAsGame: widget.onAddAsGame,
        onAddAsStreaming: widget.onAddAsStreaming,
      ),
    ];

    return Shortcuts(
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.gameButtonLeft1): const PreviousTabIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonRight1): const NextTabIntent(),
      },
      child: Actions(
        actions: {
          PreviousTabIntent: CallbackAction<PreviousTabIntent>(onInvoke: (_) {
            final controller = widget.tabController;
            if (controller == null) return null;
            final nextIndex = (controller.index - 1).clamp(0, controller.length - 1);
            if (nextIndex != controller.index) {
              controller.animateTo(nextIndex);
            }
            return null;
          }),
          NextTabIntent: CallbackAction<NextTabIntent>(onInvoke: (_) {
            final controller = widget.tabController;
            if (controller == null) return null;
            final nextIndex = (controller.index + 1).clamp(0, controller.length - 1);
            if (nextIndex != controller.index) {
              controller.animateTo(nextIndex);
            }
            return null;
          }),
        },
        child: widget.layoutMode == LayoutMode.handheld
            ? Row(
                children: [
                  _HandheldTabRail(
                    icons: tabIcons,
                    controller: widget.tabController,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: widget.tabController,
                      children: tabChildren,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: TabBar(
                      controller: widget.tabController,
                      labelColor: AppColors.primaryBlue,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primaryBlue,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: tabs,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: widget.tabController,
                      children: tabChildren,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HandheldTabRail extends StatelessWidget {
  final List<IconData> icons;
  final TabController? controller;

  const _HandheldTabRail({
    required this.icons,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final tabController = controller;
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface.withValues(alpha: 0.7),
        border: Border(
          right: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: List.generate(icons.length, (index) {
          final isSelected = tabController?.index == index;
          return Expanded(
            child: InkWell(
              onTap: () => tabController?.animateTo(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.divider),
                ),
                child: Center(
                  child: Icon(
                    icons[index],
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    size: 26,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

