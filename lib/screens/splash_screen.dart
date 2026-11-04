import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quraan_tafseer/screens/main_navigation_screen.dart';

/// Animated splash:
///  • night-sky gradient with twinkling stars and rising golden particles
///  • slowly counter-rotating Islamic 8-point star patterns (the same star as the logo)
///  • the logo "draws" its golden ring, then pops in with a soft glow and ripples
///  • app title with a gold shimmer + a verse about tadabbur (Sad: 29)
///
/// Tap anywhere to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 3400);
  static const _totalDuration = Duration(milliseconds: 4600);
  static const _loopDuration = Duration(seconds: 14);

  static const _gold = Color(0xFFD4AF37);
  static const _lightGold = Color(0xFFF6E3A1);

  late final AnimationController _intro;
  late final AnimationController _loop;
  Timer? _timer;
  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: _introDuration);
    _loop = AnimationController(vsync: this, duration: _loopDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Make sure the logo is decoded before the animation starts (no pop-in).
    precacheImage(const AssetImage('assets/images/splash2.png'), context)
        .whenComplete(_start);
  }

  void _start() {
    if (!mounted) return;
    _intro.forward();
    _loop.repeat();
    _timer = Timer(_totalDuration, _navigate);
  }

  void _navigate() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const MainNavigationScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// Progress of [t] inside the window [a]..[b], shaped by [curve].
  static double _iv(double t, double a, double b, [Curve curve = Curves.easeOut]) {
    return curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF050B1C),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigate,
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _loop]),
            builder: (context, _) => _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final t = _intro.value; // 0..1 over the intro
    final loop = _loop.value; // 0..1 repeating

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final logoSize = math.min(math.min(w * 0.5, h * 0.28), 220.0);
        final center = Offset(w / 2, h * 0.38);

        // Staggered timeline.
        final ringProgress = _iv(t, 0.05, 0.50, Curves.easeInOutCubic);
        final logoScale = _iv(t, 0.18, 0.62, Curves.elasticOut);
        final logoOpacity = _iv(t, 0.18, 0.40);
        final titleT = _iv(t, 0.52, 0.80, Curves.easeOutCubic);
        final dividerT = _iv(t, 0.62, 0.86, Curves.easeOutCubic);
        final verseT = _iv(t, 0.74, 1.0);

        // Gentle floating of the logo.
        final float = math.sin(loop * 2 * math.pi * 5) * 4;
        final shimmer = (loop * 5) % 1.0;
        final shimmerCenter = -0.2 + 1.4 * shimmer;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background + all painted effects.
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.24),
                  radius: 1.1,
                  colors: [
                    Color(0xFF1F3A63),
                    Color(0xFF0F1E3C),
                    Color(0xFF050B1C),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _SplashPainter(
                  intro: t,
                  loop: loop,
                  center: center,
                  logoRadius: logoSize / 2,
                  ringProgress: ringProgress,
                ),
              ),
            ),

            // Logo.
            Positioned(
              left: center.dx - logoSize / 2,
              top: center.dy - logoSize / 2 + float,
              width: logoSize,
              height: logoSize,
              child: Opacity(
                opacity: logoOpacity,
                child: Transform.scale(
                  scale: 0.4 + 0.6 * logoScale,
                  child: Image.asset(
                    'assets/images/splash2.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Title, divider and verse.
            Positioned(
              top: center.dy + logoSize / 2 + 36,
              left: 24,
              right: 24,
              bottom: 56,
              child: Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: titleT,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - titleT)),
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (rect) => LinearGradient(
                                colors: const [
                                  _gold,
                                  _gold,
                                  Colors.white,
                                  _gold,
                                  _gold,
                                ],
                                stops: [
                                  0.0,
                                  (shimmerCenter - 0.15).clamp(0.0, 1.0),
                                  shimmerCenter.clamp(0.0, 1.0),
                                  (shimmerCenter + 0.15).clamp(0.0, 1.0),
                                  1.0,
                                ],
                              ).createShader(rect),
                              child: const Text(
                                'التفسير السعيد',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Ornament(progress: dividerT),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: verseT,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - verseT)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    // w can be 0 on the very first (warm-up) frame,
                                    // so never let this go negative.
                                    maxWidth: math.max(0.0, math.min(w - 48, 420.0)),
                                  ),
                                  child: Text(
                                    '﴿ كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ مُبَارَكٌ لِّيَدَّبَّرُوا آيَاتِهِ وَلِيَتَذَكَّرَ أُولُو الْأَلْبَابِ ﴾',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 20,
                                      height: 1.9,
                                      color: _lightGold.withOpacity(0.92),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'سورة ص  ·  ٢٩',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.5),
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
              ),
            ),

            // Thin gold progress line at the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 28 + MediaQuery.of(context).padding.bottom,
              child: Center(
                child: Opacity(
                  opacity: _iv(t, 0.05, 0.2) * 0.9,
                  child: Container(
                    width: 120,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: t.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gold, _lightGold],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ── ─◆─ ──  thin ornament that grows from the middle.
class _Ornament extends StatelessWidget {
  final double progress;
  const _Ornament({required this.progress});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    final lineW = 70.0 * progress;
    return Opacity(
      opacity: progress,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: lineW,
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold.withOpacity(0), gold],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Transform.rotate(
            angle: math.pi / 4 * progress,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: lineW,
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold, gold.withOpacity(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Star {
  final double x, y, size, phase;
  final int speed;
  const _Star(this.x, this.y, this.size, this.phase, this.speed);
}

class _Particle {
  final double x, size, phase;
  final int rise; // full rises per loop
  final int sway; // sways per loop
  const _Particle(this.x, this.size, this.phase, this.rise, this.sway);
}

class _SplashPainter extends CustomPainter {
  final double intro; // 0..1
  final double loop; // 0..1 repeating (seamless: only integer multiples used)
  final Offset center;
  final double logoRadius;
  final double ringProgress;

  _SplashPainter({
    required this.intro,
    required this.loop,
    required this.center,
    required this.logoRadius,
    required this.ringProgress,
  });

  static const _gold = Color(0xFFD4AF37);
  static const _lightGold = Color(0xFFF6E3A1);
  static const _tau = 2 * math.pi;

  static final List<_Star> _stars = () {
    final r = math.Random(7);
    return List.generate(
      70,
      (_) => _Star(
        r.nextDouble(),
        r.nextDouble(),
        0.6 + r.nextDouble() * 1.4,
        r.nextDouble(),
        1 + r.nextInt(4),
      ),
    );
  }();

  static final List<_Particle> _particles = () {
    final r = math.Random(21);
    return List.generate(
      26,
      (_) => _Particle(
        r.nextDouble(),
        1.0 + r.nextDouble() * 2.2,
        r.nextDouble(),
        1 + r.nextInt(3),
        1 + r.nextInt(3),
      ),
    );
  }();

  static double _iv(double t, double a, double b, [Curve curve = Curves.easeOut]) {
    return curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
  }

  /// Classic 8-point Islamic star = two squares, one rotated by 45°.
  Path _octagram(Offset c, double r, double rotation) {
    final path = Path();
    for (var sq = 0; sq < 2; sq++) {
      for (var i = 0; i < 4; i++) {
        final a = rotation + sq * math.pi / 4 + i * math.pi / 2;
        final x = c.dx + r * math.cos(a);
        final y = c.dy + r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fadeIn = _iv(intro, 0.0, 0.25);

    // 1) Twinkling stars.
    final starPaint = Paint();
    for (final s in _stars) {
      final tw = math.sin((loop * s.speed + s.phase) * _tau);
      final a = (0.25 + 0.75 * tw * tw) * fadeIn;
      starPaint.color = Colors.white.withOpacity((a * 0.8).clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        starPaint,
      );
    }

    // 2) Rotating geometric star pattern (three layers, alternating direction).
    final patternT = _iv(intro, 0.03, 0.55, Curves.easeOutCubic);
    final layers = <List<double>>[
      // radius multiplier, base opacity, rotation direction (+1 / -1)
      [2.0, 0.30, 1.0],
      [2.9, 0.20, -1.0],
      [3.9, 0.13, 1.0],
      [5.1, 0.08, -1.0],
    ];
    final patternPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final l in layers) {
      final r = logoRadius * l[0] * (0.6 + 0.4 * patternT);
      patternPaint.color = _gold.withOpacity(l[1] * patternT);
      // Half a turn per loop: slow, and seamless thanks to the 8-fold symmetry.
      final rot = l[2] * loop * math.pi + math.pi / 8;
      canvas.drawPath(_octagram(center, r, rot), patternPaint);
    }

    // 3) Soft pulsing glow behind the logo.
    final glowT = _iv(intro, 0.15, 0.6);
    final glowR = logoRadius * 2.5 * (1 + 0.06 * math.sin(loop * _tau * 5));
    final glowRect = Rect.fromCircle(center: center, radius: glowR);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _gold.withOpacity(0.38 * glowT),
          _gold.withOpacity(0.0),
        ],
      ).createShader(glowRect);
    canvas.drawCircle(center, glowR, glowPaint);

    // 4) Ripples expanding from the logo.
    final rippleStart = _iv(intro, 0.45, 0.6);
    if (rippleStart > 0) {
      final maxR = size.width * 0.85;
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (var i = 0; i < 3; i++) {
        final p = (loop * 4 + i / 3.0) % 1.0;
        final r = logoRadius * 1.15 + p * maxR;
        final a = math.pow(1 - p, 1.6).toDouble() * 0.28 * rippleStart;
        ripplePaint.color = _lightGold.withOpacity(a.clamp(0.0, 1.0));
        canvas.drawCircle(center, r, ripplePaint);
      }
    }

    // 5) Golden ring that draws itself around the logo.
    if (ringProgress > 0) {
      final ringR = logoRadius * 1.04 + 6;
      final ringRect = Rect.fromCircle(center: center, radius: ringR);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: _tau,
          colors: const [_gold, _lightGold, _gold],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(ringRect);
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        _tau * ringProgress,
        false,
        ringPaint,
      );

      // Little spark that travels at the head of the ring while it draws.
      if (ringProgress < 1.0) {
        final ang = -math.pi / 2 + _tau * ringProgress;
        final head = Offset(
          center.dx + ringR * math.cos(ang),
          center.dy + ringR * math.sin(ang),
        );
        canvas.drawCircle(
          head,
          9,
          Paint()
            ..shader = RadialGradient(
              colors: [Colors.white, _lightGold.withOpacity(0.0)],
            ).createShader(Rect.fromCircle(center: head, radius: 9)),
        );
      }
    }

    // 6) Rising golden particles.
    final particlePaint = Paint();
    for (final p in _particles) {
      final f = (loop * p.rise + p.phase) % 1.0;
      final x = p.x * size.width + math.sin((loop * p.sway + p.phase) * _tau) * 12;
      final y = size.height * (1.05 - f * 1.1);
      final a = math.sin(f * math.pi) * 0.55 * fadeIn;
      particlePaint.color = _lightGold.withOpacity(a.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), p.size, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) => true;
}