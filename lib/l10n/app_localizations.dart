import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('pl'),
  ];

  // Navigation
  String get navHome;
  String get navLibrary;
  String get navPlazaNet;
  String get navStore;
  String get navSettings;

  // Home
  String get homeNoGamesTitle;
  String get homeNoGamesSubtitle;
  String get homeGoToLibrary;
  String get homeLastPlayedLabel;
  String get homeNeverPlayed;
  String get homePlay;
  String get homeDetails;
  String homeGamesCount(int count);
  String homeAppsCount(int count);
  String get homeCharging;

  // Actions
  String get actionPlay;
  String get actionBack;
  String get actionOpen;
  String get actionOpenApp;
  String get actionSearch;
  String get actionReload;
  String get actionClear;
  String get actionApply;
  String get actionCancel;
  String get actionContinue;
  String get actionGetStarted;
  String get actionReset;
  String get actionDelete;
  String get actionDeleteAll;

  // Setup
  String get setupWelcomeTitle;
  String get setupWelcomeMessage;
  String get setupNameLabel;
  String get setupNameHint;
  String setupGreeting(String name);
  String get setupConnectPrompt;
  String get setupConnectDescription;
  String get setupConnectOptional;
  String get setupPlazaNetAccountTitle;
  String get setupLoginContinue;
  String get setupContinue;
  String get setupSteamGridDbTitle;
  String get setupSteamGridDbDescription;
  String get setupSteamGridDbHint;
  String get setupSteamGridDbApiHint;
  String get setupPlazaNetTitle;
  String get setupPlazaNetMessage;
  String get setupPlazaNetUrl;
  String get setupPlazaNetUsername;
  String get setupPlazaNetPassword;
  String get setupPlazaNetSkip;
  String get setupPlazaNetLogin;
  String get setupCompleteTitle;
  String get setupCompleteMessage;

  // Language
  String get langSelectLanguage;
  String get langEnglish;
  String get langPolish;

  // Settings
  String get settingsTitle;
  String get settingsAccount;
  String get settingsDisplayName;
  String get settingsIntegrations;
  String get settingsNotSet;
  String get settingsPlazaNetTitle;
  String get settingsConnected;
  String get settingsNotConnected;
  String get settingsResetTitle;
  String get settingsResetDescription;
  String get settingsSetup;
  String get settingsPresence;
  String get settingsBackgroundTracking;
  String get settingsBackgroundTrackingDesc;
  String get settingsPresenceOverall;
  String get settingsPresenceOverallDesc;
  String get settingsPresenceGame;
  String get settingsPresenceGameDesc;
  String get settingsPresenceLoginRequired;
  String get settingsSteamGridDbTitle;
  String get settingsSteamGridDbDescription;
  String get settingsSteamGridDbHint;
  String get settingsData;
  String get settingsResetSetup;
  String get settingsResetSetupDialog;
  String get settingsResetSetupMessage;
  String get settingsClearData;
  String get settingsClearDataDialog;
  String get settingsClearDataMessage;
  String get settingsOpenAndroidSettings;
  String get settingsPlazaNetConnected;
  String get settingsPlazaNetNotConnected;

  // Library
  String get libraryNoGames;
  String get libraryAddGame;
  String get librarySearchPlaceholder;
  String get libraryPlayTime;
  String get libraryLastPlayed;
  String get libraryNever;
  String get libraryTabGames;
  String get libraryTabAllApps;
  String get libraryNoApps;
  String get libraryReloadSearchHint;
  String libraryFilterLabel(String query);
  String get libraryReloadTooltip;
  String get librarySearchTooltip;
  String get libraryAddAsGame;
  String get libraryAdd;
  String get libraryUninstallApp;
  String get libraryUninstall;
  String get libraryGameTitleHint;
  String libraryUninstallConfirm(String appName);

  // Store
  String get storeComingSoon;
  String get storeGoToPlayStore;
  String get storeUnableToOpen;

  // PlazaNet
  String get plazaNetNotConnected;
  String get plazaNetConnectMessage;
  String get plazaNetFriendsTitle;
  String get plazaNetNoFriends;
  String plazaNetComingSoonTitle(String label);
  String get plazaNetComingSoonSubtitle;

  // Game details
  String get gameDetailsTitle;
  String get gameDetailsLaunch;
  String gameDetailsPlayTime(String formatted);
  String gameDetailsLastPlayed(String formatted);
  String get gameDetailsArtwork;
  String get gameDetailsSetCover;
  String get gameDetailsSetBanner;
  String get gameDetailsManagement;
  String get gameDetailsRemoveFromLibrary;
  String get gameDetailsUninstallApp;
  String get gameDetailsRemoveDialogTitle;
  String gameDetailsRemoveDialogMessage(String title);
  String get gameDetailsUninstallDialogTitle;
  String gameDetailsUninstallDialogMessage(String title);
  String get gameDetailsCancel;
  String get gameDetailsRemove;
  String get gameDetailsUninstall;
  String get gameDetailsToday;
  String get gameDetailsYesterday;
  String gameDetailsDaysAgo(int days);

  // Game dialogs
  String get gameDialogsClose;
  String get gameDialogsMatchingGames;
  String get gameDialogsSearchHint;
  String get gameDialogsEnterSearchTerm;
  String get gameDialogsNoGamesFound;
  String get gameDialogsAvailableCovers;
  String get gameDialogsAvailableBanners;
  String gameDialogsImagesCount(int count);
  String get gameDialogsSearchForArtwork;
  String get gameDialogsNoCovers;
  String get gameDialogsNoBanners;
  String get gameDialogsSetCover;
  String get gameDialogsSetBanner;
  String get gameDialogsCoverUpdated;
  String get gameDialogsBannerUpdated;
  String get gameDialogsCancel;

  // Messages
  String get msgLoginSuccess;
  String get msgLoginFailed;
  String get msgError;
  String get msgGameAdded;
  String get msgShortcutAdded;
  String get msgArtworkError;

  // Time
  String get timeHour;
  String get timeHours;
  String get timeMinute;
  String get timeMinutes;
  String get timeJustNow;

  // Common
  String get appName;
  String get loading;
  String get unknown;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'pl'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'pl':
        return AppLocalizationsPl();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
