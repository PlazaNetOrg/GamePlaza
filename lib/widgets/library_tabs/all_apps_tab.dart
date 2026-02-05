import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../services/installed_apps_service.dart';
import '../../shortcuts/app_intents.dart';
import '../../l10n/app_localizations.dart';

class AllAppsTab extends StatefulWidget {
  final List<AppInfo> installedApps;
  final String searchQuery;
  final bool isLoading;
  final VoidCallback onReloadPressed;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onSearchQueryChanged;
  final InstalledAppsService appsService;
  final Function(String appName, String packageName)? onAddAsGame;
  final void Function(AppInfo app, bool isGameStreaming, String displayName)? onAddAsStreaming;

  const AllAppsTab({
    super.key,
    required this.installedApps,
    required this.searchQuery,
    required this.isLoading,
    required this.onReloadPressed,
    required this.onSearchPressed,
    required this.onSearchQueryChanged,
    required this.appsService,
    this.onAddAsGame,
    this.onAddAsStreaming,
  });

  @override
  State<AllAppsTab> createState() => _AllAppsTabState();
}

class _AllAppsTabState extends State<AllAppsTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    if (widget.installedApps.isEmpty) {
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

    final apps = widget.searchQuery.isEmpty
        ? widget.installedApps
        : widget.installedApps
            .where((app) =>
                app.name.toLowerCase().contains(widget.searchQuery))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Text(
                widget.searchQuery.isEmpty
                    ? AppLocalizations.of(context).libraryReloadSearchHint
                    : AppLocalizations.of(context)
                        .libraryFilterLabel(widget.searchQuery),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onReloadPressed,
                icon: const Icon(Icons.refresh),
                tooltip: AppLocalizations.of(context).libraryReloadTooltip,
                color: AppColors.textPrimary,
                focusNode:
                    FocusNode(skipTraversal: true, canRequestFocus: false),
              ),
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
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 0.8,
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
          ),
        ),
      ],
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
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: focused
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : AppColors.elevatedSurface,
                            border: Border.all(
                              color: focused
                                  ? AppColors.primaryBlue
                                  : Colors.transparent,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: app.icon != null
                                ? Image.memory(
                                    app.icon!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.android,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              focused ? FontWeight.bold : FontWeight.w500,
                          color: focused
                              ? AppColors.primaryBlue
                              : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
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
        return Container(
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
                          app.name,
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
                icon: Icons.games,
                label: 'Add as Game',
                onTap: () {
                  Navigator.pop(context);
                  _addAppAsGame(app);
                },
              ),
              if (widget.onAddAsStreaming != null)
                _buildContextMenuItem(
                  icon: Icons.stream,
                  label: AppLocalizations.of(context).libraryAddAsStreaming,
                  onTap: () {
                    Navigator.pop(context);
                    _addAppAsStreaming(app);
                  },
                ),
              _buildContextMenuItem(
                icon: Icons.delete_outline,
                label: 'Uninstall',
                onTap: () async {
                  Navigator.pop(context);
                  _showUninstallDialog(app);
                },
                color: Colors.red,
              ),
            ],
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

  void _addAppAsGame(AppInfo app) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController(text: app.name);
        return AlertDialog(
          backgroundColor: AppColors.elevatedSurface,
          title: Text(AppLocalizations.of(context).libraryAddAsGame,
              style: const TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: titleController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).libraryGameTitleHint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.darkSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).actionCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty && widget.onAddAsGame != null) {
                  widget.onAddAsGame!(title, app.packageName);
                }
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context).libraryAdd),
            ),
          ],
        );
      },
    );
  }

  void _addAppAsStreaming(AppInfo app) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController(text: app.name);
        bool isGameStreaming = true;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppColors.elevatedSurface,
            title: Text(
              AppLocalizations.of(context).libraryAddAsStreaming,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).libraryGameTitleHint,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(AppLocalizations.of(context).streamingGameTitle),
                      selected: isGameStreaming,
                      onSelected: (_) => setDialogState(() => isGameStreaming = true),
                    ),
                    ChoiceChip(
                      label: Text(AppLocalizations.of(context).streamingVideoTitle),
                      selected: !isGameStreaming,
                      onSelected: (_) => setDialogState(() => isGameStreaming = false),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).actionCancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty && widget.onAddAsStreaming != null) {
                    widget.onAddAsStreaming!(app, isGameStreaming, title);
                  }
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context).libraryAdd),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUninstallDialog(AppInfo app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          AppLocalizations.of(context).libraryUninstallApp,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).libraryUninstallConfirm(app.name),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(AppLocalizations.of(context).libraryUninstall),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.appsService.uninstallApp(app.packageName);
      widget.onReloadPressed();
    }
  }
}
