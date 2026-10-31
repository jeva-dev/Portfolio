import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/portfolio_data.dart';
import '../theme.dart';
import '../widgets/memory_field.dart';
import '../widgets/motion.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({
    super.key,
    required this.scroll,
    required this.revealed,
    required this.onNavigate,
  });

  final ScrollController scroll;
  final ValueListenable<bool> revealed;
  final ValueChanged<int> onNavigate;

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  final _input = FieldInput();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = math.max(size.height, 640.0);
    final gutter = Layout.gutter(size.width);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: MouseRegion(
        opaque: false,
        onHover: (e) => _input.pointer = e.position,
        onExit: (_) => _input.pointer = null,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _input.pulses.add(e.position),
          child: Stack(
            children: [
              Positioned.fill(child: MemoryField(input: _input)),
              const Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: _LegibilityScrim()),
                ),
              ),
              AnimatedBuilder(
                animation: widget.scroll,
                builder: (context, child) {
                  final offset = widget.scroll.hasClients
                      ? widget.scroll.position.pixels
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(0, offset * 0.28),
                    child: Opacity(
                      opacity: (1 - offset / (height * 0.75)).clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: RepaintBoundary(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Layout.maxWidth,
                        minHeight: height,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 70, gutter, 40),
                        child: _HeroContent(
                          input: _input,
                          revealed: widget.revealed,
                          onNavigate: widget.onNavigate,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegibilityScrim extends StatelessWidget {
  const _LegibilityScrim();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _ScrimPainter(), size: Size.infinite);
  }
}

/// Darkens the heap behind the hero text, from the left and from the bottom.
/// Drawn as solid bands because full-screen gradient shaders caused raster
/// spikes of up to 500 ms while scrolling. The steps are too faint to see.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter();

  static const _columns = 48;
  static const _rows = 32;
  static const _bottomReach = 0.3;

  double _leftAlpha(double x) => x < 0.55
      ? 0.82 + (0.35 - 0.82) * (x / 0.55)
      : 0.35 * (1 - (x - 0.55) / 0.45);

  @override
  void paint(Canvas canvas, Size size) {
    // Without antialiasing, neighbouring bands meet with no visible seam.
    final paint = Paint()..isAntiAlias = false;
    for (var i = 0; i < _columns; i++) {
      final left = (size.width * i / _columns).roundToDouble();
      final right = (size.width * (i + 1) / _columns).roundToDouble();
      paint.color = Palette.ink.withValues(
        alpha: _leftAlpha((i + 0.5) / _columns),
      );
      canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height), paint);
    }
    final reach = size.height * _bottomReach;
    for (var i = 0; i < _rows; i++) {
      final bottom = (size.height - reach * i / _rows).roundToDouble();
      final top = (size.height - reach * (i + 1) / _rows).roundToDouble();
      paint.color = Palette.ink.withValues(alpha: 1 - (i + 0.5) / _rows);
      canvas.drawRect(Rect.fromLTRB(0, top, size.width, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) => false;
}

class _HeroContent extends StatefulWidget {
  const _HeroContent({
    required this.input,
    required this.revealed,
    required this.onNavigate,
  });

  final FieldInput input;
  final ValueListenable<bool> revealed;
  final ValueChanged<int> onNavigate;

  @override
  State<_HeroContent> createState() => _HeroContentState();
}

class _HeroContentState extends State<_HeroContent>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    widget.revealed.addListener(_onRevealed);
  }

  @override
  void dispose() {
    widget.revealed.removeListener(_onRevealed);
    _intro.dispose();
    super.dispose();
  }

  void _onRevealed() {
    if (!widget.revealed.value) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  /// Everything except the name fades up behind it, later in the intro.
  Widget _stagger(double start, Widget child) {
    final curved = _intro.drive(
      CurveTween(
        curve: Interval(start, math.min(1, start + 0.5), curve: Motion.settle),
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stagger(
          0.15,
          Row(
            children: [
              const RepaintBoundary(child: _Led()),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '$availability  /  $location',
                  style: Fonts.mono(13, color: Palette.paper),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        KineticName(
          lines: nameLines,
          input: widget.input,
          intro: _intro,
          fontSize: (width * 0.15).clamp(70.0, 190.0),
        ),
        const SizedBox(height: 26),
        _stagger(
          0.4,
          Text(
            role,
            style: Fonts.mono(
              width < 600 ? 15 : 19,
              color: Palette.amber,
              wght: 500,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _stagger(
          0.5,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(tagline, style: Fonts.body(width < 600 ? 17 : 20)),
          ),
        ),
        const SizedBox(height: 30),
        _stagger(
          0.6,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeroButton('See the work', () => widget.onNavigate(3)),
              _HeroButton('Get in touch', () => widget.onNavigate(5)),
              if (width >= Layout.wide)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'Move over the heap. Click to send a pulse.',
                    style: Fonts.mono(12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WipeLink(
      onTap: onTap,
      child: (foreground) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Text(label, style: Fonts.mono(14, color: foreground, wght: 500)),
      ),
    );
  }
}

class _Led extends StatelessWidget {
  const _Led();

  @override
  Widget build(BuildContext context) {
    return LiveClock(
      builder: (context, clock) => AnimatedBuilder(
        animation: clock,
        builder: (context, _) => Container(
          width: 9,
          height: 9,
          color: Color.lerp(
            Palette.teal,
            Palette.teal.withValues(alpha: 0.3),
            (math.sin(clock.value * 3) + 1) / 2,
          ),
        ),
      ),
    );
  }
}

/// The name, set in a variable font. Letters rise in one at a time, then thin
/// out and widen as the pointer passes over them.
class KineticName extends StatefulWidget {
  const KineticName({
    super.key,
    required this.lines,
    required this.input,
    required this.intro,
    required this.fontSize,
  });

  final List<String> lines;
  final FieldInput input;
  final Animation<double> intro;
  final double fontSize;

  @override
  State<KineticName> createState() => _KineticNameState();
}

class _KineticNameState extends State<KineticName>
    with SingleTickerProviderStateMixin {
  List<List<String>> _lines = const [];
  List<GlobalKey> _keys = const [];
  // One notifier per letter, so the pointer only rebuilds the letters it moves.
  List<ValueNotifier<double>> _pull = const [];
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncLetters();
  }

  @override
  void didUpdateWidget(KineticName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.lines, widget.lines)) _syncLetters();
  }

  void _syncLetters() {
    for (final pull in _pull) {
      pull.dispose();
    }
    _lines = [for (final line in widget.lines) line.toUpperCase().split('')];
    final count = _lines.fold(0, (sum, line) => sum + line.length);
    _keys = List.generate(count, (_) => GlobalKey());
    _pull = List.generate(count, (_) => ValueNotifier<double>(0));
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final pointer = widget.input.pointer;
    final reach = widget.fontSize * 1.5;
    final ease = 1 - math.exp(-dt * 11);
    for (var i = 0; i < _pull.length; i++) {
      var target = 0.0;
      if (pointer != null) {
        final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final center = box.localToGlobal(box.size.center(Offset.zero));
          final d = (center - pointer).distance / reach;
          target = d >= 1 ? 0 : math.pow(1 - d, 2).toDouble();
        }
      }
      final pull = _pull[i];
      final next = pull.value + (target - pull.value) * ease;
      if ((next - pull.value).abs() > 0.001) pull.value = next;
    }
  }

  void _onVisible(bool visible) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (visible && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!visible && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    for (final pull in _pull) {
      pull.dispose();
    }
    super.dispose();
  }

  Widget _letter(int i, String letter) {
    final start = math.min(0.02 * i, 0.5);
    final rise = widget.intro.drive(
      CurveTween(curve: Interval(start, start + 0.5, curve: Motion.settle)),
    );
    return ClipRect(
      key: _keys[i],
      child: AnimatedBuilder(
        animation: rise,
        child: ValueListenableBuilder(
          valueListenable: _pull[i],
          builder: (context, pull, _) => Text(
            letter,
            style: Fonts.display(
              widget.fontSize,
              wght: 860 - pull * 640,
              wdth: 100 + pull * 25,
              color: Color.lerp(Palette.paper, Palette.amber, pull)!,
              height: 0.98,
              tracking: -0.015,
            ),
          ),
        ),
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, 1.02 * (1 - rise.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var index = 0;
    return Semantics(
      header: true,
      label: fullName,
      child: ExcludeSemantics(
        child: ViewportSignal(
          onChanged: _onVisible,
          child: RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in _lines)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final letter in line) _letter(index++, letter),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
