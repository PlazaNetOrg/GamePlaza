import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameLibraryService {
  static const String _gamesKey = 'game_library';
  static const String _apiKeyKey = 'steamgriddb_api_key';
  static const String _setupCompleteKey = 'setup_complete';
  static const String _userNameKey = 'user_name';
  static const String _plazanetLoginKey = 'plazanet_login';
  static const String _plazanetUrlKey = 'plazanet_url';
  static const String _plazanetUsernameKey = 'plazanet_username';

  Future<void> saveGames(List<Game> games) async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = games.map((game) => game.toJson()).toList();
    await prefs.setString(_gamesKey, json.encode(gamesJson));
  }

  Future<List<Game>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesString = prefs.getString(_gamesKey);
    
    if (gamesString == null) {
      return [];
    }

    try {
      final List<dynamic> gamesJson = json.decode(gamesString);
      return gamesJson.map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addGame(Game game) async {
    final games = await loadGames();
    games.add(game);
    await saveGames(games);
  }

  Future<void> updateGame(Game updatedGame) async {
    final games = await loadGames();
    final index = games.indexWhere((g) => g.id == updatedGame.id);
    if (index != -1) {
      games[index] = updatedGame;
      await saveGames(games);
    }
  }

  Future<void> removeGame(String gameId) async {
    final games = await loadGames();
    games.removeWhere((g) => g.id == gameId);
    await saveGames(games);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<void> saveSetupComplete(String userName, bool plazaNetLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompleteKey, true);
    await prefs.setString(_userNameKey, userName);
    await prefs.setBool(_plazanetLoginKey, plazaNetLogin);
  }

  Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompleteKey) ?? false;
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<bool> isPlazaNetLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_plazanetLoginKey) ?? false;
  }

  Future<void> savePlazaNetUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_plazanetUrlKey, url);
  }

  Future<String?> getPlazaNetUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_plazanetUrlKey);
  }

  Future<void> savePlazaNetCredentials(String username, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_plazanetUsernameKey, username);
    await prefs.setString(_plazanetUrlKey, url);
    await prefs.setBool(_plazanetLoginKey, true);
  }

  Future<String?> getPlazaNetUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_plazanetUsernameKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> clearSetupData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_setupCompleteKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_plazanetLoginKey);
    await prefs.remove(_plazanetUrlKey);
    await prefs.remove(_plazanetUsernameKey);
  }
}

class Game {
  final String id;
  final String title;
  final String coverUrl;
  final String bannerUrl;
  final String? localCoverPath;
  final String? localBannerPath;
  final DateTime? lastPlayed;
  final int playTimeSeconds;
  final String? packageName;
  final int? steamGridDbId;
  final String? shortcutUri;
  final String? shortcutId;

  Game({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.bannerUrl,
    this.localCoverPath,
    this.localBannerPath,
    this.lastPlayed,
    required this.playTimeSeconds,
    this.packageName,
    this.steamGridDbId,
    this.shortcutUri,
    this.shortcutId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'bannerUrl': bannerUrl,
      'localCoverPath': localCoverPath,
      'localBannerPath': localBannerPath,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'playTimeSeconds': playTimeSeconds,
      'packageName': packageName,
      'steamGridDbId': steamGridDbId,
      'shortcutUri': shortcutUri,
      'shortcutId': shortcutId,
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    final playTimeSecondsRaw = json['playTimeSeconds'];
    int resolvedPlayTimeSeconds = 0;
    if (playTimeSecondsRaw is int) {
      resolvedPlayTimeSeconds = playTimeSecondsRaw;
    } else if (playTimeSecondsRaw is String) {
      resolvedPlayTimeSeconds = int.tryParse(playTimeSecondsRaw) ?? 0;
    } else if (json['playTime'] != null) {
      resolvedPlayTimeSeconds = _parseLegacyPlayTimeSeconds(json['playTime'].toString());
    }

    return Game(
      id: json['id'] as String,
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String,
      bannerUrl: json['bannerUrl'] as String,
      localCoverPath: json['localCoverPath'] as String?,
      localBannerPath: json['localBannerPath'] as String?,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'] as String)
          : null,
      playTimeSeconds: resolvedPlayTimeSeconds,
      packageName: json['packageName'] as String?,
      steamGridDbId: json['steamGridDbId'] as int?,
      shortcutUri: json['shortcutUri'] as String?,
      shortcutId: json['shortcutId'] as String?,
    );
  }

  Game copyWith({
    String? id,
    String? title,
    String? coverUrl,
    String? bannerUrl,
    String? localCoverPath,
    String? localBannerPath,
    DateTime? lastPlayed,
    int? playTimeSeconds,
    String? packageName,
    int? steamGridDbId,
    String? shortcutUri,
    String? shortcutId,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      localBannerPath: localBannerPath ?? this.localBannerPath,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
      packageName: packageName ?? this.packageName,
      steamGridDbId: steamGridDbId ?? this.steamGridDbId,
      shortcutUri: shortcutUri ?? this.shortcutUri,
      shortcutId: shortcutId ?? this.shortcutId,
    );
  }
}

int _parseLegacyPlayTimeSeconds(String legacy) {
  final value = legacy.toLowerCase();
  int seconds = 0;

  final daysMatch = RegExp(r'(\d+)\s*d').firstMatch(value);
  if (daysMatch != null) {
    seconds += int.parse(daysMatch.group(1)!) * 86400;
  }

  final hoursMatch = RegExp(r'(\d+)\s*h').firstMatch(value);
  if (hoursMatch != null) {
    seconds += int.parse(hoursMatch.group(1)!) * 3600;
  }

  final minutesMatch = RegExp(r'(\d+)\s*m').firstMatch(value);
  if (minutesMatch != null) {
    seconds += int.parse(minutesMatch.group(1)!) * 60;
  }

  if (seconds == 0) {
    final numeric = int.tryParse(value.trim());
    if (numeric != null) {
      seconds = numeric;
    }
  }

  return seconds;
}
