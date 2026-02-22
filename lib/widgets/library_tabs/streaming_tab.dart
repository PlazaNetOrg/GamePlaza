import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final ImageProvider? Function(AppInfo) iconImageProvider;
  final String Function(AppInfo) displayNameProvider;
  final bool useIconLayout;

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
    required this.iconImageProvider,
    required this.displayNameProvider,
    this.useIconLayout = false,
    this.gameStreamingApps = const [],
    this.videoStreamingApps = const [],
  });

  @override
  State<StreamingTab> createState() => _StreamingTabState();
}

class _StreamingTabState extends State<StreamingTab> {
  late List<AppInfo> _gameStreamingInstalledApps;
  late List<AppInfo> _videoStreamingInstalledApps;
  static const String _iconScalePrefKey = 'streaming_icon_scale';
  double _iconScale = 1.0;

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
  void initState() {
    super.initState();
    _updateStreamingApps();
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
      return Center(
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
          style: TextStyle(
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildAppsGrid(List<AppInfo> apps) {
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

    final grid = GridView.builder(
      shrinkWrap: true,
      physics: widget.useIconLayout
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0),
      gridDelegate: gridDelegate,
      scrollDirection: widget.useIconLayout ? Axis.horizontal : Axis.vertical,
      itemCount: apps.length,
      itemBuilder: (context, index) {
        return FocusTraversalOrder(
          order: NumericFocusOrder(index.toDouble()),
          child: _buildAppCard(apps[index]),
        );
      },
    );

    if (!widget.useIconLayout) {
      return grid;
    }

    final rows = _iconRowsFromScale();
    final spacing = _iconSpacingFromScale();
    final tileExtent = 110 * _iconScale;
    return SizedBox(
      height: tileExtent * rows + spacing * (rows - 1),
      child: grid,
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
                      duration: const Duration(milliseconds: 110),
                      curve: Curves.easeOut,
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
                                ? _buildIconTileContent(app, focused)
                                : _buildCoverTileContent(app),
                          ),
                          if (!widget.useIconLayout) ...[   
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                              child: Text(
                                widget.displayNameProvider(app),
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
                        ],
                      ),
                          ),
                        ),
                      );
                    },
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                app.packageName,
                                style: TextStyle(
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
                    Divider(color: AppColors.divider),
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
                      label: widget.useIconLayout ? 'Choose Icon' : 'Choose Cover',
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

  Widget _buildIconImage(AppInfo app) {
    final iconImage = widget.iconImageProvider(app);
    final coverImage = widget.coverImageProvider(app);
    final imageProvider = iconImage ?? coverImage;

    if (imageProvider != null) {
      return Image(image: imageProvider, fit: BoxFit.contain);
    }

    return Icon(
      Icons.apps,
      color: AppColors.textSecondary,
      size: 36,
    );
  }

  Widget _buildIconTileContent(AppInfo app, bool focused) {
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
                child: _buildIconImage(app),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverTileContent(AppInfo app) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            image: _getAppImage(app),
          ),
          child: _getAppImage(app) == null
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

  DecorationImage? _getAppImage(AppInfo app) {
    final iconImage = widget.iconImageProvider(app);
    final coverImage = widget.coverImageProvider(app);
    final imageProvider = widget.useIconLayout
        ? (iconImage ?? coverImage)
        : (coverImage ?? iconImage);

    if (imageProvider != null) {
      return DecorationImage(
        image: imageProvider,
        fit: widget.useIconLayout ? BoxFit.contain : BoxFit.cover,
      );
    }

    return null;
  }
}
