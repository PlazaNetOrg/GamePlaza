import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_colors.dart';
import 'services/game_library_service.dart';
import 'screens/setup_screen.dart';
import 'screens/launcher_home_page.dart';
import 'l10n/app_localizations.dart';

class GamePlaza extends StatefulWidget {
  const GamePlaza({super.key});

  static _GamePlazaState? of(BuildContext context) {
    return context.findAncestorStateOfType<_GamePlazaState>();
  }

  @override
  State<GamePlaza> createState() => _GamePlazaState();
}

class _GamePlazaState extends State<GamePlaza> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language') ?? 'en';
    if (mounted) {
      setState(() {
        _locale = Locale(languageCode);
      });
    }
  }

  void updateLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GamePlaza',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkSurface,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryBlue,
          secondary: AppColors.secondaryBlue,
          surface: AppColors.darkSurface,
        ),
        cardTheme: CardThemeData(
          color: AppColors.primaryBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final GameLibraryService _libraryService = GameLibraryService();
  bool _isLoading = true;
  bool _setupComplete = false;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final setupComplete = await _libraryService.isSetupComplete();
    if (!mounted) return;
    setState(() {
      _setupComplete = setupComplete;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }

    if (!_setupComplete) {
      return SetupScreen(onSetupComplete: () {
        setState(() {
          _setupComplete = true;
        });
      });
    }

    return const LauncherHomePage();
  }
}
