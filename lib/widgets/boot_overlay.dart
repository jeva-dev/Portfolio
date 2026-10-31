import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Opening sequence: the page "compiles", then the build screen frees itself
/// cell by cell to expose the hero. A click or tap skips it.
class BootOverlay extends StatefulWidget {
  const BootOverlay({super.key, required this.onReveal});

  /// Fires as the screen starts dissolving, so the hero can animate in under it.
  final VoidCallback onReveal;

  @override
  State<BootOverlay> createState() => _BootOverlayState();
}

class _BootOverlayState extends State<BootOverlay>
    with SingleTickerProviderStateMixin {
  static const _compile = 0.62;
  static const _lines = [
    (0.00, r'$ clang++ -std=c++23 -O3 -flto -march=native portfolio.cpp'),
    (0.14, '[ 17%] Building memory_field.cpp.o'),
    (0.26, '[ 38%] Building kinetic_type.cpp.o'),
    (0.38, '[ 64%] Building lock_free_projects.cpp.o'),
    (0.50, '[ 86%] Linking CXX executable portfolio'),
    (0.58, '[100%] Built target portfolio   0 warnings, 0 errors'),
    (0.60, r'$ ./portfolio'),
  ];

  late final AnimationController _controller;
  bool _revealed = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2500),
          )
          ..addListener(() {
            if (_controller.value >= _compile) _reveal();
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() => _done = true);
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _revealed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reveal();
        setState(() => _done = true);
      });
    } else {
      _controller.forward();
    }
  }

  void _reveal() {
    if (_revealed) return;
    _revealed = true;
    widget.onReveal();
  }

  void _skip() {
    if (_controller.value < _compile) _controller.value = _compile;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final dissolve = ((t - _compile) / (1 - _compile)).clamp(0.0, 1.0);
          final textOpacity = (1 - dissolve * 5).clamp(0.0, 1.0);
          return CustomPaint(
            painter: _DissolvePainter(Curves.easeInOut.transform(dissolve)),
            child: Opacity(
              opacity: textOpacity,
              child: _BuildLog(lines: _lines, time: t, compile: _compile),
            ),
          );
        },
      ),
    );
  }
}

class _BuildLog extends StatelessWidget {
  const _BuildLog({
    required this.lines,
    required this.time,
    required this.compile,
  });

  final List<(double, String)> lines;
  final double time;
  final double compile;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width < 600 ? 11.5 : 14.0;
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.all(Layout.gutter(width)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (at, text) in lines)
              Opacity(
                opacity: time >= at ? 1 : 0,
                child: Text(
                  text,
                  style: Fonts.mono(
                    size,
                    color: text.startsWith(r'$')
                        ? Palette.paper
                        : text.contains('100%')
                        ? Palette.amber
                        : Palette.muted,
                    height: 1.8,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: (time / compile).clamp(0.0, 1.0),
                child: Container(
                  width: double.infinity,
                  height: 2,
                  color: Palette.amber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DissolvePainter extends CustomPainter {
  _DissolvePainter(this.progress);

  static const _cell = 44.0;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Palette.ink;
    if (progress <= 0) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    final cols = (size.width / _cell).ceil();
    final rows = (size.height / _cell).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // A diagonal sweep, broken up by per-cell noise. Cells are hashed so
        // the pattern stays stable from frame to frame.
        final noise = (math.sin(c * 12.9898 + r * 78.233) * 43758.5453) % 1;
        final order = (c / cols + r / rows) * 0.34 + noise.abs() * 0.3;
        final local = ((progress - order) / 0.36).clamp(0.0, 1.0);
        if (local >= 1) continue;
        final side = _cell * (1 - local) + 0.6;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset((c + 0.5) * _cell, (r + 0.5) * _cell),
            width: side,
            height: side,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DissolvePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
