import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadStorage {
  static const _prefix = 'dl_';
  static const _indexKey = 'dl_index';
  static const _lastReciterKey = 'last_reciter_id';
  static const _lastReciterNameKey = 'last_reciter_name';
  static const _lastReciterStyleKey = 'last_reciter_style';

  static Future<void> saveLastReciter(
    int id,
    String name,
    String? style,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReciterKey, id);
    await prefs.setString(_lastReciterNameKey, name);
    if (style != null) {
      await prefs.setString(_lastReciterStyleKey, style);
    } else {
      await prefs.remove(_lastReciterStyleKey);
    }
  }

  static Future<Map<String, dynamic>?> loadLastReciter() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_lastReciterKey);
    final name = prefs.getString(_lastReciterNameKey);
    if (id == null || name == null) return null;
    return {
      'id': id,
      'name': name,
      'style': prefs.getString(_lastReciterStyleKey),
    };
  }

  static Future<void> save(int surahNumber, int reciterId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}${surahNumber}_$reciterId', path);
    final index = _getIndex(prefs);
    final entry = '${surahNumber}_$reciterId';
    if (!index.contains(entry)) {
      index.add(entry);
      await prefs.setString(_indexKey, index.join(','));
    }
  }

  static Future<String?> get(int surahNumber, int reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('${_prefix}${surahNumber}_$reciterId');
    if (path == null) return null;
    if (!kIsWeb && !await File(path).exists()) {
      await _remove(prefs, surahNumber, reciterId);
      return null;
    }
    return path;
  }

  static Future<bool> isDownloaded(int surahNumber, int reciterId) async =>
      (await get(surahNumber, reciterId)) != null;

  static Future<void> _remove(
    SharedPreferences prefs,
    int surahNumber,
    int reciterId,
  ) async {
    await prefs.remove('${_prefix}${surahNumber}_$reciterId');
    final index = _getIndex(prefs);
    index.remove('${surahNumber}_$reciterId');
    await prefs.setString(_indexKey, index.join(','));
  }

  static List<String> _getIndex(SharedPreferences prefs) {
    final raw = prefs.getString(_indexKey) ?? '';
    return raw.isEmpty ? [] : raw.split(',');
  }
}
