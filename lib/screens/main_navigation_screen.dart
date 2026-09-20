import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/models/quran_metadata.dart';
import 'package:quraan_tafseer/models/surah_model.dart';
import 'package:quraan_tafseer/providers/quran_provider.dart';
import 'package:quraan_tafseer/quran_reader.dart';
import 'package:quraan_tafseer/screens/bookmark_screen.dart';
import 'package:quraan_tafseer/screens/quran_home_screen.dart';
import 'package:quraan_tafseer/screens/setting_screen.dart';
import 'package:quraan_tafseer/screens/tafseer_list_screen.dart';
import 'package:quraan_tafseer/utils/function_utils.dart';

import 'package:xml/xml.dart' as xml_lib;

/// Production navigation screen.
/// Tabs: القرآن | التفسير | العلامات | المستمع | الإعدادات
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String currentSurah = "الفاتحة";
  List<Surah> surahs = [];
  List<QuranPage> quranPages = [];
  List<HizbMarker> hizbMarkers = [];
  List<SajdaMaker> sajdaMakers = [];
  List<JuzMaker> juzMakers = [];
  int selectedIndex = 0;
  bool isBottomBarVisible = true;

  Key _quranReaderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    _loadQuranMetadata();
    // Kick off API data load for the audio tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quranProvider = context.read<QuranProvider>();
      quranProvider.loadSurahs();
      quranProvider.loadReciters();
    });
  }

  Future<void> _loadSurahs() async {
    final loaded = await loadSurahs();
    setState(() => surahs = loaded);
  }

  void _loadQuranMetadata() async {
    try {
      final xmlString = await rootBundle.loadString('assets/quran-data.xml');
      if (!mounted) return; // ✅ Guard against disposed widget
      setState(() {
        quranPages = _extractPages(xmlString);
        hizbMarkers = _extractHizb(xmlString);
        sajdaMakers = _extractSajda(xmlString);
        juzMakers = _extractJuz(xmlString);
        // ✅ Force QuranReader to rebuild with correct metadata
        _quranReaderKey = UniqueKey();
      });
    } catch (e) {
      debugPrint('❌ XML load error: $e');
    }
  }

  // ── XML parsers ──────────────────────────────────────────────────────────
  List<QuranPage> _extractPages(String xmlString) {
    final doc = xml_lib.XmlDocument.parse(xmlString);
    return doc
        .findAllElements('page')
        .map(
          (e) => QuranPage(
            index: int.parse(e.getAttribute('index')!),
            sura: int.parse(e.getAttribute('sura')!),
            aya: int.parse(e.getAttribute('aya')!),
          ),
        )
        .toList();
  }

  List<HizbMarker> _extractHizb(String xmlString) {
    final doc = xml_lib.XmlDocument.parse(xmlString);
    return doc
        .findAllElements('quarter')
        .map(
          (e) => HizbMarker(
            index: int.parse(e.getAttribute('index')!),
            sura: int.parse(e.getAttribute('sura')!),
            aya: int.parse(e.getAttribute('aya')!),
          ),
        )
        .toList();
  }

  List<SajdaMaker> _extractSajda(String xmlString) {
    final doc = xml_lib.XmlDocument.parse(xmlString);
    return doc
        .findAllElements('sajda')
        .map(
          (e) => SajdaMaker(
            index: int.parse(e.getAttribute('index')!),
            sura: int.parse(e.getAttribute('sura')!),
            aya: int.parse(e.getAttribute('aya')!),
          ),
        )
        .toList();
  }

  List<JuzMaker> _extractJuz(String xmlString) {
    final doc = xml_lib.XmlDocument.parse(xmlString);
    return doc
        .findAllElements('juz')
        .map(
          (e) => JuzMaker(
            index: int.parse(e.getAttribute('index')!),
            sura: int.parse(e.getAttribute('sura')!),
            aya: int.parse(e.getAttribute('aya')!),
          ),
        )
        .toList();
  }

  // ── Navigation helpers ───────────────────────────────────────────────────
  void _selectSurah(String surahName) {
    setState(() {
      currentSurah = surahName;
      selectedIndex = 0;
      _quranReaderKey = UniqueKey();
      isBottomBarVisible = true;
    });
    Navigator.pop(context);
  }

  void _setBottomBarVisibility(bool visible) {
    setState(() => isBottomBarVisible = visible);
  }

  Widget _getSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        // ✅ Wait until metadata is loaded before rendering
        if (quranPages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: MyColors.deepBlue),
          );
        }
        return QuranReader(
          key: _quranReaderKey,
          surahName: currentSurah,
          initialAyahIndex: null,
          setParentBarsVisibility: _setBottomBarVisibility,
          quranPages: quranPages,
          hizbMarkers: hizbMarkers,
          sajdaMakers: sajdaMakers,
          juzMakers: juzMakers,
        );
      case 1:
        return const TafseerListScreen();
      case 2:
        return const BookmarksScreen();
      case 3:
        // Project-2: API-based audio surah list
        return const QuranHomeScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const SizedBox();
    }
  }

  String _getAppBarTitle() {
    switch (selectedIndex) {
      case 0:
        return "القرآن";
      case 1:
        return "التفسير";
      case 2:
        return "العلامات المرجعية";
      case 3:
        return "المستمع";
      case 4:
        return "الإعدادات";
      default:
        return "";
    }
  }

  bool _shouldShowDrawer() => selectedIndex == 0 || selectedIndex == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2, // To prevent Gestures Issue
      drawer: _shouldShowDrawer() ? _buildDrawer() : null,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: MyColors.deepBlue,
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: (selectedIndex == 0 && !isBottomBarVisible)
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                setState(() {
                  selectedIndex = index;
                  isBottomBarVisible = true;
                });
              },
              selectedItemColor: MyColors.deepBlue,
              unselectedItemColor: Theme.of(context).unselectedWidgetColor,
              backgroundColor: Theme.of(
                context,
              ).bottomNavigationBarTheme.backgroundColor,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book),
                  label: "القرآن",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.translate),
                  label: "التفسير",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark),
                  label: "العلامات",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.headphones),
                  label: "المستمع",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: "الإعدادات",
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 20),
            const Text(
              "السور",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...surahs.map(
              (surah) => GestureDetector(
                onTap: () => _selectSurah(surah.name),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: MyColors.deepBlue.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "الترتيب: ${surah.number}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "النوع: ${surah.type}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "الآيات: ${surah.ayahCount}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
