import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/map.dart';
import 'package:quraan_tafseer/models/bookmark_model.dart';
import 'package:quraan_tafseer/models/quran_metadata.dart';
import 'package:quraan_tafseer/providers/bookmark_provider.dart';
import 'package:quraan_tafseer/surahTafseerMap.dart';
import 'package:quraan_tafseer/theme/theme_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

//import 'google_drive_service.dart'; // for HttpClient

class QuranReader extends StatefulWidget {
  final String surahName;
  final int? initialAyahIndex;
  final ValueChanged<bool>? setParentBarsVisibility;
  final List<QuranPage>? quranPages;
  final int? currentPage;
  final List<HizbMarker>? hizbMarkers;
  final List<SajdaMaker>? sajdaMakers;
  final List<JuzMaker>? juzMakers;

  const QuranReader({
    super.key,
    required this.surahName,
    this.initialAyahIndex,
    this.setParentBarsVisibility,
    this.quranPages,
    this.currentPage = 1,
    this.hizbMarkers,
    this.sajdaMakers,
    this.juzMakers,
  });

  @override
  State<QuranReader> createState() => _QuranReaderState();
}

class _QuranReaderState extends State<QuranReader> {
  List<Map<String, dynamic>> allSurahsData = [];
  bool isLoading = true;
  String errorMessage = '';
  int? selectedAyahIndex;
  late BookmarkProvider bookmarkProvider;
  late PageController _pageController;
  final ScrollController _scrollController = ScrollController();
  AudioPlayer? _audioPlayer;
  bool _audioIsPlaying = false;
  bool _audioIsLoading = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  String? _loadedAudioUrl;
  int? _currentPlayingAyahIndex;

  Map<String, List<Map<String, dynamic>>> _loadedSurahContents = {};
  Map<String, List<int>> _surahPageBreaks = {};
  Map<String, int> _lastVisitedGlobalPageIndexPerSurah =
      {}; // Stores last visited page index for each surah

  int? currentSurahNumber;
  String? currentSurahName;
  int? currentAyahCount;
  int _currentGlobalPageIndex = 0;
  int _previousGlobalPageIndex = 0; // Track previous global page index

  double _screenWidth = 0.0;
  double _screenHeight = 0.0;
  double _availablePageHeight = 0.0;
  double _currentFontSize = 22.0;

  bool _showAudioPlayer = false;
  bool _showBars = true;
  bool _isPageChanging = false;

