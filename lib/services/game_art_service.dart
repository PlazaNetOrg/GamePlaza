import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum GameArtType { cover, banner }

class GameArtService {
  Future<Directory> _gameArtRoot() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'game_art'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> saveGameArt({
    required String gameId,
    required String imageUrl,
    required GameArtType type,
  }) async {
    final root = await _gameArtRoot();
    final gameDir = Directory(p.join(root.path, gameId));
    if (!await gameDir.exists()) {
      await gameDir.create(recursive: true);
    }

    final pattern = type == GameArtType.cover ? 'cover' : 'banner';
    final existing = gameDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith(pattern));
    for (final file in existing) {
      try {
        await file.delete();
      } catch (_) {}
    }

    final ext = _extensionFromUrl(imageUrl);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${pattern}_$ts$ext';
    final file = File(p.join(gameDir.path, fileName));

    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    throw Exception('Failed to download image: HTTP ${response.statusCode}');
  }

  Future<void> deleteArt(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearGameArt(String gameId) async {
    final root = await _gameArtRoot();
    final gameDir = Directory(p.join(root.path, gameId));
    if (await gameDir.exists()) {
      await gameDir.delete(recursive: true);
    }
  }

  String _extensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final ext = p.extension(uri.path);
    if (ext.isNotEmpty) return ext;
    return '.jpg';
  }
}
