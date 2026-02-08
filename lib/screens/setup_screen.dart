import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../services/game_library_service.dart';
import '../services/presence_service.dart';
import '../l10n/app_localizations.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const SetupScreen({super.key, required this.onSetupComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final GameLibraryService _libraryService = GameLibraryService();
  final PresenceService _presenceService = PresenceService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _plazanetUrlController = TextEditingController(text: 'https://accounts.plazanet.org');
  final TextEditingController _plazanetUsernameController = TextEditingController();
  final TextEditingController _plazanetPasswordController = TextEditingController();
  int _currentStep = 0;
  bool _plazaNetLogin = false;
  bool _isLoggingIn = false;
  String _selectedLanguage = 'en';

  bool get _hasName => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_language') ?? 'en';
    setState(() {
      _selectedLanguage = savedLanguage;
    });
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _plazanetUrlController.dispose();
    _plazanetUsernameController.dispose();
    _plazanetPasswordController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    await _libraryService.saveSetupComplete(name, _plazaNetLogin);
    if (apiKey.isNotEmpty) {
      await _libraryService.saveApiKey(apiKey);
    }
    widget.onSetupComplete();
  }

  Future<void> _loginToPlazaNet() async {
    setState(() => _isLoggingIn = true);
    try {
      final url = _plazanetUrlController.text.trim();
      final username = _plazanetUsernameController.text.trim();
      final password = _plazanetPasswordController.text.trim();

      await _libraryService.savePlazaNetUrl(url);

      final token = await _presenceService.login(url, username, password);

      if (token != null) {
        await _presenceService.saveAuthToken(token);
        await _libraryService.savePlazaNetCredentials(username, url);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).msgLoginSuccess),
            backgroundColor: Colors.green,
          ),
        );
        _goToStep(2);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).msgLoginFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).msgError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  List<Widget> _buildStepWidgets() {
    switch (_currentStep) {
      case 0:
        return [
          Text(
            AppLocalizations.of(context).setupNameLabel,
            style: const TextStyle(fontSize: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).setupNameHint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.elevatedSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            textAlign: TextAlign.center,
            onSubmitted: (_) {
              if (_hasName) {
                _goToStep(1);
              }
            },
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).langSelectLanguage,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLanguageSelector(context),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _hasName ? () => _goToStep(1) : null,
            child: Text(AppLocalizations.of(context).actionContinue),
          ),
        ];
      case 1:
        return [
          Text(
            AppLocalizations.of(context).setupGreeting(_nameController.text),
            style: const TextStyle(fontSize: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).setupConnectPrompt,
            style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).setupConnectDescription,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            title: Text(AppLocalizations.of(context).setupPlazaNetTitle, style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(
              AppLocalizations.of(context).setupConnectOptional,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            value: _plazaNetLogin,
            onChanged: (value) => setState(() => _plazaNetLogin = value),
            activeThumbColor: AppColors.primaryBlue,
          ),
          if (_plazaNetLogin) ...[
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).setupPlazaNetAccountTitle,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _plazanetUrlController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).setupPlazaNetUrl,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'https://accounts.plazanet.org',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.elevatedSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plazanetUsernameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).setupPlazaNetUsername,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: AppLocalizations.of(context).setupPlazaNetUsername,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.elevatedSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plazanetPasswordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).setupPlazaNetPassword,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: AppLocalizations.of(context).setupPlazaNetPassword,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.elevatedSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => _goToStep(0),
                child: Text(AppLocalizations.of(context).actionBack),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isLoggingIn
                    ? null
                    : (_plazaNetLogin ? _loginToPlazaNet : () => _goToStep(2)),
                child: _isLoggingIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_plazaNetLogin
                        ? AppLocalizations.of(context).setupLoginContinue
                        : AppLocalizations.of(context).setupContinue),
              ),
            ],
          ),
        ];
      case 2:
        return [
          Text(
            AppLocalizations.of(context).setupSteamGridDbTitle,
            style: const TextStyle(fontSize: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).setupSteamGridDbDescription,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).setupSteamGridDbHint,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).setupSteamGridDbApiHint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.elevatedSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => _goToStep(1),
                child: Text(AppLocalizations.of(context).actionBack),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _completeSetup,
                child: Text(AppLocalizations.of(context).actionGetStarted),
              ),
            ],
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: AppColors.elevatedSurface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
            if (value != null) {
              final navigator = Navigator.of(context);
              setState(() {
                _selectedLanguage = value;
              });
              await _saveLanguagePreference(value);
              if (mounted) {
                navigator.pushNamedAndRemoveUntil('/', (route) => false);
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final stepWidgets = _buildStepWidgets();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const Icon(
                Icons.games,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).setupWelcomeTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 48),
              ...stepWidgets,
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
