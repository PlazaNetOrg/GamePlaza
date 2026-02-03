import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../services/game_library_service.dart';
import '../services/installed_apps_service.dart';
import '../services/presence_service.dart';

class SettingsScreen extends StatefulWidget {
  final GameLibraryService libraryService;
  final InstalledAppsService appsService;
  final PresenceService presenceService;

  const SettingsScreen({
    super.key,
    required this.libraryService,
    required this.appsService,
    required this.presenceService,
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
              _LanguagePicker(),
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
              _SteamGridDBKeyInput(),
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
          style: const TextStyle(
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
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        subtitle: Text(
          snapshot.data ?? AppLocalizations.of(context).settingsNotSet,
          style: const TextStyle(color: AppColors.textSecondary),
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
              style: const TextStyle(color: AppColors.textPrimary)),
          subtitle: Text(
            snapshot.data ?? false
                ? usernameSnapshot.data ?? AppLocalizations.of(context).settingsConnected
                : AppLocalizations.of(context).settingsNotConnected,
            style: const TextStyle(color: AppColors.textSecondary),
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
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).settingsResetDescription,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
        title: Text(AppLocalizations.of(context).settingsResetSetupDialog, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          AppLocalizations.of(context).settingsResetSetupMessage,
          style: const TextStyle(color: AppColors.textSecondary),
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

  const _PresenceToggle({required this.presenceService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: presenceService.hasAuthToken(),
      builder: (context, snapshot) {
        if (!(snapshot.data ?? false)) {
          return Text(
            AppLocalizations.of(context).settingsPresenceLoginRequired,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
  late Future<bool> _gameEnabledFuture;

  @override
  void initState() {
    super.initState();
    _overallEnabledFuture = widget.presenceService.isOverallPresenceEnabled();
    _gameEnabledFuture = widget.presenceService.isGamePresenceEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _overallEnabledFuture,
      builder: (context, overallSnapshot) {
        final overallEnabled = overallSnapshot.data ?? false;
        return FutureBuilder<bool>(
          future: _gameEnabledFuture,
          builder: (context, gameSnapshot) {
            final gameEnabled = gameSnapshot.data ?? false;
            return Column(
              children: [
                SwitchListTile(
                  title: Text(AppLocalizations.of(context).settingsPresenceOverall,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    AppLocalizations.of(context).settingsPresenceOverallDesc,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: overallEnabled,
                  activeThumbColor: AppColors.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) async {
                    await widget.presenceService.setOverallPresenceEnabled(value);
                    setState(() {
                      _overallEnabledFuture = Future.value(value);
                      _gameEnabledFuture = Future.value(value ? gameEnabled : false);
                    });
                    if (!value) {
                      try {
                        const MethodChannel('org.plazanet.gameplaza/presence')
                            .invokeMethod('stopPresenceService');
                      } catch (e) {
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context).settingsPresenceGame,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    AppLocalizations.of(context).settingsPresenceGameDesc,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: overallEnabled && gameEnabled,
                  activeThumbColor: AppColors.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: overallEnabled
                      ? (value) async {
                          await widget.presenceService.setGamePresenceEnabled(value);
                          setState(() {
                            _gameEnabledFuture = Future.value(value);
                          });
                        }
                      : null,
                ),
              ],
            );
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
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
          style: const TextStyle(color: AppColors.textSecondary),
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
  const _LanguagePicker();

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
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(AppLocalizations.of(context).langEnglish),
                ),
                DropdownMenuItem(
                  value: 'pl',
                  child: Text(AppLocalizations.of(context).langPolish),
                ),
              ],
              onChanged: (value) async {
                if (value != null && value != currentLanguage) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_language', value);
                  setState(() {
                    _languageFuture = Future.value(value);
                  });
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
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
  const _SteamGridDBKeyInput();

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).settingsSteamGridDbTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).settingsSteamGridDbDescription,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppColors.textPrimary),
          obscureText: _isObscured,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).settingsSteamGridDbHint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.elevatedSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
            ),
          ),
          onChanged: (value) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('steamgriddb_api_key', value);
          },
        ),
      ],
    );
  }
}
