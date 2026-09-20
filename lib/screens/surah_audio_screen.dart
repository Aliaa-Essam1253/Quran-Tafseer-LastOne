
import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';
// ONLY just_audio — aliased to avoid AudioPlayer/PlayerState ambiguity
import 'package:just_audio/just_audio.dart' as ja;
import 'package:http/http.dart' as http;


class SurahAudioScreen extends StatefulWidget {
  final String title;
  final String url;

  const SurahAudioScreen({Key? key, required this.title, required this.url})
      : super(key: key);

  @override
  State<SurahAudioScreen> createState() => _SurahAudioScreenState();
}

class _SurahAudioScreenState extends State<SurahAudioScreen> {
  final ja.AudioPlayer _player = ja.AudioPlayer();

  bool _isLoading = true;
  String _errorMessage = '';
  double _playbackRate = 1.0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textColor => _isDark ? Colors.white : Colors.black87;
  Color get _subColor => _isDark ? Colors.white54 : Colors.black45;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  /// Follows HTTP redirects manually and returns the final resolved URL.
  /// archive.org /download/ links redirect to CDN servers like dn721805.ca.archive.org
  /// ExoPlayer on Android does not always follow these redirects reliably.
  Future<String> _resolveRedirect(String originalUrl) async {
    String url = originalUrl;
    try {
      final client = http.Client();
      int hops = 0;
      while (hops < 5) {
        final request = http.Request('HEAD', Uri.parse(url))
          ..followRedirects = false;
        final response = await client.send(request);

        if (response.statusCode >= 300 && response.statusCode < 400) {
          final location = response.headers['location'];
          if (location == null || location.isEmpty) break;
          // Resolve relative URLs against the current URL
          url = Uri.parse(url).resolve(location).toString();
          hops++;
        } else {
          break; // Not a redirect — we have the final URL
        }
      }
      client.close();
      debugPrint('✅ Resolved: $url');
    } catch (e) {
      debugPrint('⚠️ Redirect resolution failed, using original: $e');
    }
    return url;
  }

  Future<void> _loadAudio() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Resolve any archive.org redirects to the final CDN URL first
      final resolvedUrl = await _resolveRedirect(widget.url);
      await _player.setUrl(resolvedUrl);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذّر تحميل الصوت.\n${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlay() async =>
      _player.playing ? await _player.pause() : await _player.play();

  Future<void> _seekBy(int seconds) async {
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;
    final target = pos + Duration(seconds: seconds);
    await _player.seek(target < Duration.zero
        ? Duration.zero
        : target > dur
            ? dur
            : target);
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        backgroundColor: _isDark ? MyColors.darkGreen : MyColors.deepGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MyColors.deepBlue))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildPlayer(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: MyColors.deepBlue, size: 56),
            const SizedBox(height: 16),
            Text(_errorMessage,
                style: TextStyle(color: _textColor, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAudio,
              style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.deepBlue, foregroundColor: Colors.white),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return StreamBuilder<ja.PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final proc = snapshot.data?.processingState;
        final isBuffering = proc == ja.ProcessingState.buffering ||
            proc == ja.ProcessingState.loading;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Art
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isDark
                          ? [MyColors.darkGreen, MyColors.darkGrey]
                          : [MyColors.deepGreen, MyColors.deepGreen.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: MyColors.deepGreen.withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.headphones_rounded,
                      size: 64, color: Colors.white),
                ),
                const SizedBox(height: 28),
                Text(widget.title,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: _textColor),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),

                // Progress slider
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (ctx, posSnap) {
                    final duration = _player.duration ?? Duration.zero;
                    final position = posSnap.data ?? Duration.zero;
                    final maxMs = duration.inMilliseconds
                        .toDouble()
                        .clamp(1.0, double.infinity);
                    final curMs =
                        position.inMilliseconds.toDouble().clamp(0.0, maxMs);

                    return Column(children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16),
                          activeTrackColor: MyColors.deepBlue,
                          inactiveTrackColor: _isDark
                              ? Colors.white24
                              : MyColors.deepGreen.withOpacity(0.2),
                          thumbColor: MyColors.deepBlue,
                          overlayColor: MyColors.deepBlue.withOpacity(0.15),
                        ),
                        child: Slider(
                          min: 0,
                          max: maxMs,
                          value: curMs,
                          onChanged: (v) => _player
                              .seek(Duration(milliseconds: v.toInt())),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(position),
                                style: TextStyle(color: _subColor, fontSize: 12)),
                            Text(_fmt(duration),
                                style: TextStyle(color: _subColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    ]);
                  },
                ),
                const SizedBox(height: 24),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CircleButton(
                        icon: Icons.forward_10_rounded,
                        isDark: _isDark,
                        onTap: isPlaying ? () => _seekBy(10) : null),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MyColors.deepBlue,
                          boxShadow: [
                            BoxShadow(
                                color: MyColors.deepBlue.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2)
                          ],
                        ),
                        child: isBuffering
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _CircleButton(
                        icon: Icons.replay_10_rounded,
                        isDark: _isDark,
                        onTap: isPlaying ? () => _seekBy(-10) : null),
                  ],
                ),
                const SizedBox(height: 32),

                // Speed
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: MyColors.deepBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MyColors.deepBlue.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('السرعة: ',
                          style: TextStyle(
                              color: _textColor,
                              fontSize: 14,
                              fontFamily: 'Cairo')),
                      const SizedBox(width: 8),
                      DropdownButton<double>(
                        value: _playbackRate,
                        underline: const SizedBox(),
                        dropdownColor: Theme.of(context).cardTheme.color,
                        style: const TextStyle(
                            color: MyColors.deepBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 0.75, child: Text('0.75×')),
                          DropdownMenuItem(value: 1.0, child: Text('1×')),
                          DropdownMenuItem(value: 1.25, child: Text('1.25×')),
                          DropdownMenuItem(value: 1.5, child: Text('1.5×')),
                          DropdownMenuItem(value: 2.0, child: Text('2×')),
                        ],
                        onChanged: (v) async {
                          if (v != null) {
                            setState(() => _playbackRate = v);
                            await _player.setSpeed(v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, required this.isDark, this.onTap});

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
          color: active ? MyColors.deepBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: active
                ? MyColors.deepBlue.withOpacity(0.3)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Icon(icon,
            color: active
                ? MyColors.deepBlue
                : (isDark ? Colors.white24 : Colors.black26),
            size: 28),
      ),
    );
  }
}