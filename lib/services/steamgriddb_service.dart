import 'dart:convert';
import 'package:http/http.dart' as http;

class SteamGridDBService {
  final String apiKey;
  static const String baseUrl = 'https://www.steamgriddb.com/api/v2';

  SteamGridDBService({required this.apiKey});

  Future<List<GameSearchResult>> searchGame(String gameName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/autocomplete/$gameName'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          try {
            return (data['data'] as List)
                .map((item) => GameSearchResult.fromJson(item as Map<String, dynamic>))
                .toList();
          } catch (e) {
            return [];
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<GameImage>> getGridImages(int gameId, {String? style}) async {
    try {
      final url = style != null
          ? '$baseUrl/grids/game/$gameId?styles=$style'
          : '$baseUrl/grids/game/$gameId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => GameImage.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<GameImage>> getHeroImages(int gameId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/heroes/game/$gameId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => GameImage.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<GameImage>> getLogoImages(int gameId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logos/game/$gameId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => GameImage.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<GameImage>> getIconImages(int gameId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/icons/game/$gameId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => GameImage.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<GameImageSet> getAllImages(int gameId) async {
    final results = await Future.wait([
      getGridImages(gameId),
      getHeroImages(gameId),
      getLogoImages(gameId),
      getIconImages(gameId),
    ]);

    return GameImageSet(
      grids: results[0],
      heroes: results[1],
      logos: results[2],
      icons: results[3],
    );
  }
}

class GameSearchResult {
  final int id;
  final String name;
  final String? releaseDate;
  final List<String> types;

  GameSearchResult({
    required this.id,
    required this.name,
    this.releaseDate,
    required this.types,
  });

  factory GameSearchResult.fromJson(Map<String, dynamic> json) {
    return GameSearchResult(
      id: json['id'] as int,
      name: json['name'] as String,
      releaseDate: json['release_date'] != null ? json['release_date'].toString() : null,
      types: (json['types'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class GameImage {
  final int id;
  final String url;
  final String? thumb;
  final int width;
  final int height;
  final String? style;
  final String? language;

  GameImage({
    required this.id,
    required this.url,
    this.thumb,
    required this.width,
    required this.height,
    this.style,
    this.language,
  });

  factory GameImage.fromJson(Map<String, dynamic> json) {
    return GameImage(
      id: json['id'] as int,
      url: json['url'] as String,
      thumb: json['thumb'] as String?,
      width: json['width'] as int,
      height: json['height'] as int,
      style: json['style'] as String?,
      language: json['language'] as String?,
    );
  }
}

class GameImageSet {
  final List<GameImage> grids;
  final List<GameImage> heroes;
  final List<GameImage> logos;
  final List<GameImage> icons;

  GameImageSet({
    required this.grids,
    required this.heroes,
    required this.logos,
    required this.icons,
  });

  bool get hasImages =>
      grids.isNotEmpty || heroes.isNotEmpty || logos.isNotEmpty || icons.isNotEmpty;
}
