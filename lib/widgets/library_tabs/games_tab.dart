import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../models/layout_mode.dart';
import '../../services/game_library_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/responsive.dart';

class GamesTab extends StatefulWidget {
  final List<Game> games;
  final String searchQuery;
  final VoidCallback onSearchPressed;
  final Function(Game) onGameCardPressed;
  final Function(Game) onGameLaunch;
  final ImageProvider? Function(Game) coverImageProvider;
  final ImageProvider? Function(Game) iconImageProvider;
  final bool useIconLayout;
  final LayoutMode layoutMode;
  final ValueChanged<String> onSearchQueryChanged;

  const GamesTab({
    super.key,
    required this.games,
    required this.searchQuery,
    required this.onSearchPressed,
    required this.onGameCardPressed,
    required this.onGameLaunch,
    required this.coverImageProvider,
    required this.iconImageProvider,
    this.useIconLayout = false,
    required this.layoutMode,
    required this.onSearchQueryChanged,
  });

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  static const String _iconScalePrefKey = 'games_icon_scale';
  double _iconScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadIconScale();
  }

  Future<void> _loadIconScale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_iconScalePrefKey);
    if (!mounted) return;
    if (value != null) {
      setState(() => _iconScale = value.clamp(0.85, 1.3));
    }
  }

  Future<void> _saveIconScale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_iconScalePrefKey, _iconScale);
  }

  void _increaseIconScale() {
    setState(() => _iconScale = (_iconScale + 0.15).clamp(0.85, 1.3));
    _saveIconScale();
  }

  void _decreaseIconScale() {
    setState(() => _iconScale = (_iconScale - 0.15).clamp(0.85, 1.3));
    _saveIconScale();
  }

  int _iconRowsFromScale() {
    if (_iconScale >= 1.2) return 1;
    if (_iconScale <= 0.95) return 3;
    return 2;
  }

  double _iconSpacingFromScale() {
    if (_iconScale >= 1.2) return 22;
    if (_iconScale <= 0.95) return 14;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              l10n.libraryNoGames,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l10n.libraryAddGame,
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
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (widget.useIconLayout) ...[
                IconButton(
                  onPressed: _decreaseIconScale,
                  icon: const Icon(Icons.remove),
                  color: AppColors.textPrimary,
                  tooltip: 'Smaller tiles',
                  focusNode:
                      FocusNode(skipTraversal: true, canRequestFocus: false),
                ),
                IconButton(
                  onPressed: _increaseIconScale,
                  icon: const Icon(Icons.add),
                  color: AppColors.textPrimary,
                  tooltip: 'Larger tiles',
                  focusNode:
                      FocusNode(skipTraversal: true, canRequestFocus: false),
                ),
              ],
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
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.layoutMode == LayoutMode.console) {
      return _buildConsoleCoverWheel(filteredGames);
    }

    final iconRows = _iconRowsFromScale();
    final iconSpacing = _iconSpacingFromScale();
    final responsive = Responsive.of(context);
    
    final SliverGridDelegate gridDelegate;
    if (widget.useIconLayout) {
      gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: iconRows,
        childAspectRatio: 0.95,
        crossAxisSpacing: iconSpacing,
        mainAxisSpacing: iconSpacing,
      );
    } else {
      gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.gridColumns,
        childAspectRatio: 0.62,
        crossAxisSpacing: responsive.gridSpacing,
        mainAxisSpacing: responsive.gridSpacing,
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: 18,
      ),
      gridDelegate: gridDelegate,
      scrollDirection: widget.useIconLayout ? Axis.horizontal : Axis.vertical,
      physics: widget.useIconLayout
          ? const BouncingScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: filteredGames.length,
      itemBuilder: (context, index) {
        return FocusTraversalOrder(
          order: NumericFocusOrder(index.toDouble()),
          child: _buildGameCard(filteredGames[index]),
        );
      },
    );
  }

  Widget _buildConsoleCoverWheel(List<Game> games) {
    final responsive = Responsive.of(context);
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: 26,
      ),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(width: 18),
      itemBuilder: (context, index) {
        return SizedBox(
          width: responsive.consoleCardWidth,
          height: responsive.consoleCardHeight,
          child: FocusTraversalOrder(
            order: NumericFocusOrder(index.toDouble()),
            child: _buildGameCard(games[index], isLarge: true),
          ),
        );
      },
    );
  }

  Widget _buildGameCard(Game game, {bool isLarge = false}) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.gameButtonStart): _OpenGameDetailsIntent(),
      },
      child: Actions(
        actions: {
          _OpenGameDetailsIntent: CallbackAction<_OpenGameDetailsIntent>(onInvoke: (_) {
            widget.onGameCardPressed(game);
            return null;
          }),
        },
        child: FocusableActionDetector(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.onGameLaunch(game);
              return null;
            }),
          },
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              Scrollable.ensureVisible(
                context,
                alignment: 0.35,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
              );
            }
          },
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              final coverImage = widget.coverImageProvider(game);
              final iconImage = widget.iconImageProvider(game);
              final imageProvider = widget.useIconLayout
                  ? (iconImage ?? coverImage)
                  : coverImage;
              return GestureDetector(
                onTap: () => widget.onGameLaunch(game),
                onLongPress: () => widget.onGameCardPressed(game),
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOut,
                width: isLarge ? double.infinity : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.useIconLayout ? 24 : 22),
                  color: widget.useIconLayout
                      ? AppColors.elevatedSurface.withValues(alpha: 0.94)
                      : AppColors.elevatedSurface.withValues(alpha: 0.15),
                  gradient: focused && !widget.useIconLayout
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryBlue.withValues(alpha: 0.7),
                            AppColors.secondaryBlue.withValues(alpha: 0.85),
                            AppColors.primaryBlue.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: Border.all(
                    color: widget.useIconLayout
                        ? (focused
                            ? AppColors.secondaryBlue.withValues(alpha: 0.9)
                            : AppColors.divider)
                        : (focused
                            ? AppColors.secondaryBlue.withValues(alpha: 0.7)
                            : AppColors.divider.withValues(alpha: 0.35)),
                    width: widget.useIconLayout ? (focused ? 2.6 : 1.2) : (focused ? 2.6 : 1),
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.55),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: widget.useIconLayout
                          ? _buildIconTileContent(imageProvider, focused)
                          : _buildCoverTileContent(imageProvider, focused),
                    ),
                    if (!widget.useIconLayout && !isLarge)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                        child: Text(
                          game.title,
                          style: TextStyle(
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
      ),
    );
  }

  Widget _buildIconTileContent(ImageProvider? imageProvider, bool focused) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: AppColors.elevatedSurface.withValues(alpha: 0.75),
                child: imageProvider != null
                    ? Image(image: imageProvider, fit: BoxFit.contain)
                    : Icon(
                        Icons.videogame_asset_outlined,
                        color: AppColors.textSecondary,
                        size: 36,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverTileContent(ImageProvider? imageProvider, bool focused) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            image: imageProvider != null
                ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageProvider == null
              ? Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _OpenGameDetailsIntent extends Intent {
  const _OpenGameDetailsIntent();
}
