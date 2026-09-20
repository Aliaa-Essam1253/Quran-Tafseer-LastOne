import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quraan_tafseer/conectivity_service.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/download_storage.dart';
import 'package:quraan_tafseer/models/reciter_model.dart';
import 'package:quraan_tafseer/providers/quran_provider.dart';

/// Project-2 audio player screen. Fully theme-aware — uses MyColors + ThemeProvider.
class SurahPlayerScreen extends StatefulWidget {
  const SurahPlayerScreen({super.key});

  @override
  State<SurahPlayerScreen> createState() => _SurahPlayerScreenState();
}

class _SurahPlayerScreenState extends State<SurahPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();

  String? _loadedSource;
  double? _downloadProgress;
  bool _isDownloaded = false;
  String? _localPath;
  bool _checkingDownload = true;
  int? _lastCheckedReciterId;

  // ── Theme helpers ────────────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => Theme.of(context).colorScheme.background;
  Color get _cardColor => Theme.of(context).cardTheme.color ?? Colors.white;
  Color get _textColor => _isDark ? Colors.white : Colors.black87;
  Color get _subColor => _isDark ? Colors.white54 : Colors.black45;
  Color get _dividerColor => _isDark ? Colors.white12 : Colors.black12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final provider = context.read<QuranProvider>();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _checkDownloadForCurrentReciter(provider, autoPlay: false);
    if (_localPath == null) {
      final url = provider.currentAudio?.audioUrl;
      if (url != null) await _loadFromUrl(url);
    }
  }

  Future<void> _checkDownloadForCurrentReciter(QuranProvider provider,
      {bool autoPlay = false}) async {
    final surahNumber = provider.selectedSurah?.number;
    final reciter = provider.selectedReciter;
    if (surahNumber == null) {
      if (mounted) setState(() => _checkingDownload = false);
      return;
    }
    _lastCheckedReciterId = reciter?.id;
    String? localPath;
    if (reciter != null) {
      localPath = await DownloadStorage.get(surahNumber, reciter.id);
    }
    if (!mounted) return;
    if (localPath != null) {
      setState(() {
        _isDownloaded = true;
        _localPath = localPath;
        _checkingDownload = false;
      });
      await _loadFromFile(localPath);
      if (autoPlay) await _player.play();
    } else {
      setState(() {
        _player.stop();
        _isDownloaded = false;
        _localPath = null;
        _loadedSource = null;
        _checkingDownload = false;
      });
      final url = provider.currentAudio?.audioUrl;
      if (url != null) await _loadFromUrl(url);
    }
  }

  Future<void> _loadFromFile(String path) async {
    if (_loadedSource == path) return;
    try {
      await _player.stop();
      await _player.setFilePath(path);
      _loadedSource = path;
    } catch (e) {
      debugPrint('File load error: $e');
    }
  }

  Future<void> _loadFromUrl(String url) async {
    if (_loadedSource == url) return;
    try {
      await _player.stop();
      await _player.setUrl(url);
      _loadedSource = url;
    } catch (e) {
      debugPrint('URL load error: $e');
    }
  }

  Future<void> _togglePlayPause(String? audioUrl) async {
    final connectivity = context.read<ConnectivityService>();
    if (_localPath != null) {
      if (_loadedSource != _localPath) await _loadFromFile(_localPath!);
      _player.playing ? await _player.pause() : await _player.play();
      return;
    }
    if (!connectivity.isOnline) {
      _showOfflineSnackbar();
      return;
    }
    if (audioUrl == null) return;
    if (_loadedSource != audioUrl) await _loadFromUrl(audioUrl);
    _player.playing ? await _player.pause() : await _player.play();
  }

  Future<void> _seekBackward() async {
    final pos = _player.position;
    final t = pos - const Duration(seconds: 5);
    await _player.seek(t < Duration.zero ? Duration.zero : t);
  }

  Future<void> _seekForward() async {
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;
    final t = pos + const Duration(seconds: 5);
    await _player.seek(t > dur ? dur : t);
  }

  Future<void> _download(String url, QuranProvider provider) async {
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.isOnline) {
      _showOfflineSnackbar();
      return;
    }
    if (_isDownloaded) {
      _showSnackbar('تم الحفظ مسبقاً ✓');
      return;
    }
    final surahNum = provider.selectedSurah?.number ?? 0;
    final reciterId = provider.selectedReciter?.id ?? 0;
    setState(() => _downloadProgress = 0.0);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/surah_${surahNum}_$reciterId.mp3';
      await Dio().download(url, savePath, onReceiveProgress: (rx, total) {
        if (total > 0 && mounted)
          setState(() => _downloadProgress = rx / total);
      });
      await DownloadStorage.save(surahNum, reciterId, savePath);
      if (mounted) {
        setState(() {
          _downloadProgress = null;
          _isDownloaded = true;
          _localPath = savePath;
          _loadedSource = null;
        });
        _showSnackbar('تم الحفظ ✓  يعمل الآن بدون إنترنت');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress = null);
        _showSnackbar('فشل التحميل');
      }
    }
  }

  void _showOfflineSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      backgroundColor: _isDark ? MyColors.darkGrey : Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
      content: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'لا يوجد اتصال بالإنترنت.\nحمّل السورة أولاً للاستماع بدون إنترنت.',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    ));
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: MyColors.deepGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _fmt(Duration? d) {
    if (d == null) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _toArabicNum(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer2<QuranProvider, ConnectivityService>(
      builder: (ctx, provider, connectivity, _) {
        final audioUrl = provider.currentAudio?.audioUrl;
        final isLoadingAudio = provider.audioState == LoadingState.loading;
        final currentReciterId = provider.selectedReciter?.id;

        if (!_checkingDownload && currentReciterId != _lastCheckedReciterId) {
          _lastCheckedReciterId = currentReciterId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _checkingDownload = true;
                _isDownloaded = false;
                _localPath = null;
                _loadedSource = null;
              });
              _checkDownloadForCurrentReciter(provider);
            }
          });
        }

        if (!_isDownloaded &&
            !_checkingDownload &&
            audioUrl != null &&
            _loadedSource == null &&
            !isLoadingAudio) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadFromUrl(audioUrl);
          });
        }

        final canPlay = !_checkingDownload &&
            (_localPath != null ||
                (audioUrl != null && !isLoadingAudio && connectivity.isOnline));

        return Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              _buildAppBar(ctx, provider, connectivity),
              _buildReciterSelector(ctx, provider),
              if (!connectivity.isOnline &&
                  !_isDownloaded &&
                  !_checkingDownload)
                _buildOfflineBanner(),
              Expanded(
                child: _checkingDownload
                    ? Center(
                        child:
                            CircularProgressIndicator(color: MyColors.deepBlue))
                    : _buildPlayerContent(provider.selectedSurah, audioUrl,
                        isLoadingAudio, canPlay, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Offline banner ───────────────────────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: MyColors.deepBlue.withOpacity(0.08),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: MyColors.deepBlue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'أنت غير متصل — السور المحملة فقط متاحة',
              style: TextStyle(color: MyColors.deepBlue, fontSize: 12),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext ctx, QuranProvider provider,
      ConnectivityService connectivity) {
    final surah = provider.selectedSurah;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _isDark ? MyColors.darkBlue : MyColors.deepBlue,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah?.name ?? '',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  if (surah != null)
                    Text(
                      '${_toArabicNum(surah.numberOfAyahs)} آية  ·  '
                      '${surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            // Connectivity dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connectivity.isOnline
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reciter selector ─────────────────────────────────────────────────────────
  Widget _buildReciterSelector(BuildContext ctx, QuranProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _dividerColor)),
      ),
      child: Row(
        children: [
          Text('القارئ:', style: TextStyle(color: _subColor, fontSize: 13)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showReciterSheet(ctx, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: MyColors.deepBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MyColors.deepBlue.withOpacity(0.35)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_rounded,
                        color: MyColors.deepBlue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      provider.selectedReciter?.name ?? 'اختر القارئ',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          color: MyColors.deepBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: MyColors.deepBlue, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Player content ───────────────────────────────────────────────────────────
  Widget _buildPlayerContent(dynamic surah, String? audioUrl,
      bool isLoadingAudio, bool canPlay, QuranProvider provider) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final proc = snapshot.data?.processingState;
        final isBuffering = proc == ProcessingState.buffering ||
            proc == ProcessingState.loading;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              _buildSurahArt(surah),
              const SizedBox(height: 36),
              _buildProgressBar(),
              const SizedBox(height: 28),
              _buildControls(
                isPlaying: isPlaying,
                isBuffering: isBuffering || (isLoadingAudio && !_isDownloaded),
                canPlay: canPlay,
                audioUrl: audioUrl,
              ),
              const SizedBox(height: 28),
              if (audioUrl != null || _isDownloaded)
                _buildDownloadButton(audioUrl, provider),
            ],
          ),
        );
      },
    );
  }

  // ── Surah art card ────────────────────────────────────────────────────────────
  Widget _buildSurahArt(dynamic surah) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: _isDark
              ? [MyColors.darkBlue.withOpacity(0.5), MyColors.darkGrey]
              : [MyColors.deepBlue, MyColors.lightBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MyColors.deepBlue.withOpacity(_isDark ? 0.2 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (surah != null) ...[
            Text(
              surah.name,
              style: const TextStyle(
                fontFamily: 'Amiri',
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 6),
            Text(
              surah.englishName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
            if (_isDownloaded) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_done_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'محفوظ — يعمل بدون إنترنت',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;
        final duration = _player.duration ?? Duration.zero;
        final progress = duration.inMilliseconds == 0
            ? 0.0
            : (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0);

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: MyColors.deepBlue,
                inactiveTrackColor: _isDark
                    ? Colors.white24
                    : MyColors.deepGreen.withOpacity(0.2),
                thumbColor: MyColors.deepBlue,
                overlayColor: MyColors.deepBlue.withOpacity(0.2),
              ),
              child: Slider(
                value: progress,
                onChanged: duration.inMilliseconds > 0
                    ? (v) => _player.seek(Duration(
                        milliseconds: (v * duration.inMilliseconds).round()))
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(duration.inMilliseconds > 0
                        ? duration - position
                        : null),
                    style: TextStyle(color: _subColor, fontSize: 12),
                  ),
                  Text(
                    _fmt(position == Duration.zero ? null : position),
                    style: TextStyle(color: _subColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Playback controls ────────────────────────────────────────────────────────
  Widget _buildControls({
    required bool isPlaying,
    required bool isBuffering,
    required bool canPlay,
    required String? audioUrl,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SkipButton(
          icon: Icons.forward_5_rounded,
          isDark: _isDark,
          onTap: canPlay && isPlaying ? _seekForward : null,
        ),
        const SizedBox(width: 28),
        GestureDetector(
          onTap: canPlay ? () => _togglePlayPause(audioUrl) : null,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canPlay ? MyColors.deepBlue : Colors.grey.shade300,
              boxShadow: canPlay
                  ? [
                      BoxShadow(
                        color: MyColors.deepBlue.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isBuffering
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
          ),
        ),
        const SizedBox(width: 28),
        _SkipButton(
          icon: Icons.replay_5_rounded,
          isDark: _isDark,
          onTap: canPlay && isPlaying ? _seekBackward : null,
        ),
      ],
    );
  }

  // ── Download button ───────────────────────────────────────────────────────────
  Widget _buildDownloadButton(String? audioUrl, QuranProvider provider) {
    final isDownloading = _downloadProgress != null;
    final connectivity = context.read<ConnectivityService>();

    Color bgColor;
    Color borderColor;
    Widget content;

    if (isDownloading) {
      bgColor = MyColors.deepGreen.withOpacity(0.08);
      borderColor = MyColors.deepGreen.withOpacity(0.3);
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              value: _downloadProgress,
              strokeWidth: 2,
              color: MyColors.deepGreen,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'جاري التحميل... ${((_downloadProgress ?? 0) * 100).toInt()}٪',
            style: const TextStyle(color: MyColors.deepGreen, fontSize: 14),
          ),
        ],
      );
    } else if (_isDownloaded) {
      bgColor = MyColors.deepGreen.withOpacity(0.1);
      borderColor = MyColors.deepGreen.withOpacity(0.4);
      content = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done_rounded,
              color: MyColors.deepGreen, size: 20),
          SizedBox(width: 8),
          Text(
            'محفوظ على الجهاز',
            style: TextStyle(
                color: MyColors.deepGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      );
    } else if (!connectivity.isOnline) {
      bgColor = Colors.transparent;
      borderColor = _dividerColor;
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: _subColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'لا يمكن التحميل بدون إنترنت',
            style: TextStyle(color: _subColor, fontSize: 13),
          ),
        ],
      );
    } else {
      bgColor = MyColors.deepBlue.withOpacity(0.08);
      borderColor = MyColors.deepBlue.withOpacity(0.3);
      content = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_rounded, color: MyColors.deepBlue, size: 20),
          SizedBox(width: 8),
          Text(
            'تحميل السورة',
            style: TextStyle(
                color: MyColors.deepBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: (isDownloading || audioUrl == null)
          ? null
          : () => _download(audioUrl, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: content,
      ),
    );
  }

  // ── Reciter bottom sheet ──────────────────────────────────────────────────────
  void _showReciterSheet(BuildContext ctx, QuranProvider provider) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _ReciterSheet(provider: provider, isDark: _isDark),
    );
  }
}

