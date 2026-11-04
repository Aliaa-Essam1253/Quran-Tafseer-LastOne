import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/models/surah_model.dart';
import 'package:quraan_tafseer/screens/surah_audio_screen.dart';
import 'package:quraan_tafseer/screens/tafseer_screen.dart';
import 'package:quraan_tafseer/surahTafseerMap.dart';
import 'package:quraan_tafseer/utils/function_utils.dart';
import 'package:quraan_tafseer/utils/ui_utils.dart';

/// Key of the introduction recording inside [surahAudioUrls].
const _introKey = 'المقدمة';

class TafseerListScreen extends StatefulWidget {
  const TafseerListScreen({super.key});

  @override
  State<TafseerListScreen> createState() => _TafseerListScreenState();
}

class _TafseerListScreenState extends State<TafseerListScreen> {
  List<Surah> surahs = [];
  List<Surah> filteredSurahs = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final loaded = await loadSurahs();
    setState(() {
      surahs = loaded;
      filteredSurahs = loaded;
    });
  }

  void filterSurahs(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      filteredSurahs = surahs
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.type.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  bool get _showIntro => searchController.text.trim().isEmpty;

  void _openIntro() {
    final urls = surahAudioUrls[_introKey];
    if (urls == null || urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تسجيل المقدمة غير متاح حاليًا')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahAudioScreen(
          title: 'مقدمة التفسير',
          url: urls.first,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: surahs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSurahs,
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم السورة أو نوعها (مكية / مدنية)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    // +1 for the intro card, shown only when not searching.
                    itemCount: filteredSurahs.length + (_showIntro ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_showIntro && i == 0) {
                        return _IntroCard(onTap: _openIntro);
                      }
                      final index = _showIntro ? i - 1 : i;
                      return surahCard(
                        context,
                        filteredSurahs[index],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TafsirScreen(
                              surahName: filteredSurahs[index].name,
                              EnglishName: filteredSurahs[index].englishName,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Highlighted card at the top of the tafseer list that opens the
/// audio introduction of the book.
class _IntroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _IntroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = MyColors.audioGold;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [MyColors.deepBlue, MyColors.darkBlue],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gold.withOpacity(0.7), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withOpacity(0.15),
                      border: Border.all(color: gold, width: 1.2),
                    ),
                    child: const Icon(Icons.headphones, color: gold, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مقدمة التفسير',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تسجيل صوتي · نحو ١٠ دقائق · ابدأ من هنا',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_fill, color: gold, size: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}