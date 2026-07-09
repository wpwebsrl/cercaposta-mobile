import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// WpWeb brand logo with the same staggered reveal as the web About dialog:
/// circle pop → arc wipe (left→right) → wordmark rise → tagline fade. The four
/// brand layers live as separate SVGs (assets/logo/) sharing one viewBox
/// (340×470) so they overlay pixel-perfect; a single controller drives them via
/// time intervals that mirror the web's Web Animations API delays/durations.
///
/// One-shot and decorative: it plays fully once on mount (like the web),
/// regardless of prefers-reduced-motion.
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key, this.width = 150});

  final double width;

  /// Full reveal timeline (circle → arc → wordmark → tagline). Exposed so the
  /// About credits can hold their first line until the logo has finished.
  static const Duration animationDuration = Duration(milliseconds: 5700);

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AnimatedLogo.animationDuration,
  )..forward();

  // Brand ink (black) recolored to the light --logo-ink in dark mode, exactly like
  // the web/desktop — so the wordmark/arc stay legible without a white glow behind.
  static const _lightInk = '#231f20';
  static const _lightInkUpper = '#231F20';
  static const _darkInk = '#eaedf0';
  final Map<String, String> _svgRaw = <String, String>{};

  @override
  void initState() {
    super.initState();
    _loadSvgs();
  }

  Future<void> _loadSvgs() async {
    for (final name in const <String>['circle', 'arc', 'wordmark']) {
      try {
        _svgRaw[name] = await rootBundle.loadString('assets/logo/$name.svg');
      } on Object {
        /* leave unset → _layer falls back to SvgPicture.asset for this layer */
      }
    }
    if (mounted) setState(() {});
  }

  // Each layer's [delay, delay+duration] window as a fraction of 5700ms.
  static const _circle = Interval(0.053, 0.404, curve: Curves.easeOutBack);
  static const _circleFade = Interval(0.053, 0.210, curve: Curves.easeOut);
  static const _arc = Interval(0.263, 0.570, curve: Curves.easeInOut);
  static const _wordmark = Interval(0.561, 0.772, curve: Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const aspect = 340 / 470;
    final w = widget.width;
    final h = w / aspect;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Build each SvgPicture once; AnimatedBuilder only rewraps them (the SVG
    // raster is cached, so the 69KB wordmark isn't re-decoded each frame).
    final circle = _layer('circle', w, h, dark);
    final arc = _layer('arc', w, h, dark);
    // The wordmark SVG already includes the "Technology Solutions" tagline, so
    // there's no separate tagline layer (adding one double-printed the text).
    final wordmark = _layer('wordmark', w, h, dark);

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final circleScale = 0.12 + 0.88 * _circle.transform(v);
          final wordT = _wordmark.transform(v);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Opacity(
                opacity: _circleFade.transform(v),
                child: Transform.scale(
                  scale: circleScale,
                  // circle bbox center ≈ (170, 223) in the 340×470 viewBox.
                  alignment: const Alignment(0, -0.051),
                  child: circle,
                ),
              ),
              ClipRect(clipper: _WipeClipper(_arc.transform(v)), child: arc),
              Opacity(
                opacity: wordT,
                child: Transform.translate(
                  offset: Offset(0, (1 - wordT) * h * (30 / 207)),
                  child: wordmark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _layer(String name, double w, double h, bool dark) {
    final raw = _svgRaw[name];
    if (raw == null) {
      // Strings not loaded yet (first frames only): the light asset is fine — the
      // ink layers (arc/wordmark) reveal later, by when the strings have loaded.
      return SvgPicture.asset(
        'assets/logo/$name.svg',
        width: w,
        height: h,
        fit: BoxFit.contain,
      );
    }
    final svg = dark
        ? raw
              .replaceAll(_lightInk, _darkInk)
              .replaceAll(_lightInkUpper, _darkInk)
        : raw;
    return SvgPicture.string(svg, width: w, height: h, fit: BoxFit.contain);
  }
}

/// Reveals its child left→right: [progress] 0 shows nothing, 1 shows all.
/// Mirrors the web arc's `clip-path: inset(0 100% 0 0)` → `inset(0 0 0 0)`.
class _WipeClipper extends CustomClipper<Rect> {
  const _WipeClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress.clamp(0, 1), size.height);

  @override
  bool shouldReclip(_WipeClipper oldClipper) => oldClipper.progress != progress;
}
