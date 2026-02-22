import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/steamgriddb_service.dart';
import '../l10n/app_localizations.dart';

enum ImageType { grid, hero, icon }

class CoverPickerDialog extends StatelessWidget {
  final String apiKey;
  final String appName;
  final String packageName;
  final Function(String) onCoverSelected;

  const CoverPickerDialog({
    super.key,
    required this.apiKey,
    required this.appName,
    required this.packageName,
    required this.onCoverSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BannerPickerDialog(
      apiKey: apiKey,
      appName: appName,
      packageName: packageName,
      imageType: ImageType.grid,
      onBannerSelected: onCoverSelected,
    );
  }
}

class IconPickerDialog extends StatelessWidget {
  final String apiKey;
  final String appName;
  final String packageName;
  final Function(String) onIconSelected;

  const IconPickerDialog({
    super.key,
    required this.apiKey,
    required this.appName,
    required this.packageName,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BannerPickerDialog(
      apiKey: apiKey,
      appName: appName,
      packageName: packageName,
      imageType: ImageType.icon,
      onBannerSelected: onIconSelected,
    );
  }
}

class BannerPickerDialog extends StatefulWidget {
  final String apiKey;
  final String appName;
  final String packageName;
  final ImageType imageType;
  final Function(String) onBannerSelected;

  const BannerPickerDialog({
    super.key,
    required this.apiKey,
    required this.appName,
    required this.packageName,
    required this.imageType,
    required this.onBannerSelected,
  });

  @override
  State<BannerPickerDialog> createState() => _BannerPickerDialogState();
}

class _BannerPickerDialogState extends State<BannerPickerDialog> {
  late SteamGridDBService _steamGridService;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  List<GameSearchResult> _searchResults = [];
  List<GameImage> _bannerImages = [];
  bool _isSearching = false;
  bool _isLoadingImages = false;
  String? _selectedBannerUrl;
  int? _selectedGameIndex;
  int? _selectedImageIndex;

  @override
  void initState() {
    super.initState();
    _steamGridService = SteamGridDBService(apiKey: widget.apiKey);
    _searchController = TextEditingController(text: widget.appName);
    _searchFocusNode = FocusNode();
    _searchGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchGames([String? query]) async {
    final searchQuery = query ?? _searchController.text;
    if (searchQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
      _selectedGameIndex = null;
    });
    try {
      final results = await _steamGridService.searchGame(searchQuery);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        if (results.isNotEmpty) {
          _selectedGameIndex = 0;
        }
      });
      
      if (results.isNotEmpty) {
        _loadBanners(results.first.id);
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadBanners(int gameId) async {
    setState(() {
      _isLoadingImages = true;
      _selectedImageIndex = null;
    });
    final images = widget.imageType == ImageType.grid
      ? await _steamGridService.getGridImages(gameId)
      : widget.imageType == ImageType.icon
        ? await _steamGridService.getIconImages(gameId)
        : await _steamGridService.getHeroImages(gameId);
    setState(() {
      _bannerImages = images;
      _selectedBannerUrl = images.isNotEmpty ? images.first.url : null;
      _selectedImageIndex = images.isNotEmpty ? 0 : null;
      _isLoadingImages = false;
    });
  }

  void _selectGame(int index) {
    if (index >= 0 && index < _searchResults.length) {
      setState(() => _selectedGameIndex = index);
      _loadBanners(_searchResults[index].id);
    }
  }

  void _selectImage(int index) {
    if (index >= 0 && index < _bannerImages.length) {
      setState(() {
        _selectedImageIndex = index;
        _selectedBannerUrl = _bannerImages[index].url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.elevatedSurface,
      child: Container(
        width: 900,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 280,
                    child: _buildLeftPanel(),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildRightPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          widget.imageType == ImageType.grid
              ? Icons.image
              : widget.imageType == ImageType.icon
                  ? Icons.apps
                  : Icons.panorama,
          color: AppColors.primaryBlue,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.imageType == ImageType.grid
                    ? AppLocalizations.of(context).gameDialogsSelectCover
                    : widget.imageType == ImageType.icon
                        ? AppLocalizations.of(context).gameDialogsSelectIcon
                        : AppLocalizations.of(context).gameDialogsSelectBanner,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                widget.appName,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _FocusableIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.pop(context),
          tooltip: AppLocalizations.of(context).gameDialogsClose,
        ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).gameDialogsMatchingGames,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildGamesList(),
        ),
        const SizedBox(height: 16),
        _buildActions(),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).gameDialogsSearchHint,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
        suffixIcon: _isSearching
            ? Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                  ),
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      onSubmitted: _searchGames,
    );
  }

