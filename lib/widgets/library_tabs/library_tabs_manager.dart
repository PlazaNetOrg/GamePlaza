import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_library_service.dart';
import '../../services/installed_apps_service.dart';
import 'games_tab.dart';
import 'all_apps_tab.dart';

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
  final ImageProvider? Function(Game) coverImageProvider;
  final InstalledAppsService appsService;
  final Function(String appName, String packageName)? onAddAsGame;
  final TabController? tabController;

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
    required this.coverImageProvider,
    required this.appsService,
    this.onAddAsGame,
    this.tabController,
  });

  @override
  State<LibraryTabsManager> createState() => _LibraryTabsManagerState();
}

class _LibraryTabsManagerState extends State<LibraryTabsManager> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingGames) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    return Column(
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
            tabs: [
              Tab(text: AppLocalizations.of(context).libraryTabGames),
              Tab(text: AppLocalizations.of(context).libraryTabAllApps),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: widget.tabController,
            children: [
              GamesTab(
                games: widget.games,
                searchQuery: widget.gamesSearchQuery,
                onSearchPressed: widget.onGamesSearchPressed,
                onGameCardPressed: widget.onGameCardPressed,
                coverImageProvider: widget.coverImageProvider,
                onSearchQueryChanged: widget.onGamesSearchQueryChanged,
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
