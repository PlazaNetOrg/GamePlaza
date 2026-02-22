import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../services/game_library_service.dart';
import '../../l10n/app_localizations.dart';

class GamesTab extends StatefulWidget {
  final List<Game> games;
  final String searchQuery;
  final VoidCallback onSearchPressed;
  final Function(Game) onGameCardPressed;
  final Function(Game) onGameLaunch;
  final ImageProvider? Function(Game) coverImageProvider;
  final ImageProvider? Function(Game) iconImageProvider;
  final bool useIconLayout;
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

    final iconRows = _iconRowsFromScale();
    final iconSpacing = _iconSpacingFromScale();
    final gridDelegate = widget.useIconLayout
        ? SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: iconRows,
            childAspectRatio: 0.95,
            crossAxisSpacing: iconSpacing,
            mainAxisSpacing: iconSpacing,
          )
        : const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.62,
            crossAxisSpacing: 18,
            mainAxisSpacing: 20,
          );

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                width: isLarge ? 200 : null,
                margin: isLarge ? const EdgeInsets.only(right: 16) : null,
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
                    if (!widget.useIconLayout)
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
