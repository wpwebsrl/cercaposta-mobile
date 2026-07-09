import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_info.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';
import 'animated_logo.dart';

const _wpwebUrl = 'https://www.wpweb.com';

/// Open wpweb.com in the browser; best-effort (no crash if no browser resolves,
/// e.g. Android 11+ package visibility or a browserless device).
Future<void> _openWebsite() async {
  try {
    await launchUrl(Uri.parse(_wpwebUrl), mode: LaunchMode.externalApplication);
  } on Object {
    // ignore: nothing actionable to show from a decorative footer link.
  }
}

/// Marketing "About" page, mirroring the web About dialog's content and order:
/// animated logo → company (WPWEB S.R.L.) → app name → version pill → build ·
/// date → the descriptive credits (auto-scrolling roll) → website link.
/// No QR code (dropped on purpose for mobile).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = ref.watch(appInfoProvider);

    final build = AppInfo.buildDate.isNotEmpty
        ? '${AppInfo.build} · ${AppInfo.buildDate}'
        : AppInfo.build;
    final credits = l.aboutCredits
        .split('\n')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: <Widget>[
                // Brand logo: the wordmark ink is theme-aware (light in dark mode),
                // so no white glow is needed behind it.
                const AnimatedLogo(width: 132),
                const SizedBox(height: 6),
                Text(
                  l.aboutCompany.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'v${info.version}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l.aboutBuildLabel} $build',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _CreditsRoll(
              lines: credits,
              holdDuration: AnimatedLogo.animationDuration,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: TextButton.icon(
              onPressed: _openWebsite,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(l.aboutWebsite),
            ),
          ),
        ],
      ),
    );
  }
}

/// Descriptive credits, phased exactly like the web's About roll:
///  1. hold  — only the first line, until the logo animation finishes;
///  2. type  — the remaining lines reveal character-by-character below it,
///             stacking downward until they fill the viewport;
///  3. scroll — the whole list then scrolls continuously (seamless loop via
///             two stacked copies translated by one copy's height).
class _CreditsRoll extends StatefulWidget {
  const _CreditsRoll({required this.lines, required this.holdDuration});
  final List<String> lines;
  final Duration holdDuration;

  @override
  State<_CreditsRoll> createState() => _CreditsRollState();
}

enum _Phase { hold, type, scroll }

