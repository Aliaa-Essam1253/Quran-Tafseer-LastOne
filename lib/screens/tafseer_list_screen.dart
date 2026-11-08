import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/models/surah_model.dart';
import 'package:quraan_tafseer/screens/intro_text_screen.dart';
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
  bool _hasIntroText = false;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    loadIntroBlocks().then((blocks) {
      if (mounted) setState(() => _hasIntroText = blocks != null);
    });
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

  void _readIntro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IntroTextScreen()),
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
                        return _IntroCard(
                          onListen: _openIntro,
                          onRead: _hasIntroText ? _readIntro : null,
                        );
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

/// Highlighted card at the top of the tafseer list for the book's
/// introduction: listen to the recording and (when the text is available)
/// read it.
class _IntroCard extends StatelessWidget {
  final VoidCallback onListen;
  final VoidCallback? onRead;
  const _IntroCard({required this.onListen, this.onRead});

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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gold.withOpacity(0.15),
                        border: Border.all(color: gold, width: 1.2),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          color: gold, size: 24),
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
                            onRead != null
                                ? 'اقرأها أو استمع إليها · ابدأ من هنا'
                                : 'تسجيل صوتي · نحو ١٠ دقائق · ابدأ من هنا',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onRead != null) ...[
                      Expanded(
                        child: _IntroButton(
                          icon: Icons.menu_book_rounded,
                          label: 'قراءة',
                          filled: true,
                          onTap: onRead!,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _IntroButton(
                        icon: Icons.headphones,
                        label: 'استماع',
                        filled: onRead == null,
                        onTap: onListen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _IntroButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = MyColors.audioGold;
    final fg = filled ? MyColors.darkBlue : gold;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        height: 42,
        decoration: BoxDecoration(
          color: filled ? gold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: gold, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}