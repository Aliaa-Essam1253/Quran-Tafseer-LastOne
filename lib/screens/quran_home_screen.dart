import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/models/surah_model.dart';
import 'package:quraan_tafseer/providers/quran_provider.dart';
import 'package:quraan_tafseer/screens/surah_player_screen.dart';

/// Project-2 screen: lists Surahs fetched from the API with a search bar,
/// then navigates to SurahPlayerScreen. Fully theme-aware.
class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<QuranProvider>();
      if (p.surahListState == LoadingState.idle) p.loadSurahs();
      if (p.recitersState == LoadingState.idle) p.loadReciters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).colorScheme.background;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          _buildSearchBar(isDark),
          Expanded(child: _buildSurahList(isDark)),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      width: double.infinity,
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Texts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القرآن الكريم',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 26,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'استمع إلى كلام الله',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                //const SizedBox(width: 14),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MyColors.deepBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: MyColors.deepBlue.withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.headphones_rounded,
                    color: MyColors.deepBlue,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ── Search bar ───────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
            isDark ? Colors.white12 : MyColors.deepGreen.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: textColor, fontSize: 15),
          onChanged: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'ابحث عن سورة...',
            hintStyle: TextStyle(color: hintColor, fontSize: 14),
            suffixIcon: const Icon(Icons.search, color: MyColors.deepBlue, size: 20),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ── Surah list ───────────────────────────────────────────────────────────────
  Widget _buildSurahList(bool isDark) {
    return Consumer<QuranProvider>(
      builder: (ctx, provider, _) {
        if (provider.surahListState == LoadingState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: MyColors.deepBlue),
          );
        }
        if (provider.surahListState == LoadingState.error) {
          return _ErrorState(
            message: provider.errorMessage ?? 'حدث خطأ',
            onRetry: provider.retry,
          );
        }

        final list = _query.isEmpty
            ? provider.surahs
            : provider.surahs.where((s) {
          final q = _normalizeArabic(_query);
          if (q.isEmpty) return true;
          return _normalizeArabic(s.name).contains(q) ||
              s.englishName
                  .toLowerCase()
                  .contains(_query.toLowerCase()) ||
              s.number.toString().startsWith(_query);
        }).toList();

        if (list.isEmpty) {
          return Center(
            child: Text(
              'لم يتم العثور على سورة',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: list.length,
          itemBuilder: (ctx, i) => _SurahTile(
            surah: list[i],
            isDark: isDark,
            onTap: () {
              provider.selectSurah(list[i]);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SurahPlayerScreen()),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Arabic normalizer ─────────────────────────────────────────────────────────
String _normalizeArabic(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if ((rune >= 0x064B && rune <= 0x065F) ||
        (rune >= 0x0610 && rune <= 0x061A) ||
        rune == 0x0640 ||
        rune == 0x0670 ||
        (rune >= 0x06D6 && rune <= 0x06ED)) continue;
    if (rune == 0x0623 || rune == 0x0625 || rune == 0x0622 || rune == 0x0671) {
      buffer.writeCharCode(0x0627);
    } else if (rune == 0x0629) {
      buffer.writeCharCode(0x0647);
    } else if (rune == 0x0649) {
      buffer.writeCharCode(0x064A);
    } else if (rune == 0x0624) {
      buffer.writeCharCode(0x0648);
    } else if (rune == 0x0626) {
      buffer.writeCharCode(0x064A);
    } else if (rune == 0x0621) {
      buffer.writeCharCode(0x0627);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString().trim();
}

// ── Surah tile ────────────────────────────────────────────────────────────────
class _SurahTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;
  final bool isDark;

  const _SurahTile({
    required this.surah,
    required this.onTap,
    required this.isDark,
  });

  String get _revelationAr =>
      surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية';

  String _toArabicNum(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final isMeccan = surah.revelationType == 'Meccan';
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    final badgeBg = isMeccan
        ? (isDark
        ? MyColors.deepGreen.withOpacity(0.25)
        : MyColors.deepGreen.withOpacity(0.12))
        : (isDark
        ? MyColors.deepBlue.withOpacity(0.25)
        : MyColors.deepBlue.withOpacity(0.10));
    final badgeText = isMeccan ? MyColors.deepGreen : MyColors.deepBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
            isDark ? Colors.white12 : MyColors.deepGreen.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: MyColors.deepBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _toArabicNum(surah.number),
                  style: const TextStyle(
                    color: MyColors.deepBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${surah.numberOfAyahs} آية',
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                      Text(' · ',
                          style: TextStyle(color: subColor, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _revelationAr,
                          style: TextStyle(
                            color: badgeText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.headphones_outlined,
                color: MyColors.deepBlue, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: MyColors.deepBlue),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.deepBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
