import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/game_library_service.dart';
import '../services/installed_apps_service.dart';
import '../l10n/app_localizations.dart';

class GameDetailDialog extends StatelessWidget {
  final Game game;
  final VoidCallback onClose;
  final Function(Game) onLaunch;
  final Function(Game) onSetBanner;
  final Function(Game) onSetCover;
  final Function(Game) onSetIcon;
  final FocusNode? focusNode;
  final GameLibraryService libraryService;

  const GameDetailDialog({
    super.key,
    required this.game,
    required this.onClose,
    required this.onLaunch,
    required this.onSetBanner,
    required this.onSetCover,
    required this.onSetIcon,
    required this.libraryService,
    this.focusNode,
  });

  String _formatPlayTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    }
    return '<1m';
  }

  String _formatLastPlayed(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return AppLocalizations.of(context).gameDetailsToday;
    }
    if (difference.inDays == 1) {
      return AppLocalizations.of(context).gameDetailsYesterday;
    }
    if (difference.inDays < 7) {
      return AppLocalizations.of(context).gameDetailsDaysAgo(difference.inDays);
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleRemoveFromLibrary(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          AppLocalizations.of(context).gameDetailsRemoveDialogTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).gameDetailsRemoveDialogMessage(game.title),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).gameDetailsCancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: Text(AppLocalizations.of(context).gameDetailsRemove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await libraryService.removeGame(game.id);
      if (context.mounted) {
        onClose();
      }
    }
  }

  Future<void> _handleUninstall(BuildContext context) async {
    if (game.packageName == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          AppLocalizations.of(context).gameDetailsUninstallDialogTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).gameDetailsUninstallDialogMessage(game.title),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).gameDetailsCancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: Text(AppLocalizations.of(context).gameDetailsUninstall),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final installedAppsService = InstalledAppsService();
      await installedAppsService.uninstallApp(game.packageName!);
      await libraryService.removeGame(game.id);
      if (context.mounted) {
        onClose();
      }
    }
  }

  Widget _buildCover() {
    if (game.localCoverPath != null && File(game.localCoverPath!).existsSync()) {
      return Image.file(
        File(game.localCoverPath!),
        width: 260,
        height: 360,
        fit: BoxFit.cover,
      );
    }

    if (game.coverUrl.isNotEmpty) {
      return Image.network(
        game.coverUrl,
        width: 260,
        height: 360,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(),
      );
    }

    return _buildCoverPlaceholder();
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      width: 260,
      height: 360,
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.videogame_asset, size: 64, color: AppColors.textSecondary),
    );
  }

  Widget _buildBanner() {
    if (game.localBannerPath != null && File(game.localBannerPath!).existsSync()) {
      return Image.file(
        File(game.localBannerPath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (game.bannerUrl.isNotEmpty) {
      return Image.network(
        game.bannerUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildBannerPlaceholder(),
      );
    }

    return _buildBannerPlaceholder();
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
      ),
      child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                  tooltip: AppLocalizations.of(context).actionBack,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).gameDetailsTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                // Banner background
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Stack(
                      children: [
                        _buildBanner(),
                        // Gradient fade at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.darkSurface.withOpacity(0.9),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Cover and Launch button overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cover
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 120,
                            height: 160,
                            child: _buildCover(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Launch button
                        Expanded(
                          child: FocusableActionDetector(
                            actions: {
                              ActivateIntent: CallbackAction<ActivateIntent>(
                                onInvoke: (_) {
                                  onLaunch(game);
                                  return null;
                                },
                              ),
                            },
                            child: Focus(
                              focusNode: focusNode,
                              child: ElevatedButton.icon(
                                onPressed: () => onLaunch(game),
                                icon: const Icon(Icons.play_arrow, size: 28),
                                label: Text(
                                  AppLocalizations.of(context).gameDetailsLaunch,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              game.title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (game.packageName != null) ...[
              const SizedBox(height: 6),
              Text(
                game.packageName!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)
                      .gameDetailsPlayTime(_formatPlayTime(game.playTimeSeconds)),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
            if (game.lastPlayed != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).gameDetailsLastPlayed(
                      _formatLastPlayed(game.lastPlayed!, context),
                    ),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context).gameDetailsArtwork,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onSetCover(game),
                    icon: const Icon(Icons.image, size: 20),
                    label: Text(AppLocalizations.of(context).gameDetailsSetCover),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onSetBanner(game),
                    icon: const Icon(Icons.panorama, size: 20),
                    label: Text(AppLocalizations.of(context).gameDetailsSetBanner),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onSetIcon(game),
                icon: const Icon(Icons.apps, size: 20),
                label: Text(AppLocalizations.of(context).gameDetailsSetIcon),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).gameDetailsManagement,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleRemoveFromLibrary(context),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                label: Text(AppLocalizations.of(context).gameDetailsRemoveFromLibrary),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            if (game.packageName != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleUninstall(context),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(AppLocalizations.of(context).gameDetailsUninstallApp),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryBlue,
                    side: BorderSide(color: AppColors.secondaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