  /*bool? _isHizbMarker(int surahNumber, int ayahNumber) {
    return widget.hizbMarkers?.any(
      (marker) => marker.sura == surahNumber && marker.aya == ayahNumber,
    );
  }*/
  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _audioIsPlaying = state == PlayerState.playing);
    });
    _audioPlayer!.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _audioDuration = d);
    });
    _audioPlayer!.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _audioPosition = p);
    });
    _audioPlayer!.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _audioIsPlaying = false;
        _audioPosition = Duration.zero;
      });
    });
  }



  Future<void> _loadAudioForSurah(String url) async {
    if (_loadedAudioUrl == url && _audioPlayer != null) {
      await _audioPlayer!.resume();
      return;
    }

    if (_audioPlayer == null) _initAudioPlayer();
    await _audioPlayer!.stop();

    if (mounted) {
      setState(() {
        _audioIsLoading = true;
        _audioPosition = Duration.zero;
        _audioDuration = Duration.zero;
        _loadedAudioUrl = null;
      });
    }

    try {
      // ✅ تحقق من وجود الملف قبل التشغيل
      final request = await HttpClient().headUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 404) {
        if (mounted) {
          setState(() => _audioIsLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'لا يوجد تسجيل لهذه الآية',

              ),
              //duration: Duration(seconds: 3),
            ),
          );
          // أخفي الـ audio player لأن مفيش ملف
          setState(() {
            _showAudioPlayer = false;
            _currentPlayingAyahIndex = null;
          });
        }
        return;
      }

      await _audioPlayer!.play(UrlSource(url));
      _loadedAudioUrl = url;
      debugPrint('✅ Audio playing: $url');
    } catch (e) {
      debugPrint('❌ Audio error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذّر تشغيل التسجيل، تحقق من اتصالك بالإنترنت',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 15),
            ),
            backgroundColor: Colors.black,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _showAudioPlayer = false;
          _currentPlayingAyahIndex = null;
        });
      }
    }

    if (mounted) setState(() => _audioIsLoading = false);
  }
  Future<void> _toggleAudio() async {
    if (_audioPlayer == null) return;
    if (_audioIsPlaying) {
      await _audioPlayer!.pause();
    } else {
      if (_loadedAudioUrl == null) return;
      await _audioPlayer!.resume();
    }
  }

  void _showSpeedOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Android 15 edge-to-edge: keep the sheet clear of the system nav bar.
      useSafeArea: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'سرعة التشغيل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _speedTile('0.75x', 0.75),
                _speedTile('1.0x (عادي)', 1.0),
                _speedTile('1.25x', 1.25),
                _speedTile('1.5x', 1.5),
                _speedTile('2.0x', 2.0),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _speedTile(String title, double speed) {
    return ListTile(
      title: Text(title),
      onTap: () async {
        await _audioPlayer?.setPlaybackRate(speed);
        Navigator.pop(context);
      },
    );
  }


  String? _resolveAudioUrl(String surahName, int ayahIndex) {
    // 1. Exact match على اسم السورة
    List<String>? urls = surahAudioUrls[surahName];

    // 2. لو مش لاقي exact → جرب prefix match (زي "الفاتحة" → "الفاتحة الآية")
    if (urls == null || urls.isEmpty) {
      final prefixKey = surahAudioUrls.keys.firstWhere(
        (k) => k.startsWith(surahName),
        orElse: () => '',
      );
      if (prefixKey.isNotEmpty) {
        urls = surahAudioUrls[prefixKey];
      }
    }

    if (urls == null || urls.isEmpty) {
      debugPrint('⚠️ No audio URLs found for surah: $surahName');
      return null;
    }
    // 3. ✅ الـ fix الأساسي: استخدم ayahIndex عشان تجيب الـ URL الصح
    //    الـ list مرتبة من 0 → أول آية، 1 → تاني آية ... إلخ
    //    لو الـ index أكبر من الـ list نرجع آخر URL
    final safeIndex = ayahIndex.clamp(0, urls.length - 1);

    debugPrint(
        '🎵 Playing ayah ${ayahIndex + 1} of $surahName → ${urls[safeIndex]}');
    return urls[safeIndex];
  }

  Future<void> _audioSeekBy(int seconds) async {
    if (_audioPlayer == null) return;
    final target = _audioPosition + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > _audioDuration
            ? _audioDuration
            : target;
    await _audioPlayer!.seek(clamped);
  }

  String _fmtAudio(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _buildCurrentQuranLocationText(int surahNumber, int ayahNumber) {
    final hizb = _getHizbIndexForAyah(surahNumber, ayahNumber);
    if (hizb == null) return '';

    final part = (hizb - 1) ~/ 4 + 1; // رقم الحزب
    final quarterType = (hizb - 2) % 4;

    switch (quarterType) {
      case 0:
        return 'ربع الحزب $part';
      case 1:
        return 'نصف الحزب $part';
      case 2:
        return 'ثلاثة أرباع الحزب $part';
      case 3:
        return 'الحزب ${part}';
      default:
        return '';
    }

    /*final quarter = hizb % 4;
    final hizbNumber = (hizb ~/ 4) + 1;

    switch (quarter) {
      case 0:
        return 'بداية الحزب رقم $hizbNumber';
      case 1:
        return 'ربع الحزب رقم $hizbNumber';
      case 2:
        return 'نصف الحزب رقم $hizbNumber';
      case 3:
        return 'ثلاثة أرباع الحزب رقم $hizbNumber';
      default:
        return '';
    }*/
  }

  /*int? _getHizbIndexForAyah(int surahNumber, int ayahNumber) {
    final marker = widget.hizbMarkers?.firstWhereOrNull(
      (marker) => marker.sura == surahNumber && marker.aya == ayahNumber,
    );
    return marker?.index;
  }*/
  int? _getHizbIndexForAyah(int surahNumber, int ayahNumber) {
    try {
      final marker = widget.hizbMarkers?.firstWhereOrNull(
        (marker) {
          // تأكدي إن العلامة بعد أو عند (البقرة 25)
          final isBeforeFirstValidHizb =
              marker.sura < 2 || (marker.sura == 2 && marker.aya < 25);
          if (isBeforeFirstValidHizb) return false;

          return marker.sura == surahNumber && marker.aya == ayahNumber;
        },
        //orElse: () => null, // لتفادي الخطأ
      );
      return marker?.index;
    } catch (e) {
      print("❌ Error in _getHizbIndexForAyah: $e");
      return null;
    }
  }

  int? _getSajdaIndexForAyah(int surahNumber, int ayahNumber) {
    try {
      final marker = widget.sajdaMakers?.firstWhereOrNull(
        (marker) => marker.sura == surahNumber && marker.aya == ayahNumber,
      );
      return marker?.index;
    } catch (e) {
      print("❌ Error in _getSajdaIndexForAyah: $e");
      return null;
    }
  }

  int? _getJuzIndexForAyah(int surahNumber, int ayahNumber) {
    if (widget.juzMakers == null) return null;

    final sorted = widget.juzMakers!
      ..sort((a, b) {
        if (a.sura != b.sura) return a.sura.compareTo(b.sura);
        return a.aya.compareTo(b.aya);
      });

    int? currentIndex;

    for (var marker in sorted) {
      final isBeforeOrSame = (marker.sura < surahNumber) ||
          (marker.sura == surahNumber && marker.aya <= ayahNumber);

      if (isBeforeOrSame) {
        currentIndex = marker.index;
      } else {
        break;
      }
    }

    return currentIndex;
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _pageController = PageController(initialPage: 0);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _screenWidth = MediaQuery.of(context).size.width;
  //     _screenHeight = MediaQuery.of(context).size.height;
  //     _currentFontSize = Provider.of<ThemeProvider>(
  //       context,
  //       listen: false,
  //     ).fontSize;
  //     _calculateAvailablePageHeight();
  //     _loadInitialGlobalData();
  //   });
  // }

  // ✅ الكود الصح
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // خد الأبعاد الحقيقية من الـ context بعد ما الـ frame اتبنى
      final size = MediaQuery.of(context).size;
      _screenWidth = size.width;
      _screenHeight = size.height;

      _currentFontSize = Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).fontSize;

      _calculateAvailablePageHeight();

      // تأكد إن الأبعاد اتحسبت صح قبل ما تحمل البيانات
      if (_screenWidth > 0 && _screenHeight > 0) {
        await _loadInitialGlobalData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bookmarkProvider = Provider.of<BookmarkProvider>(context);

    final newFontSize = Provider.of<ThemeProvider>(context).fontSize;
    if (newFontSize != _currentFontSize) {
      setState(() {
        _currentFontSize = newFontSize;
        _calculateAvailablePageHeight();
        _recalculatePageBreaksForAllLoadedSurahs();
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentGlobalPageIndex);
        }
      });
    }
  }

  void _calculateAvailablePageHeight() {
    const double topPadding = 20.0;
    const double bottomPadding = 20.0;
    const double surahFrameHeight = 80.0;
    const double basmalaHeight = 35.0;
    const double spacerHeight = 16.0 * 2;

    final double fixedHeaderHeightForPageLayout =
        surahFrameHeight + basmalaHeight + spacerHeight;

    _availablePageHeight = _screenHeight -
        topPadding -
        bottomPadding -
        fixedHeaderHeightForPageLayout;

    final double estimatedLineHeight = _currentFontSize * 1.8;

    final double desiredAyahsHeight = estimatedLineHeight * 16;

    if (_availablePageHeight < desiredAyahsHeight) {
      _availablePageHeight = desiredAyahsHeight;
    }
  }

  void _recalculatePageBreaksForAllLoadedSurahs() {
    _surahPageBreaks.clear();
    _loadedSurahContents.forEach((surahName, ayahs) {
      _surahPageBreaks[surahName] = _calculatePageBreaksByLength(
        ayahs,
        surahName,
      );
    });
    if (_pageController.hasClients && currentSurahName != null) {
      // Find the first ayah of the current global page and jump to its new global page index
      final int firstAyahOfCurrentPage = _getFirstAyahIndexOnPage(
        _currentGlobalPageIndex,
      );
      final int newTargetPage = _getGlobalPageIndexForAyah(
        currentSurahName!,
        firstAyahOfCurrentPage,
      );
      _pageController.jumpToPage(newTargetPage);
    }
  }

  int _getFirstAyahIndexOnPage(int globalPageIndex) {
    int pageOffset = 0;
    for (var surahData in allSurahsData) {
      final String currentSurahIterationName = surahData['name'];
      final int surahPageCount = _getSurahPageCount(currentSurahIterationName);

      if (globalPageIndex >= pageOffset &&
          globalPageIndex < pageOffset + surahPageCount) {
        final int localPageIndex = globalPageIndex - pageOffset;
        if (_surahPageBreaks.containsKey(currentSurahIterationName)) {
          final List<int> pageBreaks =
              _surahPageBreaks[currentSurahIterationName]!;
          if (localPageIndex < pageBreaks.length) {
            return pageBreaks[localPageIndex];
          }
        }
        return 0; // Default to first ayah if no breaks found
      }
      pageOffset += surahPageCount;
    }
    return 0; // Default to first ayah of first surah
  }

  List<int> _calculatePageBreaksFromQuranPages(
    List<Map<String, dynamic>> ayahs,
    int surahNumber,
  ) {
    if (widget.quranPages == null || widget.quranPages!.isEmpty) {
      return [0, ayahs.length];
    }

    // Get all page boundaries for this surah, sorted
    final List<int> breaks = widget.quranPages!
        .where((p) => p.sura == surahNumber)
        .map((p) => p.aya - 1) // aya is 1-based, convert to 0-based index
        .where((idx) => idx >= 0 && idx < ayahs.length)
        .toSet()
        .toList()
      ..sort();

    // Always start from 0
    if (breaks.isEmpty || breaks.first != 0) {
      breaks.insert(0, 0);
    }

    // Always end with ayahs.length
    if (breaks.last != ayahs.length) {
      breaks.add(ayahs.length);
    }

    return breaks;
  }

  List<int> _calculatePageBreaksByLength(
    List<Map<String, dynamic>> ayahs,
    String surahName,
  ) {
    List<int> pageBreaks = [0];
    double currentPageHeight = 0;

    // Special handling for the first 5 ayahs of Al-Baqarah if they fit on one page
    if (surahName == "البقرة" && ayahs.length >= 5) {
      double tempHeightForFirstFiveAyahs = 0;
      for (int i = 0; i < 5; i++) {
        final ayahText = ayahs[i]['text'] as String;
        final textSpan = TextSpan(
          text: ayahText + ' ۝${convertToArabicNumber(i + 1)} ',
          style: TextStyle(
            fontSize: _currentFontSize,
            fontFamily: 'UthmanicHafs',
            height: 1.8,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.rtl,
          textScaleFactor: 1.0,
          maxLines: null,
        )..layout(maxWidth: _screenWidth - 40);

        tempHeightForFirstFiveAyahs += textPainter.height;
      }
      if (tempHeightForFirstFiveAyahs <= _availablePageHeight) {
        pageBreaks.add(5); // Add break after 5th ayah
        currentPageHeight = 0; // Reset current page height for next segment
      }
    }

    for (int i = pageBreaks.last; i < ayahs.length; i++) {
      final ayahText = ayahs[i]['text'] as String;
      final textSpan = TextSpan(
        text: ayahText + ' ۝${convertToArabicNumber(i + 1)} ',
        style: TextStyle(
          fontSize: _currentFontSize,
          fontFamily: 'UthmanicHafs',
          height: 1.8,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
        textScaleFactor: 1.0,
        maxLines: null,
      )..layout(maxWidth: _screenWidth - 40);

      final double ayahHeight = textPainter.height;

      if (currentPageHeight + ayahHeight > _availablePageHeight) {
        pageBreaks.add(i); // Add new page break
        currentPageHeight =
            ayahHeight; // Start new page with current ayah's height
      } else {
        currentPageHeight += ayahHeight;
      }
    }

    // Ensure the last page break accounts for all ayahs
    if (pageBreaks.last != ayahs.length) {
      pageBreaks.add(ayahs.length);
    }
    // Handle cases where a surah might be empty or very short
    if (pageBreaks.isEmpty) {
      pageBreaks.add(0);
      pageBreaks.add(0); // At least two breaks for a single "page"
    } else if (pageBreaks.length == 1) {
      if (ayahs.isNotEmpty) {
        pageBreaks.add(ayahs.length);
      } else {
        pageBreaks.add(0);
      }
    }
    return pageBreaks;
  }

  int _getSurahPageCount(String surahName) {
    if (_surahPageBreaks.containsKey(surahName)) {
      // The number of pages is breaks.length - 1 because breaks mark the start of each page
      return _surahPageBreaks[surahName]!.length - 1;
    }
    return 1; // Default to 1 page if no breaks found (shouldn't happen with proper loading)
  }

  int _getGlobalPageIndexForAyah(String surahName, int ayahIndex) {
    int pageOffset = 0;
    for (var surahData in allSurahsData) {
      final String currentSurahIterationName = surahData['name'];
      if (currentSurahIterationName == surahName) {
        if (_surahPageBreaks.containsKey(currentSurahIterationName)) {
          final List<int> pageBreaks =
              _surahPageBreaks[currentSurahIterationName]!;
          for (int i = 0; i < pageBreaks.length - 1; i++) {
            if (ayahIndex >= pageBreaks[i] && ayahIndex < pageBreaks[i + 1]) {
              return pageOffset + i;
            }
          }
          // If ayahIndex is the very last ayah and it's the last page
          if (ayahIndex == pageBreaks.last && pageBreaks.length > 1) {
            return pageOffset + pageBreaks.length - 2; // Last page index
          }
        }
        return pageOffset; // Return first page of surah if ayah not found or no breaks
      }
      pageOffset += _getSurahPageCount(currentSurahIterationName);
    }
    return 0; // Default to first page of the whole Quran
  }

  int _getGlobalPageIndexForLastPageOfSurah(String surahName) {
    int pageOffset = 0;
    for (var surahData in allSurahsData) {
      final String currentSurahIterationName = surahData['name'];
      if (currentSurahIterationName == surahName) {
        if (_surahPageBreaks.containsKey(currentSurahIterationName)) {
          final int surahPageCount = _getSurahPageCount(
            currentSurahIterationName,
          );
          if (surahPageCount > 0) {
            return pageOffset + surahPageCount - 1; // Last page of this surah
          }
        }
        return pageOffset; // Return first page of surah if no pages
      }
      pageOffset += _getSurahPageCount(currentSurahIterationName);
    }
    return 0; // Default to first page of the whole Quran
  }

  List<QuranPage>? get currentSurahPages {
    final surahData = allSurahsData.firstWhere(
      (s) => s['name'] == widget.surahName,
      orElse: () => {},
    );

    final int surahNumber = surahData['number'];
    return widget.quranPages
        ?.where((page) => page.sura == surahNumber)
        .toList();
  }

  Future<void> _loadInitialGlobalData() async {
    try {
      final String surahListJson = await rootBundle.loadString(
        'assets/json/surahs.json',
      );
      final List<dynamic> surahListData = json.decode(surahListJson);
      allSurahsData =
          surahListData.map((s) => s as Map<String, dynamic>).toList();

      // Preload some initial surahs for smoother experience
      final List<String> surahsToPreload = ["الفاتحة", "البقرة"];
      for (String surahName in surahsToPreload) {
        if (!_loadedSurahContents.containsKey(surahName)) {
          await _fetchSurahContentAndCalculateBreaks(surahName);
        }
      }

      currentSurahName = widget.surahName;
      final surahData = allSurahsData.firstWhere(
        (s) => s['name'] == currentSurahName,
      );
      currentSurahNumber = surahData['number'];
      currentAyahCount = surahData['ayahCount'];

      if (!_loadedSurahContents.containsKey(currentSurahName!)) {
        await _fetchSurahContentAndCalculateBreaks(currentSurahName!);
      }

      _currentGlobalPageIndex = _getGlobalPageIndexForAyah(
        widget.surahName,
        widget.initialAyahIndex ?? 0,
      );
      _previousGlobalPageIndex = _currentGlobalPageIndex; // Initialize previous
      _lastVisitedGlobalPageIndexPerSurah[currentSurahName!] =
          _currentGlobalPageIndex;

      // if (_pageController.hasClients) {
      //   _pageController.jumpToPage(_currentGlobalPageIndex);
      // } else {
      //   _pageController = PageController(initialPage: _currentGlobalPageIndex);
      // }

      // ✅ بعد
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentGlobalPageIndex);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading initial data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSurahContentAndCalculateBreaks(String surahName) async {
    if (_loadedSurahContents.containsKey(surahName)) return;

    // ✅ أضف ده: لو الأبعاد لسه مش جاهزة، استنى
    if (_screenWidth == 0 || _screenHeight == 0) {
      debugPrint('⚠️ Screen dimensions not ready, skipping $surahName');
      return;
    }

    try {
      final String? fileName = surahFileNames[surahName];
      if (fileName == null) {
        errorMessage = 'محتوى سورة "$surahName" غير متوفر.';
        return;
      }

      final String jsonString = await rootBundle.loadString(
        'assets/json/tafseer/$fileName',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      List<Map<String, dynamic>> ayahs = List<Map<String, dynamic>>.from(
        data['ayahs'],
      );

      _loadedSurahContents[surahName] = ayahs;

      // ✅ Guard: only use quranPages if they are loaded
      if (widget.quranPages != null && widget.quranPages!.isNotEmpty) {
        _surahPageBreaks[surahName] = _calculatePageBreaksFromQuranPages(
          ayahs,
          data['number'],
        );
      } else {
        // fallback if metadata not ready yet
        _surahPageBreaks[surahName] = _calculatePageBreaksByLength(
          ayahs,
          surahName,
        );
      }

      if (mounted) setState(() {});
    } catch (e) {
      errorMessage = 'فشل تحميل محتوى سورة "$surahName": $e';
    }
  }

  String convertToArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join('');
  }

  void showOptionsBottomSheet(
    BuildContext context,
    int index,
    Map<String, dynamic> ayah,
  ) {
    if (currentSurahName == null) return;

    final ayahId = '$currentSurahName\_$index';
    final isBookmarked = bookmarkProvider.isBookmarked(ayahId);
    final isTafsirShown = selectedAyahIndex == index;

    showModalBottomSheet(
      context: context,
      // Android 15 edge-to-edge: keep the sheet clear of the system nav bar.
      useSafeArea: true,
      builder: (BuildContext ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                  color:  isBookmarked ? Colors.grey : MyColors.deepBlue,
                ),
                title: Text(isBookmarked ? 'إزالة العلامة' : 'إضافة علامة'),
                onTap: () {
                  final bookmark = Bookmark(
                    id: ayahId,
                    surahName: currentSurahName!,
                    ayahIndex: index,
                    snippet: ayah['text'],
                    createdAt: DateTime.now(),
                  );

                  if (isBookmarked) {
                    bookmarkProvider.removeBookmark(bookmark.id);
                  } else {
                    bookmarkProvider.addBookmark(bookmark);
                  }

                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              ListTile(
                leading: Icon(
                  isTafsirShown ? Icons.visibility_off : Icons.menu_book,
                  color: isTafsirShown ? Colors.grey : MyColors.deepBlue,
                ),
                title: Text(isTafsirShown ? 'إخفاء التفسير' : 'قراءة التفسير'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedAyahIndex = isTafsirShown ? null : index;
                  });

                  if (!isTafsirShown) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.headphones, color: MyColors.deepBlue),
                title: const Text('استماع تفسير القرآن'),
                onTap: () async {
                  Navigator.pop(context);

                  setState(() {
                    _showAudioPlayer = true;
                    _showBars = true;
                    _currentPlayingAyahIndex = index; // ← احفظ رقم الآية
                  });

                  widget.setParentBarsVisibility?.call(true);

                  // ✅ مرر اسم السورة ورقم الآية للـ helper
                  final url = _resolveAudioUrl(currentSurahName!, index);
                  if (url != null) {
                    await _loadAudioForSurah(url);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('لا يوجد تسجيل لهذه الآية')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final fontSize = themeProvider.fontSize;

    final bgColor = isDarkMode ? MyColors.blackShade : const Color(0xFFF5F5DC);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Recalculate dimensions and page breaks if font size changes or screen dimensions are not set
    // if (_screenWidth == 0.0 ||
    //     _screenHeight == 0.0 ||
    //     fontSize != _currentFontSize) {
    //   _screenWidth = MediaQuery.of(context).size.width;
    //   _screenHeight = MediaQuery.of(context).size.height;
    //   _currentFontSize = fontSize;
    //   _calculateAvailablePageHeight();
    //   if (!isLoading) {
    //     _recalculatePageBreaksForAllLoadedSurahs();
    //   }
    // }

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty && !isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: MyColors.deepBlue),
          ),
        ),
      );
    }

    int totalPages = 0;
    for (var surah in allSurahsData) {
      totalPages += _getSurahPageCount(surah['name']);
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: bgColor,

        body: GestureDetector(
          // onTap: () {
          //   setState(() {
          //     _showBars = !_showBars;
          //     if (!_showBars) {
          //       _showAudioPlayer = false;
          //     }
          //   });
          //   widget.setParentBarsVisibility?.call(_showBars);
          // },

          onTap: () {
            setState(() {
              _showBars = !_showBars;
            });

            widget.setParentBarsVisibility?.call(_showBars);
          },

          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (pageIndex) async {
                  if (_isPageChanging) return;
                  _isPageChanging = true;
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }

                  try {
                    // Store the previous global page index before updating
                    _previousGlobalPageIndex = _currentGlobalPageIndex;
                    _currentGlobalPageIndex =
                        pageIndex; // Always update current global page index

                    int currentSurahOffset = 0;
                    String newSurahName = '';
                    Map<String, dynamic>? newSurahData;

                    for (var i = 0; i < allSurahsData.length; i++) {
                      final surah = allSurahsData[i];
                      final String tempSurahName = surah['name'];
                      final int surahPageCount = _getSurahPageCount(
                        tempSurahName,
                      );

                      if (pageIndex >= currentSurahOffset &&
                          pageIndex < currentSurahOffset + surahPageCount) {
                        newSurahName = tempSurahName;
                        newSurahData = surah;
                        break;
                      }
                      currentSurahOffset += surahPageCount;
                    }

                    if (newSurahName != currentSurahName) {
                      await _fetchSurahContentAndCalculateBreaks(newSurahName);

                      int targetPage;
                      if (pageIndex < _previousGlobalPageIndex) {
                        // Navigating backward to a new surah: Go to the last page of the previous surah
                        targetPage = _getGlobalPageIndexForLastPageOfSurah(
                          newSurahName,
                        );
                      } else {
                        // Navigating forward to a new surah: Go to the first page of the new surah
                        targetPage = _getGlobalPageIndexForAyah(
                          newSurahName,
                          0,
                        );
                      }

                      setState(() {
                        currentSurahName = newSurahName;
                        currentSurahNumber = newSurahData!['number'];
                        currentAyahCount = newSurahData['ayahCount'];
                        selectedAyahIndex = null;
                        errorMessage = '';
                        _showBars = true;
                        //_showAudioPlayer = false;
                        widget.setParentBarsVisibility?.call(true);
                      });

                      // Only jump if the target page is different from the current page
                      if (_pageController.hasClients &&
                          _pageController.page!.round() != targetPage) {
                        _pageController.jumpToPage(targetPage);
                        _currentGlobalPageIndex =
                            targetPage; // Update current index after jump
                      }
                    }

                    // Always update the last visited page for the *current* surah
                    // This is done after potential jumpToPage to ensure it reflects the final displayed page
                    _lastVisitedGlobalPageIndexPerSurah[currentSurahName!] =
                        _currentGlobalPageIndex;
                  } finally {
                    _isPageChanging = false;
                  }
                },
                itemBuilder: (context, pageIndex) {
                  int currentSurahOffset = 0;
                  String currentPageSurahName = '';
                  int localPageIndex = 0;

                  for (var surah in allSurahsData) {
                    final String tempSurahName = surah['name'];
                    final int surahPageCount = _getSurahPageCount(
                      tempSurahName,
                    );

                    if (pageIndex >= currentSurahOffset &&
                        pageIndex < currentSurahOffset + surahPageCount) {
                      currentPageSurahName = tempSurahName;
                      localPageIndex = pageIndex - currentSurahOffset;
                      break;
                    }
                    currentSurahOffset += surahPageCount;
                  }

                  if (!_loadedSurahContents.containsKey(currentPageSurahName) ||
                      !_surahPageBreaks.containsKey(currentPageSurahName)) {
                    // Fallback for cases where content might not be immediately available
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<Map<String, dynamic>> surahContent =
                      _loadedSurahContents[currentPageSurahName]!;
                  final List<int> pageBreaks =
                      _surahPageBreaks[currentPageSurahName]!;

                  if (localPageIndex < 0 ||
                      localPageIndex >= pageBreaks.length - 1) {
                    return Center(
                      child: Text(
                        'خطأ في حساب الصفحة للسورة ${currentPageSurahName} (الصفحة ${localPageIndex + 1}).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: MyColors.deepBlue),
                      ),
                    );
                  }

                  final int startAyahIndex = pageBreaks[localPageIndex];
                  final int endAyahIndex = pageBreaks[localPageIndex + 1];

                  if (startAyahIndex < 0 ||
                      endAyahIndex > surahContent.length ||
                      startAyahIndex > endAyahIndex) {
                    return Center(
                      child: Text(
                        'خطأ في جلب الآيات للصفحة ${localPageIndex + 1} من سورة ${currentPageSurahName}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: MyColors.deepBlue),
                      ),
                    );
                  }

                  List<Map<String, dynamic>> pageAyahs = surahContent.sublist(
                    startAyahIndex,
                    endAyahIndex,
                  );
                  int baseAyahIndexForPage = startAyahIndex;

                  // final bool showFrame = (currentPageSurahName == "الفاتحة" &&
                  //         localPageIndex == 0) ||
                  //     (currentPageSurahName == "البقرة" &&
                  //         localPageIndex == 0) ||
                  //     (currentPageSurahName != "الفاتحة" &&
                  //         currentPageSurahName != "التوبة" &&
                  //         localPageIndex == 0);

                  final bool showFrame = localPageIndex == 0;

                  // final bool enableScrolling =
                  //     selectedAyahIndex != null || fontSize > 24.0;

                  /*final locationText = _buildCurrentQuranLocationText(
                      currentSurahNumber!, pageAyahs.first['number']);*/
                  final firstHizbAyahInPage = pageAyahs.firstWhereOrNull(
                    (ayah) =>
                        _getHizbIndexForAyah(
                          currentSurahNumber!,
                          ayah['number'],
                        ) !=
                        null,
                  );
                  final currentJuz = _getJuzIndexForAyah(
                    currentSurahNumber!,
                    pageAyahs.first['number'],
                  );
                  final locationText = (firstHizbAyahInPage != null)
                      ? _buildCurrentQuranLocationText(
                          currentSurahNumber!,
                          firstHizbAyahInPage['number'],
                        )
                      : '';

                  return Center(
                    child: SingleChildScrollView(
                      controller: _scrollController,

                      // physics: enableScrolling
                      //     ? const AlwaysScrollableScrollPhysics()
                      //     : const NeverScrollableScrollPhysics(),

                      physics: const AlwaysScrollableScrollPhysics(),

                      padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          children: [
                            if (showFrame) ...[
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Image.asset(
                                  //   'assets/frames/surah_frame.png',
                                  //   width: double.infinity,
                                  //   height: 80,
                                  //   fit: BoxFit.fill,
                                  // ),

                                  Image.asset(
                                    'assets/frames/surah_frame.png',
                                    width: double.infinity,
                                    height: 80,
                                    fit: BoxFit.fill,

                                    color: isDarkMode
                                        ? const Color(0xFFC49A3A)
                                        : null,

                                    colorBlendMode: BlendMode.modulate,
                                  ),

                                  Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 25),
                                        child: Text(
                                          'آياتها: ${convertToArabicNumber(currentAyahCount ?? 0)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child:

                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'سورة ${currentSurahName ?? ''}',
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                          ),

                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 25),
                                        child: Text(
                                          'ترتيبها: ${convertToArabicNumber(currentSurahNumber ?? 0)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (currentPageSurahName != "التوبة")
                                Text(
                                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 16),
                            ],
                            if (pageAyahs.isNotEmpty)
                              if (currentJuz != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 6.0),
                                  color: bgColor.withOpacity(0.95),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'الجزء ${currentJuz}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: textColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'سورة ${currentSurahName ?? ''}',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: textColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            if (locationText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  locationText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            buildRichText(
                              pageAyahs,
                              baseAyahIndexForPage,
                              fontSize,
                              textColor,
                              currentPageSurahName,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    'ص ${pageIndex + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedAyahIndex != null &&
                                selectedAyahIndex! >= baseAyahIndexForPage &&
                                selectedAyahIndex! <
                                    baseAyahIndexForPage + pageAyahs.length &&
                                _loadedSurahContents.containsKey(
                                  currentPageSurahName,
                                ) &&
                                selectedAyahIndex! <
                                    _loadedSurahContents[currentPageSurahName]!
                                        .length) ...[
                              const SizedBox(height: 24),
                              Text(
                                'التفسير:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _loadedSurahContents[currentPageSurahName]![
                                    selectedAyahIndex!]['tafseer'],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  height: 1.6,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              /*if (_showBars)
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'سورة ${currentSurahName ?? ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),*/

              //if (_showBars && _showAudioPlayer)
              if (_showAudioPlayer)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, -2))
                      ],
                    ),

                    // child: Column(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         IconButton(
                    //           icon: Icon(Icons.replay_10,
                    //               size: 36, color: textColor),
                    //           onPressed: () => _audioSeekBy(-10),
                    //         ),
                    //         if (_audioIsLoading)
                    //           const SizedBox(
                    //             width: 48,
                    //             height: 48,
                    //             child: Padding(
                    //               padding: EdgeInsets.all(12),
                    //               child: CircularProgressIndicator(
                    //                   strokeWidth: 2.5, color: MyColors.deepBlue),
                    //             ),
                    //           )
                    //         else
                    //           IconButton(
                    //             icon: Icon(
                    //               _audioIsPlaying
                    //                   ? Icons.pause_circle_filled
                    //                   : Icons.play_circle_filled,
                    //               size: 48,
                    //               color: MyColors.deepBlue,
                    //             ),
                    //             onPressed: _toggleAudio,
                    //           ),
                    //         IconButton(
                    //           icon: Icon(Icons.forward_10,
                    //               size: 36, color: textColor),
                    //           onPressed: () => _audioSeekBy(10),
                    //         ),
                    //       ],
                    //     ),
                    //     const SizedBox(height: 4),
                    //     SliderTheme(
                    //       data: SliderTheme.of(context).copyWith(
                    //         trackHeight: 3,
                    //         thumbShape: const RoundSliderThumbShape(
                    //             enabledThumbRadius: 6),
                    //         activeTrackColor: MyColors.deepBlue,
                    //         inactiveTrackColor:
                    //             isDarkMode ? Colors.white24 : Colors.black12,
                    //         thumbColor: MyColors.deepBlue,
                    //         overlayShape: const RoundSliderOverlayShape(
                    //             overlayRadius: 12),
                    //       ),
                    //       child: Slider(
                    //         min: 0,
                    //         max: _audioDuration.inMilliseconds
                    //             .toDouble()
                    //             .clamp(1.0, double.infinity),
                    //         value: _audioPosition.inMilliseconds
                    //             .toDouble()
                    //             .clamp(
                    //                 0.0,
                    //                 _audioDuration.inMilliseconds
                    //                     .toDouble()
                    //                     .clamp(1.0, double.infinity)),
                    //         onChanged: (v) => _audioPlayer
                    //             ?.seek(Duration(milliseconds: v.toInt())),
                    //       ),
                    //     ),
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 16),
                    //       child: Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //         children: [
                    //           Text(_fmtAudio(_audioPosition),
                    //               style: TextStyle(
                    //                   fontSize: 12, color: textColor)),
                    //           Text(_fmtAudio(_audioDuration),
                    //               style: TextStyle(
                    //                   fontSize: 12, color: textColor)),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // ✅ الصف كله: زرار X + أزرار التحكم
                        Row(
                          children: [

                            // ✅ زرار الإغلاق يمين
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 26,
                              ),
                              onPressed: () async {
                                await _audioPlayer?.stop();

                                setState(() {
                                  _showAudioPlayer = false;
                                  _audioIsPlaying = false;
                                  _audioPosition = Duration.zero;
                                });
                              },
                            ),

                            // ✅ الأزرار في النص
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.forward_10,
                                      size: 36,
                                      color: textColor,
                                    ),
                                    onPressed: () => _audioSeekBy(-10),
                                  ),

                                  if (_audioIsLoading)
                                    const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: MyColors.deepBlue,
                                        ),
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: Icon(
                                        _audioIsPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        size: 48,
                                        color: MyColors.deepBlue,
                                      ),
                                      onPressed: _toggleAudio,
                                    ),

                                  IconButton(
                                    icon: Icon(
                                      Icons.replay_10,
                                      size: 36,
                                      color: textColor,
                                    ),
                                    onPressed: () => _audioSeekBy(10),
                                  ),
                                ],
                              ),
                            ),

                            // ✅ Spacer علشان الأزرار تفضل متوسطة
                           // const SizedBox(width: 48),

                            // speed
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: MyColors.darkGrey,
                                size: 26,
                              ),
                              onPressed: () {
                                _showSpeedOptions(context);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            activeTrackColor: MyColors.deepBlue,
                            inactiveTrackColor:
                            isDarkMode ? Colors.white24 : Colors.black12,
                            thumbColor: MyColors.deepBlue,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: _audioDuration.inMilliseconds
                                .toDouble()
                                .clamp(1.0, double.infinity),
                            value: _audioPosition.inMilliseconds
                                .toDouble()
                                .clamp(
                              0.0,
                              _audioDuration.inMilliseconds
                                  .toDouble()
                                  .clamp(1.0, double.infinity),
                            ),
                            onChanged: (v) => _audioPlayer
                                ?.seek(Duration(milliseconds: v.toInt())),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmtAudio(_audioPosition),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _fmtAudio(_audioDuration),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Widget buildRichText(
    List<Map<String, dynamic>> pageAyahs,
    int baseAyahIndex,
    double fontSize,
    Color textColor,
    String currentDisplayedSurahName,
  ) {
    final int safeSurahNumber = currentSurahNumber ?? 0;
    return RichText(
      textAlign: TextAlign.justify, // علشان يتمدد للنهاية
      textDirection: TextDirection.rtl,

      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'UthmanicHafs',
          height: 1.8,
          color: textColor,
        ),
        children: pageAyahs.asMap().entries.map((entry) {
        final indexInPage = entry.key;
        final ayahIdx = baseAyahIndex + indexInPage;
        final ayah = entry.value;
        final ayahId = '${currentDisplayedSurahName}_$ayahIdx';
        final bool ayahIsBookmarked = bookmarkProvider.isBookmarked(ayahId);
        final bool ayahIsSelected = selectedAyahIndex == ayahIdx;
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

         
          /*return TextSpan(
            children: [
              TextSpan(
                text: ayah['text'],
                style: TextStyle(
                  backgroundColor:
                      isSelected ? Colors.yellow.shade200 : Colors.transparent,
                ),
                recognizer: LongPressGestureRecognizer()
                  ..onLongPress = () {
                    showOptionsBottomSheet(context, globalIndex, ayah);
                  },
              ),
              if (currentSurahNumber != 1 && _getHizbIndexForAyah(currentSurahNumber!, ayah['number']) != null)
                WidgetSpan(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.star, size: 16, color: Colors.teal),
                  ),
                ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAyahIndex = isSelected ? null : globalIndex;
                    });
                    if (!isSelected) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? Colors.red.shade200
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '۝${convertToArabicNumber(globalIndex + 1)}',
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ),
                ),
              ),
              const TextSpan(text: ' '), // مسافة بعد الرقم
            ],
          );*/

/*
          return TextSpan(
            children: [
              // ✅ ماركر التقسيم
              if (_getHizbIndexForAyah(currentSurahNumber!, ayah['number']) !=
                      null &&
                  ayah['number'] != 1)
                WidgetSpan(
                  child: Transform.translate(
                    offset: const Offset(0, 4),
                    // نزليها 4 بكسل تحت، عدلي الرقم حسب الحاجة
                    child: Text(
                      '۞ ',
                      //_buildCurrentQuranLocationText(currentSurahNumber!, ayah['number']),
                      style: TextStyle(fontSize: fontSize, color: Colors.red),
                    ),
                  ),
                ),

              // ✅ نص الآية
              TextSpan(
                text: ' ${ayah['text']}',
                style: TextStyle(
                  backgroundColor:
                      isSelected ? Colors.yellow.shade200 : Colors.transparent,
                ),
                recognizer: LongPressGestureRecognizer()
                  ..onLongPress = () {
                    showOptionsBottomSheet(context, globalIndex, ayah);
                  },
              ),

              if (_getSajdaIndexForAyah(currentSurahNumber!, ayah['number']) !=
                  null)
                WidgetSpan(
                  child: Transform.translate(
                    offset: const Offset(0, 4),
                    // نزليها 4 بكسل تحت، عدلي الرقم حسب الحاجة
                    child: Text(
                      ' ۩',
                      style: TextStyle(fontSize: fontSize, color: Colors.red),
                    ),
                  ),
                ),

              // ✅ رقم الآية
              // TextSpan(
              //   text: ' ۝${convertToArabicNumber(globalIndex + 1)} ',
              //   style: TextStyle(
              //     color: Colors.red,
              //     backgroundColor:
              //         isBookmarked ? Colors.red.shade200 : Colors.transparent,
              //   ),
              //   recognizer: TapGestureRecognizer()
              //     ..onTap = () {
              //       setState(() {
              //         selectedAyahIndex = isSelected ? null : globalIndex;
              //       });
              //       if (!isSelected) {
              //         Future.delayed(const Duration(milliseconds: 300), () {
              //           _scrollController.animateTo(
              //             _scrollController.position.maxScrollExtent,
              //             duration: const Duration(milliseconds: 500),
              //             curve: Curves.easeOut,
              //           );
              //         });
              //       }
              //     },
              // ),

              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAyahIndex = isSelected ? null : globalIndex;
                    });
                    if (!isSelected) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        );
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor:
                    isBookmarked ? Colors.red.shade200 : Colors.transparent,
                    child: Text(
                      '۝${convertToArabicNumber(globalIndex + 1)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 19,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),

            ],
          );
          */

          return TextSpan(
          children: [

            if (_getHizbIndexForAyah(safeSurahNumber, ayah['number']) != null)
              TextSpan(
                text: ' ۞ ',
                style: TextStyle(fontSize: fontSize, color: Colors.red),
              ),

            TextSpan(
              text: ' ${ayah['text']} ',
              style: TextStyle(
                backgroundColor: ayahIsSelected
                    ? isDarkMode
                    ? Color(0xFFC49A3A)
                    : Colors.yellow.shade200
                    : Colors.transparent,

              ),
              recognizer: LongPressGestureRecognizer()
                ..onLongPress = () {
                  showOptionsBottomSheet(context, ayahIdx, ayah);
                },
            ),

            if (_getSajdaIndexForAyah(safeSurahNumber, ayah['number']) != null)
              const TextSpan(
                text: '۩ ',
                style: TextStyle(color: Colors.red),
              ),

            TextSpan(
              text: '۝${convertToArabicNumber(ayahIdx + 1)} ',
              style: TextStyle(
                color: ayahIsBookmarked ? const Color(0xFFC4861B) : Colors.red,
                fontSize: 19,
                height: 1,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    selectedAyahIndex =
                        (selectedAyahIndex == ayahIdx) ? null : ayahIdx;
                  });
                },
            ),

          ],
        );
        }).toList(),
      ),
    );
  }
}