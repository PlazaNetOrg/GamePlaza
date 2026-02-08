import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../services/game_library_service.dart';
import '../../l10n/app_localizations.dart';

class GamesTab extends StatefulWidget {
  final List<Game> games;
  final String searchQuery;
  final VoidCallback onSearchPressed;
  final Function(Game) onGameCardPressed;
  final ImageProvider? Function(Game) coverImageProvider;
  final ValueChanged<String> onSearchQueryChanged;

  const GamesTab({
    super.key,
    required this.games,
    required this.searchQuery,
    required this.onSearchPressed,
    required this.onGameCardPressed,
    required this.coverImageProvider,
    required this.onSearchQueryChanged,
  });

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.games_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No games in your library',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Long-press on apps to add them as games',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final sortedGames = List<Game>.from(widget.games)
      ..sort((a, b) => a.title.compareTo(b.title));

    final filteredGames = widget.searchQuery.isEmpty
        ? sortedGames
        : sortedGames
            .where((game) => game.title.toLowerCase().contains(widget.searchQuery))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Text(
                widget.searchQuery.isEmpty
                    ? AppLocalizations.of(context).librarySearchOnlyHint
                    : AppLocalizations.of(context)
                        .libraryFilterLabel(widget.searchQuery),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onSearchPressed,
                icon: const Icon(Icons.search),
                color: AppColors.textPrimary,
                focusNode:
                    FocusNode(skipTraversal: true, canRequestFocus: false),
                tooltip: AppLocalizations.of(context).librarySearchTooltip,
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildGamesContent(filteredGames),
        ),
      ],
    );
  }

  Widget _buildGamesContent(List<Game> filteredGames) {
    if (filteredGames.isEmpty && widget.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No games matching "${widget.searchQuery}"',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.56,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredGames.length,
      itemBuilder: (context, index) {
        return FocusTraversalOrder(
          order: NumericFocusOrder(index.toDouble()),
          child: _buildGameCard(filteredGames[index]),
        );
      },
    );
  }

  Widget _buildGameCard(Game game, {bool isLarge = false}) {
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onGameCardPressed(game);
          return null;
        }),
      },
      child: Focus(
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            final coverImage = widget.coverImageProvider(game);
            return GestureDetector(
              onTap: () => widget.onGameCardPressed(game),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: isLarge ? 200 : null,
                margin: isLarge ? const EdgeInsets.only(right: 16) : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: focused ? AppColors.primaryBlue : Colors.transparent,
                    width: 4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.elevatedSurface,
                          image: coverImage != null
                              ? DecorationImage(
                                  image: coverImage,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        game.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
