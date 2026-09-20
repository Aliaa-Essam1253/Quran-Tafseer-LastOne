import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quraan_tafseer/models/surah_model.dart';

/// Loads the full surah list from bundled assets/json/surahs.json.
/// Used by Project-1 screens (TafseerListScreen, MainNavigationScreen, etc.)
Future<List<Surah>> loadSurahs() async {
  final String jsonString = await rootBundle.loadString(
    'assets/json/surahs.json',
  );
  final List<dynamic> jsonData = json.decode(jsonString);
  return jsonData
      .map((e) => Surah.fromLocalJson(e as Map<String, dynamic>))
      .toList();
}

/// Returns the surah number for a given Arabic name from local assets.
Future<int?> getSurahNumberFromAssets(String surahName) async {
  final String jsonString = await rootBundle.loadString(
    'assets/json/surahs.json',
  );
  final List<dynamic> surahList = json.decode(jsonString);
  final surahData = surahList.firstWhere(
    (surah) => surah['name'] == surahName,
    orElse: () => null,
  );
  return surahData?['number'] as int?;
}
