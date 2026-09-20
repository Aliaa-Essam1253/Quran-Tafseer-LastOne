import 'package:quraan_tafseer/models/reciter_model.dart';
import 'package:quraan_tafseer/models/surah_model.dart';

abstract class IQuranService {
  Future<List<Surah>> fetchAllSurahs();
  Future<Surah> fetchSurah(int surahNumber);
  Future<List<Reciter>> fetchReciters();
  Future<RecitationAudio?> fetchRecitation(int reciterId, int surahNumber);
}
