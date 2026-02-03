import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/game_library_service.dart';
import '../widgets/home_tab.dart';

class HomeScreen extends StatelessWidget {
  final List<Game> games;
  final int allAppsCount;
  final bool isLoading;
  final VoidCallback onGoToLibrary;
  final Function(Game) onOpenGameDetail;
  final Function(Game) onLaunchGame;
  final ImageProvider? Function(Game) coverImageProvider;
  final String Function(DateTime) formatLastPlayed;

  const HomeScreen({
    super.key,
    required this.games,
    required this.allAppsCount,
    required this.isLoading,
    required this.onGoToLibrary,
    required this.onOpenGameDetail,
    required this.onLaunchGame,
    required this.coverImageProvider,
    required this.formatLastPlayed,
  });

  @override
  Widget build(BuildContext context) {
    return HomeTab(
      games: games,
      allAppsCount: allAppsCount,
      isLoading: isLoading,
      onGoToLibrary: onGoToLibrary,
      onOpenGameDetail: onOpenGameDetail,
      onLaunchGame: onLaunchGame,
      coverImageProvider: coverImageProvider,
      formatLastPlayed: formatLastPlayed,
    );
  }
}
