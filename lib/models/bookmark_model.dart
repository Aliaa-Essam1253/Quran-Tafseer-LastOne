class Bookmark {
  final String id;
  final String surahName;
  final int ayahIndex;
  final String snippet;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.surahName,
    required this.ayahIndex,
    required this.snippet,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahName': surahName,
    'ayahIndex': ayahIndex,
    'snippet': snippet,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      surahName: json['surahName'],
      ayahIndex: json['ayahIndex'],
      snippet: json['snippet'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
