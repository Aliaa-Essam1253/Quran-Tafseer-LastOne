import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _keySurahs = 'cache_surahs';
  static const _keyReciters = 'cache_reciters_v2';

  static Future<void> saveSurahs(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySurahs, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>?> loadSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySurahs);
    if (raw == null) return null;
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<void> saveReciters(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReciters, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>?> loadReciters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReciters);
    if (raw == null) return null;
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }
}