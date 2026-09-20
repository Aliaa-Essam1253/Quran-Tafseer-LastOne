import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/screens/surah_audio_screen.dart';

class TafseerAudioScreen extends StatefulWidget {
  const TafseerAudioScreen({super.key});

  @override
  TafseerAudioScreenState createState() => TafseerAudioScreenState();
}

class TafseerAudioScreenState extends State<TafseerAudioScreen> {
  // Map: surahName -> first direct .mp3 URL for that surah
  Map<String, String> uniqueSurahs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/quran_mp3_links.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      for (var item in jsonData) {
        final name = item['sura_name'] as String?;
        final url = item['url'] as String?;
        if (name != null &&
            url != null &&
            url.isNotEmpty &&
            !uniqueSurahs.containsKey(name)) {
          // Use the URL exactly as-is from the JSON — they are already
          // direct archive.org /download/ .mp3 links and need no modification.
          // SurahAudioScreen will resolve any remaining HTTP redirects at play time.
          uniqueSurahs[name] = url;
        }
      }
    } catch (e) {
      debugPrint('Failed to load mp3 links: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تسجيلات التفسير',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
        backgroundColor: isDark ? MyColors.darkGreen : MyColors.deepGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MyColors.deepBlue))
          : uniqueSurahs.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد تسجيلات متاحة',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: uniqueSurahs.length,
                  itemBuilder: (context, index) {
                    final surahName = uniqueSurahs.keys.elementAt(index);
                    // Pass URL directly — no modification needed
                    final url = uniqueSurahs[surahName]!;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: MyColors.deepBlue,
                          foregroundColor: Colors.white,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        title: Text(
                          surahName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'اضغط للاستماع',
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.play_circle_outline,
                          color: MyColors.deepBlue,
                          size: 32,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurahAudioScreen(
                              title: surahName,
                              url: url, // raw URL, no manipulation
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}