  Widget _buildGamesList() {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? AppLocalizations.of(context).gameDialogsEnterSearchTerm
                  : AppLocalizations.of(context).gameDialogsNoGamesFound,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          final isSelected = _selectedGameIndex == index;
          return _FocusableListTile(
            title: result.name,
            isSelected: isSelected,
            onTap: () => _selectGame(index),
          );
        },
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.imageType == ImageType.grid
                  ? AppLocalizations.of(context).gameDialogsAvailableCovers
                  : widget.imageType == ImageType.icon
                      ? AppLocalizations.of(context).gameDialogsAvailableIcons
                      : AppLocalizations.of(context).gameDialogsAvailableBanners,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (_bannerImages.isNotEmpty)
              Text(
                AppLocalizations.of(context).gameDialogsImagesCount(_bannerImages.length),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildImageGrid(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    if (_isLoadingImages) {
      return Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (_bannerImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              _searchResults.isEmpty
                  ? AppLocalizations.of(context).gameDialogsSearchForArtwork
                  : widget.imageType == ImageType.grid
                      ? AppLocalizations.of(context).gameDialogsNoCovers
                      : widget.imageType == ImageType.icon
                          ? AppLocalizations.of(context).gameDialogsNoIcons
                          : AppLocalizations.of(context).gameDialogsNoBanners,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = widget.imageType == ImageType.grid
      ? 2
      : widget.imageType == ImageType.icon
        ? 4
        : 1;
    final childAspectRatio = widget.imageType == ImageType.grid
      ? 0.667
      : widget.imageType == ImageType.icon
        ? 1.0
        : 2.5;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _bannerImages.length,
      itemBuilder: (context, index) {
        final image = _bannerImages[index];
        final isSelected = _selectedImageIndex == index;
        return _FocusableImageTile(
          imageUrl: image.thumb ?? image.url,
          isSelected: isSelected,
          onTap: () => _selectImage(index),
        );
      },
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FocusableButton(
          label: widget.imageType == ImageType.grid
              ? AppLocalizations.of(context).gameDialogsSetCover
              : widget.imageType == ImageType.icon
                  ? AppLocalizations.of(context).gameDialogsSetIcon
                  : AppLocalizations.of(context).gameDialogsSetBanner,
          isPrimary: true,
          enabled: _selectedBannerUrl != null,
          onPressed: _selectedBannerUrl != null
              ? () {
                  widget.onBannerSelected(_selectedBannerUrl!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.imageType == ImageType.grid
                          ? AppLocalizations.of(context).gameDialogsCoverUpdated
                          : widget.imageType == ImageType.icon
                              ? AppLocalizations.of(context).gameDialogsIconUpdated
                              : AppLocalizations.of(context).gameDialogsBannerUpdated),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: 8),
        _FocusableButton(
          label: AppLocalizations.of(context).gameDialogsCancel,
          isPrimary: false,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _FocusableIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _FocusableIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Tooltip(
            message: tooltip ?? '',
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: focused ? AppColors.primaryBlue.withValues(alpha: 0.2) : Colors.transparent,
                  border: Border.all(
                    color: focused ? AppColors.primaryBlue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: focused ? AppColors.primaryBlue : AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FocusableListTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusableListTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          onTap();
          return null;
        }),
      },
      child: Focus(
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryBlue.withValues(alpha: 0.2) 
                      : (focused ? AppColors.elevatedSurface : Colors.transparent),
                  border: Border(
                    left: BorderSide(
                      color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (isSelected)
                      Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 16)
                    else
                      Icon(Icons.videogame_asset, color: focused ? AppColors.textPrimary : AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected || focused ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (focused)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.keyboard_return, color: AppColors.primaryBlue, size: 12),
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

class _FocusableImageTile extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusableImageTile({
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          onTap();
          return null;
        }),
      },
      child: Focus(
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primaryBlue 
                        : (focused ? AppColors.primaryBlue.withValues(alpha: 0.7) : Colors.transparent),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: focused || isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.darkSurface,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryBlue,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.darkSurface,
                            child: Center(
                              child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                            ),
                          );
                        },
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
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
    );
  }
}

class _FocusableButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onPressed;

  const _FocusableButton({
    required this.label,
    required this.isPrimary,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          if (enabled) onPressed?.call();
          return null;
        }),
      },
      child: Focus(
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: focused ? AppColors.primaryBlue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isPrimary
                  ? ElevatedButton(
                      onPressed: enabled ? onPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: enabled ? AppColors.primaryBlue : AppColors.divider,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(label),
                    )
                  : TextButton(
                      onPressed: onPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(label),
                    ),
            );
          },
        ),
      ),
    );
  }
}

