import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../../theme/app_colors.dart';
import '../../services/installed_apps_service.dart';
import '../../shortcuts/app_intents.dart';
import '../../l10n/app_localizations.dart';

class StreamingTab extends StatefulWidget {
  final List<AppInfo> installedApps;
  final String searchQuery;
  final bool isLoading;
  final VoidCallback onReloadPressed;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onSearchQueryChanged;
  final InstalledAppsService appsService;
  final bool showGameStreaming;
  final bool showVideoStreaming;
  final void Function(AppInfo app, bool isGameStreaming)? onRemoveStreaming;
  final List<String> gameStreamingApps;
  final List<String> videoStreamingApps;
  final Function(AppInfo app, String? coverPath)? onSetStreamingCover;
  final ImageProvider? Function(AppInfo) coverImageProvider;
  final String Function(AppInfo) displayNameProvider;

  const StreamingTab({
    super.key,
    required this.installedApps,
    required this.searchQuery,
    required this.isLoading,
    required this.onReloadPressed,
    required this.onSearchPressed,
    required this.onSearchQueryChanged,
    required this.appsService,
    required this.showGameStreaming,
    required this.showVideoStreaming,
    this.onRemoveStreaming,
    this.onSetStreamingCover,
    required this.coverImageProvider,
    required this.displayNameProvider,
    this.gameStreamingApps = const [],
    this.videoStreamingApps = const [],
  });

  @override
  State<StreamingTab> createState() => _StreamingTabState();
}

class _StreamingTabState extends State<StreamingTab> {
  late List<AppInfo> _gameStreamingInstalledApps;
  late List<AppInfo> _videoStreamingInstalledApps;

  @override
  void initState() {
    super.initState();
    _updateStreamingApps();
  }

  @override
  void didUpdateWidget(StreamingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.installedApps != widget.installedApps ||
        oldWidget.gameStreamingApps != widget.gameStreamingApps ||
        oldWidget.videoStreamingApps != widget.videoStreamingApps) {
      _updateStreamingApps();
    }
  }

  void _updateStreamingApps() {
    _gameStreamingInstalledApps = widget.installedApps
      .where((app) => widget.gameStreamingApps.contains(app.packageName))
        .toList();
    _videoStreamingInstalledApps = widget.installedApps
      .where((app) => widget.videoStreamingApps.contains(app.packageName))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    final isEmpty = _gameStreamingInstalledApps.isEmpty &&
        _videoStreamingInstalledApps.isEmpty;

    if (isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).libraryNoApps,
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context).librarySearchOnlyHint,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onSearchPressed,
                icon: const Icon(Icons.search),
                tooltip: AppLocalizations.of(context).librarySearchTooltip,
                color: AppColors.textPrimary,
                focusNode:
                    FocusNode(skipTraversal: true, canRequestFocus: false),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.showGameStreaming &&
                  _gameStreamingInstalledApps.isNotEmpty) ...[
                _buildSectionHeader(
                    AppLocalizations.of(context).streamingGameTitle),
                const SizedBox(height: 12),
                _buildAppsGrid(_gameStreamingInstalledApps),
                const SizedBox(height: 32),
              ],
              if (widget.showVideoStreaming &&
                  _videoStreamingInstalledApps.isNotEmpty) ...[
                _buildSectionHeader(
                    AppLocalizations.of(context).streamingVideoTitle),
                const SizedBox(height: 12),
                _buildAppsGrid(_videoStreamingInstalledApps),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildAppsGrid(List<AppInfo> apps) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.56,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        return FocusTraversalOrder(
          order: NumericFocusOrder(index.toDouble()),
          child: _buildAppCard(apps[index]),
        );
      },
    );
  }

  Widget _buildAppCard(AppInfo app) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.gameButtonStart):
            OpenContextMenuIntent(),
        SingleActivator(LogicalKeyboardKey.contextMenu):
            OpenContextMenuIntent(),
      },
      child: Actions(
        actions: {
          OpenContextMenuIntent: CallbackAction<OpenContextMenuIntent>(
            onInvoke: (_) {
              _showAppContextMenu(app);
              return null;
            },
          ),
        },
        child: FocusableActionDetector(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.appsService.launchApp(app.packageName);
              return null;
            }),
          },
          child: Focus(
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return GestureDetector(
                  onTap: () async {
                    await widget.appsService.launchApp(app.packageName);
                  },
                  onLongPress: () {
                    _showAppContextMenu(app);
                  },
                  child: MouseRegion(
                    onEnter: (_) => Focus.of(context).requestFocus(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
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
                                image: _getCoverImage(app),
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
                              widget.displayNameProvider(app),
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAppContextMenu(AppInfo app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.gameButtonB):
                CloseContextMenuIntent(),
          },
          child: Actions(
            actions: {
              CloseContextMenuIntent: CallbackAction<CloseContextMenuIntent>(
                onInvoke: (_) {
                  Navigator.pop(context);
                  return null;
                },
              ),
            },
            child: WillPopScope(
              onWillPop: () async => true,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (app.icon != null)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(app.icon!),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.displayNameProvider(app),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                app.packageName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 8),
                    _buildContextMenuItem(
                      icon: Icons.info_outline,
                      label: 'App Info',
                      onTap: () async {
                        Navigator.pop(context);
                        await widget.appsService.openAppSettings(app.packageName);
                      },
                    ),
                    _buildContextMenuItem(
                      icon: Icons.image,
                      label: 'Choose Cover',
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSetStreamingCover?.call(app, null);
                      },
                    ),
                    if (widget.onRemoveStreaming != null)
                      _buildContextMenuItem(
                        icon: Icons.delete_outline,
                        label: AppLocalizations.of(context).libraryRemoveFromStreaming,
                        onTap: () {
                          Navigator.pop(context);
                          _removeFromStreaming(app);
                        },
                        color: Colors.red,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContextMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? AppColors.textPrimary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFromStreaming(AppInfo app) {
    final isGameStreaming = widget.gameStreamingApps.contains(app.packageName);
    widget.onRemoveStreaming?.call(app, isGameStreaming);
  }

  DecorationImage? _getCoverImage(AppInfo app) {
    final coverImage = widget.coverImageProvider(app);
    if (coverImage != null) {
      return DecorationImage(image: coverImage, fit: BoxFit.cover);
    }
    
    if (app.icon != null) {
      return DecorationImage(
        image: MemoryImage(app.icon!),
        fit: BoxFit.cover,
      );
    }
    
    return null;
  }
}
