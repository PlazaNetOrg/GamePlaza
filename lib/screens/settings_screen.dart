import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../app.dart';
import '../theme/app_colors.dart';
import '../models/color_palette.dart';
import '../services/game_library_service.dart';
import '../services/installed_apps_service.dart';
import '../services/presence_service.dart';
import '../models/layout_mode.dart';

class SettingsScreen extends StatefulWidget {
  final GameLibraryService libraryService;
  final InstalledAppsService appsService;
  final PresenceService presenceService;
  final void Function(bool gameStreaming, bool videoStreaming)? onStreamingSettingsChanged;
  final Future<void> Function()? onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.libraryService,
    required this.appsService,
    required this.presenceService,
    this.onStreamingSettingsChanged,
    this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          _SettingsButton(
            icon: Icons.settings_outlined,
            label: AppLocalizations.of(context).settingsOpenAndroidSettings,
            onPressed: () => widget.appsService.openAndroidSettings(),
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: AppLocalizations.of(context).settingsAccount,
            children: [
              _AccountInfoTile(
                title: AppLocalizations.of(context).settingsDisplayName,
                future: widget.libraryService.getUserName(),
              ),
              const SizedBox(height: 12),
              _LanguagePicker(onSettingsChanged: widget.onSettingsChanged),
              const SizedBox(height: 12),
              _PlazaNetStatusTile(
                libraryService: widget.libraryService,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: AppLocalizations.of(context).settingsIntegrations,
            children: [
              _SteamGridDBKeyInput(onSettingsChanged: widget.onSettingsChanged),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: AppLocalizations.of(context).settingsAppearance,
            children: [
              _LayoutPicker(onSettingsChanged: widget.onSettingsChanged),
              const SizedBox(height: 16),
              _UseHomeAsLibraryToggle(onSettingsChanged: widget.onSettingsChanged),
              const SizedBox(height: 16),
              _ColorPalettePicker(onSettingsChanged: widget.onSettingsChanged),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: AppLocalizations.of(context).settingsSetup,
            children: [
              _ResetSetupOption(
                libraryService: widget.libraryService,
                presenceService: widget.presenceService,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: AppLocalizations.of(context).settingsPresence,
            children: [
              _PresenceToggle(presenceService: widget.presenceService),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: AppLocalizations.of(context).settingsStreaming,
            children: [
              _StreamingToggle(
                libraryService: widget.libraryService,
                onSettingsChanged: widget.onStreamingSettingsChanged,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: AppLocalizations.of(context).settingsData,
            children: [
              _ClearDataOption(
                libraryService: widget.libraryService,
                presenceService: widget.presenceService,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}

class _LayoutPicker extends StatefulWidget {
  final Future<void> Function()? onSettingsChanged;

  const _LayoutPicker({
    this.onSettingsChanged,
  });

  @override
  State<_LayoutPicker> createState() => _LayoutPickerState();
}

class _LayoutPickerState extends State<_LayoutPicker> {
  LayoutMode _layoutMode = LayoutMode.classic;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLayoutMode();
  }

  Future<void> _loadLayoutMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(layoutModePrefKey);
    if (!mounted) return;
    setState(() {
      _layoutMode = layoutModeFromString(raw);
      _isLoading = false;
    });
  }

  Future<void> _setLayoutMode(LayoutMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(layoutModePrefKey, layoutModeToString(mode));
    if (!mounted) return;
    setState(() => _layoutMode = mode);
    await widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsLayout,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsLayoutDesc,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          LinearProgressIndicator(color: AppColors.primaryBlue)
        else
          DropdownButtonFormField<LayoutMode>(
            value: _layoutMode,
            dropdownColor: AppColors.elevatedSurface,
            iconEnabledColor: AppColors.textSecondary,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.elevatedSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: LayoutMode.classic,
                child: Text(l10n.settingsLayoutClassic),
              ),
              DropdownMenuItem(
                value: LayoutMode.handheld,
                child: Text(l10n.settingsLayoutHandheld),
              ),
              DropdownMenuItem(
                value: LayoutMode.compact,
                child: Text(l10n.settingsLayoutCompact),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _setLayoutMode(value);
              }
            },
          ),
      ],
    );
  }
}

class _UseHomeAsLibraryToggle extends StatefulWidget {
  final Future<void> Function()? onSettingsChanged;

  const _UseHomeAsLibraryToggle({
    this.onSettingsChanged,
  });

  @override
  State<_UseHomeAsLibraryToggle> createState() => _UseHomeAsLibraryToggleState();
}

class _UseHomeAsLibraryToggleState extends State<_UseHomeAsLibraryToggle> {
  static const String _prefKey = 'use_home_as_library';
  bool _useHomeAsLibrary = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _useHomeAsLibrary = prefs.getBool(_prefKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _setPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    if (!mounted) return;
    setState(() => _useHomeAsLibrary = value);
    await widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsUseHomeAsLibrary,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsUseHomeAsLibraryDesc,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const LinearProgressIndicator()
        else
          SwitchListTile(
            value: _useHomeAsLibrary,
            onChanged: _setPreference,
            title: Text(
              _useHomeAsLibrary ? 'Enabled' : 'Disabled',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            activeColor: AppColors.primaryBlue,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

class _ColorPalettePicker extends StatefulWidget {
  final Future<void> Function()? onSettingsChanged;

  const _ColorPalettePicker({this.onSettingsChanged});

  @override
  State<_ColorPalettePicker> createState() => _ColorPalettePickerState();
}

class _ColorPalettePickerState extends State<_ColorPalettePicker> {
  ColorPalette _palette = ColorPalette.plazanet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPalette();
  }

  Future<void> _loadPalette() async {
    final palette = await ColorPaletteExtension.load();
    if (!mounted) return;
    setState(() {
      _palette = palette;
      _isLoading = false;
    });
  }

  Future<void> _setPalette(ColorPalette palette) async {
    await palette.save();
    if (!mounted) return;
    setState(() => _palette = palette);
    GamePlaza.of(context)?.updatePalette(palette);
    await widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsColorPalette,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsColorPaletteDesc,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          LinearProgressIndicator(color: AppColors.primaryBlue)
        else
          DropdownButtonFormField<ColorPalette>(
            value: _palette,
            dropdownColor: AppColors.elevatedSurface,
            iconEnabledColor: AppColors.textSecondary,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.elevatedSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: ColorPalette.plazanet,
                child: Text(l10n.settingsColorPalettePlazaNet),
              ),
              DropdownMenuItem(
                value: ColorPalette.nostalgiaWhite,
                child: Text(l10n.settingsColorPaletteNostalgiaWhite),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _setPalette(value);
              }
            },
          ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  final String title;
  final Future<String?> future;

  const _AccountInfoTile({
    required this.title,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) => ListTile(
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        subtitle: Text(
          snapshot.data ?? AppLocalizations.of(context).settingsNotSet,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _PlazaNetStatusTile extends StatelessWidget {
  final GameLibraryService libraryService;

  const _PlazaNetStatusTile({required this.libraryService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: libraryService.isPlazaNetLoggedIn(),
      builder: (context, snapshot) => FutureBuilder<String?>(
        future: libraryService.getPlazaNetUsername(),
        builder: (context, usernameSnapshot) => ListTile(
          title: Text(AppLocalizations.of(context).settingsPlazaNetTitle,
              style: TextStyle(color: AppColors.textPrimary)),
          subtitle: Text(
            snapshot.data ?? false
                ? usernameSnapshot.data ?? AppLocalizations.of(context).settingsConnected
                : AppLocalizations.of(context).settingsNotConnected,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _ResetSetupOption extends StatelessWidget {
  final GameLibraryService libraryService;
  final PresenceService presenceService;

  const _ResetSetupOption({
    required this.libraryService,
    required this.presenceService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).settingsResetTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).settingsResetDescription,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showResetDialog(context),
          icon: const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context).settingsResetSetup),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(AppLocalizations.of(context).settingsResetSetupDialog, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          AppLocalizations.of(context).settingsResetSetupMessage,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).actionCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await libraryService.clearSetupData();
              await presenceService.goOffline();
              await presenceService.clearAuthToken();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text(AppLocalizations.of(ctx).actionReset, style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

class _PresenceToggle extends StatelessWidget {
  final PresenceService presenceService;

  const _PresenceToggle({
    required this.presenceService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: presenceService.hasAuthToken(),
      builder: (context, snapshot) {
        if (!(snapshot.data ?? false)) {
          return Text(
            AppLocalizations.of(context).settingsPresenceLoginRequired,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          );
        }
        return _PresenceToggleSwitch(presenceService: presenceService);
      },
    );
  }
}

class _PresenceToggleSwitch extends StatefulWidget {
  final PresenceService presenceService;

  const _PresenceToggleSwitch({required this.presenceService});

  @override
  State<_PresenceToggleSwitch> createState() => _PresenceToggleSwitchState();
}

class _PresenceToggleSwitchState extends State<_PresenceToggleSwitch> {
  late Future<bool> _overallEnabledFuture;

  @override
  void initState() {
    super.initState();
    _overallEnabledFuture = widget.presenceService.isOverallPresenceEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _overallEnabledFuture,
      builder: (context, overallSnapshot) {
        final overallEnabled = overallSnapshot.data ?? false;
        return SwitchListTile(
          title: Text(AppLocalizations.of(context).settingsPresenceOverall,
              style: TextStyle(color: AppColors.textPrimary)),
          subtitle: Text(
            AppLocalizations.of(context).settingsPresenceOverallDesc,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          value: overallEnabled,
          activeThumbColor: AppColors.primaryBlue,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) async {
            await widget.presenceService.setOverallPresenceEnabled(value);
            setState(() {
              _overallEnabledFuture = Future.value(value);
            });
          },
        );
      },
    );
  }
}

class _ClearDataOption extends StatelessWidget {
  final GameLibraryService libraryService;
  final PresenceService presenceService;

  const _ClearDataOption({
    required this.libraryService,
    required this.presenceService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).settingsClearData,
          style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).settingsClearDataMessage,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showClearDialog(context),
          icon: const Icon(Icons.delete_outline),
          label: Text(AppLocalizations.of(context).settingsClearData),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(AppLocalizations.of(context).settingsClearDataDialog, style: const TextStyle(color: Colors.red)),
        content: Text(
          AppLocalizations.of(context).settingsClearDataMessage,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).actionCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await libraryService.clearAll();
              await presenceService.goOffline();
              await presenceService.clearAuthToken();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text(AppLocalizations.of(ctx).actionDeleteAll, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatefulWidget {
  final Future<void> Function()? onSettingsChanged;

  const _LanguagePicker({this.onSettingsChanged});

  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  late Future<String> _languageFuture;

  @override
  void initState() {
    super.initState();
    _languageFuture = _loadLanguage();
  }

  Future<String> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_language') ?? 'en';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _languageFuture,
      builder: (context, snapshot) {
        final currentLanguage = snapshot.data ?? 'en';
        return Container(
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: currentLanguage,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppColors.elevatedSurface,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(AppLocalizations.of(context).langEnglish),
                ),
                DropdownMenuItem(
                  value: 'pl',
                  child: Text(AppLocalizations.of(context).langPolish),
                ),
                DropdownMenuItem(
                  value: 'ja',
                  child: Text(AppLocalizations.of(context).langJapanese),
                ),
              ],
              onChanged: (value) async {
                if (value != null && value != currentLanguage) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_language', value);
                  setState(() {
                    _languageFuture = Future.value(value);
                  });
                  GamePlaza.of(context)?.updateLocale(Locale(value));
                  await widget.onSettingsChanged?.call();
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _SteamGridDBKeyInput extends StatefulWidget {
  final Future<void> Function()? onSettingsChanged;

  const _SteamGridDBKeyInput({this.onSettingsChanged});

  @override
  State<_SteamGridDBKeyInput> createState() => _SteamGridDBKeyInputState();
}

class _SteamGridDBKeyInputState extends State<_SteamGridDBKeyInput> {
  late TextEditingController _controller;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('steamgriddb_api_key') ?? '';
    if (mounted) {
      setState(() {
        _controller.text = key;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showApiKeyDialog() async {
    await _loadApiKey();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.elevatedSurface,
          title: Text(
            AppLocalizations.of(context).settingsSteamGridDbTitle,
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).settingsSteamGridDbDescription,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    style: TextStyle(color: AppColors.textPrimary),
                    obscureText: _isObscured,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).settingsSteamGridDbHint,
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _isObscured = !_isObscured),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                _controller.text = '';
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('steamgriddb_api_key', '');
                if (!mounted) return;
                Navigator.pop(context);
                await widget.onSettingsChanged?.call();
                setState(() {});
              },
              child: Text('Clear', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('steamgriddb_api_key', _controller.text.trim());
                if (!mounted) return;
                Navigator.pop(context);
                await widget.onSettingsChanged?.call();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = _controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).settingsSteamGridDbTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).settingsSteamGridDbDescription,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                hasKey ? AppLocalizations.of(context).settingsConnected : AppLocalizations.of(context).settingsNotSet,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            TextButton.icon(
              onPressed: _showApiKeyDialog,
              icon: Icon(Icons.vpn_key, color: AppColors.primaryBlue, size: 18),
              label: Text('Set key', style: TextStyle(color: AppColors.primaryBlue)),
            ),
          ],
        ),
      ],
    );
  }
}
class _StreamingToggle extends StatefulWidget {
  final GameLibraryService libraryService;
  final void Function(bool gameStreaming, bool videoStreaming)? onSettingsChanged;

  const _StreamingToggle({
    required this.libraryService,
    this.onSettingsChanged,
  });

  @override
  State<_StreamingToggle> createState() => _StreamingToggleState();
}

class _StreamingToggleState extends State<_StreamingToggle> {
  late Future<bool> _gameStreamingFuture;
  late Future<bool> _videoStreamingFuture;

  @override
  void initState() {
    super.initState();
    _gameStreamingFuture = widget.libraryService.isGameStreamingEnabled();
    _videoStreamingFuture = widget.libraryService.isVideoStreamingEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _gameStreamingFuture,
      builder: (context, gameSnapshot) {
        final gameEnabled = gameSnapshot.data ?? false;
        return FutureBuilder<bool>(
          future: _videoStreamingFuture,
          builder: (context, videoSnapshot) {
            final videoEnabled = videoSnapshot.data ?? false;
            return Column(
              children: [
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context).settingsGameStreaming,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).settingsGameStreamingDesc,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: gameEnabled,
                  activeThumbColor: AppColors.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) async {
                    await widget.libraryService.setGameStreamingEnabled(value);
                    widget.onSettingsChanged?.call(value, videoEnabled);
                    if (mounted) {
                      setState(() {
                        _gameStreamingFuture = widget.libraryService.isGameStreamingEnabled();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context).settingsVideoStreaming,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).settingsVideoStreamingDesc,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: videoEnabled,
                  activeThumbColor: AppColors.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) async {
                    await widget.libraryService.setVideoStreamingEnabled(value);
                    widget.onSettingsChanged?.call(gameEnabled, value);
                    if (mounted) {
                      setState(() {
                        _videoStreamingFuture = widget.libraryService.isVideoStreamingEnabled();
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}