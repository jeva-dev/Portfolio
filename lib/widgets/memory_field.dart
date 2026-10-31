import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';
import 'motion.dart';

/// Pointer input shared by the hero's field and its kinetic name.
class FieldInput {
  Offset? pointer;
  final List<Offset> pulses = [];
  final _sim = _HeapSim();
  final _repaint = ValueNotifier<int>(0);

  void dispose() => _repaint.dispose();
}

/// The hero background: a live heap map. Blocks are allocated and freed on
/// their own, the pointer heats the cells it passes, and a click sends a pulse
/// through the grid.
class MemoryField extends StatefulWidget {
  const MemoryField({super.key, required this.input});

  final FieldInput input;

  @override
  State<MemoryField> createState() => _MemoryFieldState();
}

class _MemoryFieldState extends State<MemoryField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    // Clamped so returning from a background tab does not jump the simulation.
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final input = widget.input;
    if (input._sim.cols == 0) return;
    final pointer = input.pointer == null
        ? null
        : box.globalToLocal(input.pointer!);
    final pulses = input.pulses.map(box.globalToLocal).toList();
    input.pulses.clear();
    input._sim.step(dt, pointer, pulses);
    input._repaint.value++;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewportSignal(
      onChanged: _onVisible,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _HeapPainter(widget.input._sim, widget.input._repaint),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Pulse {
  _Pulse(this.center);
  final Offset center;
  double radius = 0;
}

class _HeapSim {
  static const cell = 22.0;

  final _random = math.Random(64);
  final _pulses = <_Pulse>[];
  int cols = 0;
  int rows = 0;
  Float32List heat = Float32List(0);
  Float32List lifetime = Float32List(0);
  Offset? pointer;
  double _allocDebt = 0;

  void resize(Size size) {
    final nextCols = (size.width / cell).ceil() + 1;
    final nextRows = (size.height / cell).ceil() + 1;
    if (nextCols == cols && nextRows == rows) return;
    cols = nextCols;
    rows = nextRows;
    heat = Float32List(cols * rows);
    lifetime = Float32List(cols * rows);
    // Start part-full so the very first frame already looks like a live heap.
    for (var i = 0; i < cols * rows / 40; i++) {
      _malloc(initial: true);
    }
  }

  void _malloc({bool initial = false}) {
    final start = _random.nextInt(cols * rows);
    final length = 3 + _random.nextInt(_random.nextBool() ? 8 : 44);
    final life = 2 + _random.nextDouble() * 9;
    for (var i = start; i < math.min(start + length, cols * rows); i++) {
      lifetime[i] = life;
      if (!initial) heat[i] = 0.8;
    }
  }

  void step(double dt, Offset? nextPointer, List<Offset> newPulses) {
    if (cols == 0) return;
    pointer = nextPointer;
    _allocDebt += dt * cols * rows / 240;
    while (_allocDebt >= 1) {
      _allocDebt -= 1;
      _malloc();
    }
    final decay = math.exp(-dt * 2.4);
    for (var i = 0; i < heat.length; i++) {
      heat[i] *= decay;
      if (lifetime[i] > 0) {
        lifetime[i] -= dt;
        // A freed cell flashes briefly on its way out.
        if (lifetime[i] <= 0) heat[i] = math.max(heat[i], 0.25);
      }
    }
    if (pointer != null) _heatAround(pointer!);
    for (final center in newPulses) {
      _pulses.add(_Pulse(center));
    }
    for (final pulse in _pulses) {
      pulse.radius += dt * 780;
      _heatRing(pulse);
    }
    _pulses.removeWhere((p) => p.radius > 900);
  }

  void _heatAround(Offset p) {
    const reach = 120.0;
    final minCol = ((p.dx - reach) / cell).floor().clamp(0, cols - 1);
    final maxCol = ((p.dx + reach) / cell).ceil().clamp(0, cols - 1);
    final minRow = ((p.dy - reach) / cell).floor().clamp(0, rows - 1);
    final maxRow = ((p.dy + reach) / cell).ceil().clamp(0, rows - 1);
    for (var r = minRow; r <= maxRow; r++) {
      for (var c = minCol; c <= maxCol; c++) {
        final dx = c * cell - p.dx;
        final dy = r * cell - p.dy;
        final d = math.sqrt(dx * dx + dy * dy) / reach;
        if (d >= 1) continue;
        final i = r * cols + c;
        final target = (1 - d) * (1 - d);
        if (target > heat[i]) heat[i] = target;
      }
    }
  }

  void _heatRing(_Pulse pulse) {
    final strength = 1 - pulse.radius / 900;
    final around = (math.pi * 2 * pulse.radius / (cell * 0.5)).ceil();
    for (var k = 0; k < around; k++) {
      final angle = k / around * math.pi * 2;
      final c = ((pulse.center.dx + math.cos(angle) * pulse.radius) / cell)
          .round();
      final r = ((pulse.center.dy + math.sin(angle) * pulse.radius) / cell)
          .round();
      if (c < 0 || r < 0 || c >= cols || r >= rows) continue;
      final i = r * cols + c;
      if (strength > heat[i]) heat[i] = strength;
    }
  }
}

class _HeapPainter extends CustomPainter {
  _HeapPainter(this.sim, Listenable repaint) : super(repaint: repaint);

  static const _heatLevels = 6;

  final _HeapSim sim;
  Float32List _free = Float32List(0);
  Float32List _used = Float32List(0);
  List<Float32List> _hot = const [];

  @override
  void paint(Canvas canvas, Size size) {
    sim.resize(size);
    final capacity = sim.cols * sim.rows * 2;
    if (_free.length != capacity) {
      _free = Float32List(capacity);
      _used = Float32List(capacity);
      _hot = List.generate(_heatLevels, (_) => Float32List(capacity));
    }

    var freeCount = 0;
    var usedCount = 0;
    final hotCounts = List.filled(_heatLevels, 0);
    for (var r = 0; r < sim.rows; r++) {
      final y = r * _HeapSim.cell;
      for (var c = 0; c < sim.cols; c++) {
        final i = r * sim.cols + c;
        final x = c * _HeapSim.cell;
        final level = (sim.heat[i] * _heatLevels).floor();
        if (level > 0) {
          final bucket = math.min(level, _heatLevels) - 1;
          final buffer = _hot[bucket];
          buffer[hotCounts[bucket]++] = x;
          buffer[hotCounts[bucket]++] = y;
        } else if (sim.lifetime[i] > 0) {
          _used[usedCount++] = x;
          _used[usedCount++] = y;
        } else {
          _free[freeCount++] = x;
          _free[freeCount++] = y;
        }
      }
    }

    final paint = Paint()..strokeCap = StrokeCap.square;
    paint
      ..strokeWidth = 2
      ..color = Palette.line;
    _draw(canvas, _free, freeCount, paint);
    paint
      ..strokeWidth = 15
      ..color = Palette.paper.withValues(alpha: 0.075);
    _draw(canvas, _used, usedCount, paint);
    for (var b = 0; b < _heatLevels; b++) {
      paint.color = Palette.amber.withValues(alpha: 0.14 + b * 0.16);
      _draw(canvas, _hot[b], hotCounts[b], paint);
    }
  }

  void _draw(Canvas canvas, Float32List buffer, int count, Paint paint) {
    if (count == 0) return;
    canvas.drawRawPoints(
      PointMode.points,
      Float32List.sublistView(buffer, 0, count),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HeapPainter oldDelegate) => oldDelegate.sim != sim;
}
