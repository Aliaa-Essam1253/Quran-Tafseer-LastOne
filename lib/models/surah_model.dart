/// Unified Surah model — satisfies both the local JSON (Project 1)
/// and the alquran.cloud / quran.com API (Project 2).
class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String
  revelationType; // "Meccan" | "Medinan"  (API) or mapped from type
  final int numberOfAyahs;
  final List<Ayah> ayahs;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    this.englishNameTranslation = '',
    required this.revelationType,
    required this.numberOfAyahs,
    this.ayahs = const [],
  });

  // ── Convenience getters so old Project-1 code still compiles ──────────────
  String get type => revelationType;
  int get ayahCount => numberOfAyahs;

  // ── Project-1 local assets/json/surahs.json ────────────────────────────────
  // Expected shape: { number, name, englishName, type, ayahCount }
  factory Surah.fromLocalJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      revelationType: json['type'] ?? json['revelationType'] ?? '',
      numberOfAyahs: json['ayahCount'] ?? json['numberOfAyahs'] ?? 0,
    );
  }

  // ── Project-2 alquran.cloud list endpoint ─────────────────────────────────
  // Expected shape: { number, name, englishName, englishNameTranslation,
  //                   revelationType, numberOfAyahs }
  factory Surah.fromListJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      revelationType: json['revelationType'] ?? json['type'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? json['ayahCount'] ?? 0,
    );
  }

  // ── Project-2 alquran.cloud detail endpoint (includes ayahs) ─────────────
  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      revelationType: json['revelationType'] ?? json['type'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? json['ayahCount'] ?? 0,
      ayahs:
          (json['ayahs'] as List<dynamic>?)
              ?.map((a) => Ayah.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) => other is Surah && other.number == number;

  @override
  int get hashCode => number.hashCode;
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] ?? 0,
      text: json['text'] ?? '',
      numberInSurah: json['numberInSurah'] ?? 0,
      juz: json['juz'] ?? 0,
    );
  }
}
