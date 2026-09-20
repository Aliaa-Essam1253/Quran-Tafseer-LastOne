import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quraan_tafseer/models/reciter_model.dart';
import 'package:quraan_tafseer/models/surah_model.dart';
import 'api_config.dart';
import 'cache_service.dart';
import 'quran_service_interface.dart';

class QuranApiService implements IQuranService {
  final http.Client _client;

  QuranApiService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<Surah>> fetchAllSurahs() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.allSurahsEndpoint))
          .timeout(const Duration(seconds: 10));
      _checkStatus(response);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      await CacheService.saveSurahs(data);
      return data.map((s) => Surah.fromListJson(s)).toList();
    } catch (e) {
      debugPrint('⚠️ fetchAllSurahs failed, loading from cache: $e');
      final cached = await CacheService.loadSurahs();
      if (cached != null && cached.isNotEmpty) {
        return cached.map((s) => Surah.fromListJson(s)).toList();
      }
      rethrow;
    }
  }

  @override
  Future<Surah> fetchSurah(int surahNumber) async {
    final response = await _client
        .get(Uri.parse(ApiConfig.surahEndpoint(surahNumber)))
        .timeout(const Duration(seconds: 10));
    _checkStatus(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Surah.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<Reciter>> fetchReciters() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.recitersEndpoint))
          .timeout(const Duration(seconds: 10));
      _checkStatus(response);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data =
          (json['recitations'] as List<dynamic>).cast<Map<String, dynamic>>();
      await CacheService.saveReciters(data);
      return data.map((r) => Reciter.fromJson(r)).toList();
    } catch (e) {
      debugPrint('⚠️ fetchReciters failed, loading from cache: $e');
      final cached = await CacheService.loadReciters();
      if (cached != null && cached.isNotEmpty) {
        return cached.map((r) => Reciter.fromJson(r)).toList();
      }
      rethrow;
    }
  }

  @override
  Future<RecitationAudio?> fetchRecitation(
    int reciterId,
    int surahNumber,
  ) async {
    final url = ApiConfig.recitationEndpoint(reciterId, surahNumber);
    debugPrint('🎵 Fetching audio: $url');
    final response =
        await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    _checkStatus(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = json['audio_file'];
    if (raw == null) return null;
    return RecitationAudio.fromJson(raw as Map<String, dynamic>);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}
