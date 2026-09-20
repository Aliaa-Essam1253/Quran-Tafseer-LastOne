class ApiConfig {
  static const String quranBaseUrl = 'https://api.alquran.cloud/v1';
  static const String recitationBaseUrl = 'https://api.quran.com/api/v4';

  static String get allSurahsEndpoint => '$quranBaseUrl/surah';
  static String surahEndpoint(int surahNumber) =>
      '$quranBaseUrl/surah/$surahNumber';
  static String get recitersEndpoint =>
      '$recitationBaseUrl/resources/recitations?language=ar';
  static String recitationEndpoint(int reciterId, int chapterNumber) =>
      '$recitationBaseUrl/chapter_recitations/$reciterId/$chapterNumber';
}