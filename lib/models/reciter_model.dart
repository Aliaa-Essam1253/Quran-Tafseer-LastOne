class Reciter {
  final int id;
  final String name;
  final String? style;

  Reciter({required this.id, required this.name, this.style});

  factory Reciter.fromJson(Map<String, dynamic> json) {
    final translated = json['translated_name'] as Map<String, dynamic>?;
    final arabicName = translated?['name'] as String?;

    return Reciter(
      id: json['id'] ?? 0,
      name: (arabicName != null && arabicName.trim().isNotEmpty)
          ? arabicName
          : (json['reciter_name'] ?? json['name'] ?? ''),
      style: _styleAr(json['style']),
    );
  }

   static String? _styleAr(String? style) {
    switch (style) {
      case 'Murattal':
        return 'مرتل';
      case 'Mujawwad':
        return 'مجوّد';
      case 'Muallim':
        return 'معلّم';
      default:
        return style;
    }
  }

  String get displayName => style != null ? '$name ($style)' : name;

  @override
  bool operator ==(Object other) => other is Reciter && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class RecitationAudio {
  final int id;
  final int chapterId;
  final String audioUrl;
  final String format;

  RecitationAudio({
    required this.id,
    required this.chapterId,
    required this.audioUrl,
    required this.format,
  });

  factory RecitationAudio.fromJson(Map<String, dynamic> json) {
    return RecitationAudio(
      id: json['id'] ?? 0,
      chapterId: json['chapter_id'] ?? 0,
      audioUrl: json['audio_url'] ?? json['audioUrl'] ?? '',
      format: json['format'] ?? 'mp3',
    );
  }
}