import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme.dart';
import '../widgets/motion.dart';

/// Skills drawn as a memory hierarchy: narrow at the hardware and widening
/// toward the tools, with a pulse of light travelling down through the layers.
class StackSection extends StatelessWidget {
  const StackSection({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Layout.wide;
    return SectionFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            address: '0x20',
            label: 'stack',
            title: 'From silicon to toolchain.',
          ),
          const SizedBox(height: 52),
          LiveClock(
            builder: (context, clock) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < stackLayers.length; i++)
                  Reveal(
                    delay: Duration(milliseconds: 70 * i),
                    offset: const Offset(-40, 0),
                    child: FractionallySizedBox(
                      widthFactor: wide
                          ? 0.72 + 0.28 * i / (stackLayers.length - 1)
                          : 1,
                      child: _Layer(
                        layer: stackLayers[i],
                        index: i,
                        count: stackLayers.length,
                        clock: clock,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Layer extends StatefulWidget {
  const _Layer({
    required this.layer,
    required this.index,
    required this.count,
    required this.clock,
  });

  final StackLayer layer;
  final int index;
  final int count;
  final ValueNotifier<double> clock;

  @override
  State<_Layer> createState() => _LayerState();
}

class _LayerState extends State<_Layer> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Motion.settle,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _hover ? Palette.panel : Palette.ink,
          border: Border.all(color: _hover ? Palette.amber : Palette.line),
        ),
        child: CustomPaint(
          painter: _PulseWash(widget.clock, widget.index, widget.count),
          // The wash repaints every frame; the text above it does not.
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 240),
                        style: Fonts.display(
                          27,
                          wght: 720,
                          wdth: 92,
                          color: _hover ? Palette.amber : Palette.paper,
                        ),
                        child: Text(layer.name),
                      ),
                      const SizedBox(height: 5),
                      Text(layer.note, style: Fonts.mono(12)),
                    ],
                  );
                  final chips = Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in layer.skills)
                        TagChip(
                          skill,
                          color: _hover ? Palette.paper : Palette.muted,
                        ),
                    ],
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [heading, const SizedBox(height: 14), chips],
                    );
                  }
                  return Row(
                    children: [
                      SizedBox(width: 250, child: heading),
                      const SizedBox(width: 20),
                      Expanded(child: chips),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseWash extends CustomPainter {
  _PulseWash(this.clock, this.index, this.count) : super(repaint: clock);

  final ValueNotifier<double> clock;
  final int index;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = (clock.value / 4.2 - index * 0.11) % 1.0;
    final glow = math.exp(-phase * 7);
    if (glow < 0.01) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Palette.amber.withValues(alpha: 0.2 * glow),
            Palette.amber.withValues(alpha: 0),
          ],
          stops: [0, math.min(1, 0.25 + phase * 2)],
        ).createShader(rect),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, size.height),
      Paint()..color = Palette.amber.withValues(alpha: glow),
    );
  }

  @override
  bool shouldRepaint(_PulseWash oldDelegate) => false;
}