class _CreditsRollState extends State<_CreditsRoll>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _speed = 26.0; // scroll speed, logical px per second
  static const _charInterval = Duration(milliseconds: 22); // typewriter reveal

  final GlobalKey _copyKey = GlobalKey(); // first scroll copy (measured height)
  final GlobalKey _growKey = GlobalKey(); // typing column (viewport-fill check)
  // Created in initState (not a lazy `late final`): otherwise closing the page
  // during the hold phase would first touch it in dispose(), creating a ticker
  // mid-teardown (assert). It just isn't started until the scroll phase.
  late final AnimationController _scroll;

  _Phase _phase = _Phase.hold;
  int _typed = 0; // characters revealed across lines[1..]
  Timer? _holdTimer;
  Timer? _typeTimer;
  double _copyHeight = 0;
  double _vpHeight = 0;
  double _lastScale = 1;
  int _pendingMeasure = 0;

  // Char offset at which each line's typing begins (line 0 stays whole in hold).
  late final List<int> _offsets = _computeOffsets();
  late final int _totalChars = widget.lines.isEmpty
      ? 0
      : _offsets.last + widget.lines.last.length;

  List<int> _computeOffsets() {
    final out = <int>[];
    var acc = 0;
    for (var i = 0; i < widget.lines.length; i++) {
      out.add(acc);
      if (i >= 1) acc += widget.lines[i].length;
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _scroll = AnimationController(vsync: this);
    WidgetsBinding.instance.addObserver(this);
    // Hold the first line until the logo has finished revealing, then type.
    _holdTimer = Timer(widget.holdDuration, _startTyping);
  }

  void _startTyping() {
    if (!mounted) return;
    if (widget.lines.length <= 1 || _totalChars <= 0) {
      _startScroll();
      return;
    }
    setState(() => _phase = _Phase.type);
    _typeTimer = Timer.periodic(_charInterval, (_) => _onTypeTick());
  }

  void _onTypeTick() {
    if (!mounted) return;
    setState(() => _typed = math.min(_typed + 1, _totalChars));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != _Phase.type) return;
      final grown = _growKey.currentContext?.size?.height ?? 0;
      // Once everything is typed OR the column fills the viewport, start rolling.
      if (_typed >= _totalChars ||
          (grown > 0 && _vpHeight > 0 && grown >= _vpHeight)) {
        _startScroll();
      }
    });
  }

  void _startScroll() {
    _typeTimer?.cancel();
    if (!mounted) return;
    setState(() => _phase = _Phase.scroll);
    _scheduleMeasure();
  }

  // Rotation / metrics / text-scale changes: the Activity isn't recreated
  // (configChanges), so the State survives with a now-wrong copy height — remeasure.
  @override
  void didChangeMetrics() {
    if (_phase == _Phase.scroll) _scheduleMeasure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scale = MediaQuery.textScalerOf(context).scale(100);
    if (scale != _lastScale) {
      _lastScale = scale;
      if (_phase == _Phase.scroll) _scheduleMeasure();
    }
  }

  @override
  void didUpdateWidget(_CreditsRoll old) {
    super.didUpdateWidget(old);
    if (old.lines != widget.lines && _phase == _Phase.scroll) {
      _scheduleMeasure();
    }
  }

  void _scheduleMeasure() {
    final token = ++_pendingMeasure;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(token));
  }

  void _measure(int token) {
    if (!mounted || token != _pendingMeasure || _phase != _Phase.scroll) return;
    final h = _copyKey.currentContext?.size?.height ?? 0;
    if (h <= 0) {
      if (token < 6) _scheduleMeasure(); // not laid out yet: bounded retry
      return;
    }
    if ((h - _copyHeight).abs() < 0.5 && _scroll.isAnimating) return;
    setState(() => _copyHeight = h);
    // Clamp so a tiny height can't yield a ~0ms duration (repeat() would assert).
    final ms = (h / _speed * 1000).round().clamp(4000, 600000);
    _scroll.duration = Duration(milliseconds: ms);
    _scroll
      ..stop()
      ..repeat();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _typeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        _vpHeight = constraints.maxHeight;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _phase == _Phase.scroll ? _scrollLayer() : _revealLayer(),
              _fade(bg, top: true),
              _fade(bg, top: false),
            ],
          ),
        );
      },
    );
  }

  // hold + type: a top-anchored column that grows as characters are revealed.
  Widget _revealLayer() {
    final children = <Widget>[const SizedBox(height: 20)];
    for (var i = 0; i < widget.lines.length; i++) {
      final line = widget.lines[i];
      String? text;
      if (i == 0) {
        text = line; // whole first line during both hold and type
      } else if (_phase == _Phase.type && _typed > _offsets[i]) {
        text = line.substring(0, math.min(line.length, _typed - _offsets[i]));
      }
      if (text == null) continue;
      children.add(_creditLine(text));
    }
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: Column(
        key: _growKey,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  // scroll: two stacked copies translated by one copy's height (seamless loop).
  Widget _scrollLayer() {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        KeyedSubtree(key: _copyKey, child: _copy()),
        _copy(), // second copy makes the wrap seamless
      ],
    );
    return AnimatedBuilder(
      animation: _scroll,
      child: content,
      builder: (context, child) {
        final off = _copyHeight == 0 ? 0.0 : _scroll.value * _copyHeight;
        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Transform.translate(offset: Offset(0, -off), child: child),
        );
      },
    );
  }

  Widget _copy() => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const SizedBox(height: 20),
      for (final line in widget.lines) _creditLine(line),
      const SizedBox(height: 40), // gap between loops
    ],
  );

  Widget _creditLine(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 5),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.35,
      ),
    ),
  );

  Widget _fade(Color bg, {required bool top}) => Positioned(
    top: top ? 0 : null,
    bottom: top ? null : 0,
    left: 0,
    right: 0,
    height: 28,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: <Color>[bg, bg.withValues(alpha: 0)],
          ),
        ),
      ),
    ),
  );
}