// ── Skip button ───────────────────────────────────────────────────────────────
class _SkipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _SkipButton({required this.icon, this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              active ? MyColors.deepBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: active
                ? MyColors.deepBlue.withOpacity(0.3)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Icon(
          icon,
          color: active
              ? MyColors.deepBlue
              : (isDark ? Colors.white24 : Colors.black26),
          size: 26,
        ),
      ),
    );
  }
}

// ── Reciter sheet ─────────────────────────────────────────────────────────────
class _ReciterSheet extends StatelessWidget {
  final QuranProvider provider;
  final bool isDark;

  const _ReciterSheet({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.mic_rounded,
                    color: MyColors.deepBlue, size: 20),
                const SizedBox(width: 10),
                Text(
                  'اختر القارئ',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.recitersState == LoadingState.loading
                ? const Center(
                    child: CircularProgressIndicator(color: MyColors.deepBlue))
                : provider.reciters.isEmpty
                    ? Center(
                        child: Text(
                          'القراء غير متاحة بدون إنترنت',
                          style: TextStyle(color: subColor, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: sc,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: provider.reciters.length,
                        itemBuilder: (ctx, i) {
                          final r = provider.reciters[i];
                          final sel = provider.selectedReciter?.id == r.id;
                          return _ReciterRow(
                            reciter: r,
                            isSelected: sel,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                            onTap: () {
                              provider.selectReciter(r);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ReciterRow extends StatelessWidget {
  final Reciter reciter;
  final bool isSelected;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _ReciterRow({
    required this.reciter,
    required this.isSelected,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? MyColors.deepBlue.withOpacity(0.08) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? MyColors.deepBlue.withOpacity(0.4)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isSelected
                    ? MyColors.deepBlue
                    : MyColors.deepBlue.withOpacity(0.12),
                child: Icon(
                  Icons.mic_rounded,
                  color: isSelected ? Colors.white : MyColors.deepBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.name,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: isSelected ? MyColors.deepBlue : textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (reciter.style != null)
                      Text(
                        reciter.style!,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
              isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: MyColors.deepBlue, size: 20)
                  : const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
