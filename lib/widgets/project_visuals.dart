import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme.dart';

/// A small live model of what each project does. Each painter is a pure
/// function of time, so it costs nothing when the clock is stopped.
CustomPainter painterFor(ProjectVisual visual, ValueNotifier<double> clock) {
  return switch (visual) {
    ProjectVisual.simdCompression => _SimdPainter(clock),
    ProjectVisual.gateway => _GatewayPainter(clock),
    ProjectVisual.ragPipeline => _RagPainter(clock),
  };
}

// Laying out text is the costliest part of these painters, and the same few
// labels come back every frame.
const _labelCacheLimit = 128;
final _labelCache = <(String, double, Color), TextPainter>{};

TextPainter _layoutLabel(String text, double size, Color color) {
  final key = (text, size, color);
  final cached = _labelCache[key];
  if (cached != null) return cached;
  if (_labelCache.length >= _labelCacheLimit) {
    for (final painter in _labelCache.values) {
      painter.dispose();
    }
    _labelCache.clear();
  }
  return _labelCache[key] = TextPainter(
    text: TextSpan(
      text: text,
      style: Fonts.mono(size, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

void _label(
  Canvas canvas,
  String text,
  Offset at, {
  Color color = Palette.muted,
  double size = 11,
  Alignment anchor = Alignment.topLeft,
}) {
  final painter = _layoutLabel(text, size, color);
  painter.paint(canvas, anchor.alongSize(painter.size) * -1 + at);
}

double _hash(int n) {
  final v = math.sin(n * 127.1) * 43758.5453;
  return v - v.floorToDouble();
}

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// A SIMD register sweeps a grid of 4-bit values one row at a time, and each
/// row leaves as a shorter block in the Zstd frame.
class _SimdPainter extends CustomPainter {
  _SimdPainter(this.clock) : super(repaint: clock);

  static const _rows = 4;
  static const _columns = 8;
  static const _rowPeriod = 0.8;
  final ValueNotifier<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = clock.value / _rowPeriod;
    final step = phase.floor();
    final frac = phase - step;
    final row = step % _rows;
    final epoch = step ~/ _rows;

    const pad = 22.0;
    const top = 38.0;
    final gridW = size.width * 0.56;
    final gridH = size.height - top - 38;
    final cellW = gridW / _columns;
    final cellH = gridH / _rows;
    final outL = pad + gridW + 34;
    final outW = size.width - pad - outL;
    final paint = Paint();

    _label(canvas, '4-bit weights', const Offset(pad, 14));
    _label(canvas, 'zstd frame', Offset(outL, 14), color: Palette.teal);
    _label(
      canvas,
      'simd register',
      Offset(pad, size.height - 26),
      color: Palette.amber,
    );

    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _columns; c++) {
        final rect = Rect.fromLTWH(
          pad + c * cellW + 1.5,
          top + r * cellH + 1.5,
          cellW - 3,
          cellH - 3,
        );
        final active = r == row;
        paint.color = active
            ? Palette.amber.withValues(alpha: 0.28)
            : r < row
            ? Palette.teal.withValues(alpha: 0.14)
            : Palette.line.withValues(alpha: 0.5);
        canvas.drawRect(rect, paint);
        final nibble = (_hash(epoch * 64 + r * _columns + c) * 16).floor();
        _label(
          canvas,
          nibble.toRadixString(16),
          rect.center,
          color: active ? Palette.paper : Palette.muted,
          anchor: Alignment.center,
        );
      }
    }

    final registerY = row == 0
        ? top
        : top + (row - 1 + _smooth(0, 0.3, frac)) * cellH;
    canvas.drawRect(
      Rect.fromLTWH(pad, registerY, gridW, cellH),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Palette.amber,
    );

    double blockWidth(int r) => outW * (0.42 + _hash(epoch * 4 + r + 31) * 0.5);
    for (var r = 0; r < _rows; r++) {
      final slot = Rect.fromLTWH(
        outL,
        top + r * cellH + cellH * 0.28,
        outW,
        cellH * 0.44,
      );
      paint.color = Palette.line.withValues(alpha: 0.4);
      canvas.drawRect(slot, paint);
      final done = r < row || (r == row && frac > 0.82);
      if (done) {
        paint.color = Palette.teal.withValues(alpha: 0.85);
        canvas.drawRect(
          Rect.fromLTWH(slot.left, slot.top, blockWidth(r), slot.height),
          paint,
        );
      }
    }

    final travel = _smooth(0.3, 0.82, frac);
    if (travel > 0 && travel < 1) {
      final fromX = pad + gridW;
      canvas.drawRect(
        Rect.fromLTWH(
          fromX + (outL - fromX) * travel,
          top + row * cellH + cellH * 0.28,
          lerpDouble(cellW * 2, blockWidth(row), travel),
          cellH * 0.44,
        ),
        paint..color = Color.lerp(Palette.amber, Palette.teal, travel)!,
      );
    }
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_SimdPainter oldDelegate) => false;
}

/// Traffic comes in over coax, crosses the cable modem and router inside the
/// RDK-B gateway, and fans out to the clients.
class _GatewayPainter extends CustomPainter {
  _GatewayPainter(this.clock) : super(repaint: clock);

  static const _clients = 3;
  static const _packets = 9;
  final ValueNotifier<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    const pad = 18.0;
    const clientW = 34.0;
    final box = Rect.fromLTRB(
      size.width * 0.3,
      34,
      size.width * 0.68,
      size.height - 22,
    );
    final moduleH = (box.height - 34) / 2;
    final modem = Rect.fromLTWH(
      box.left + 10,
      box.top + 10,
      box.width - 20,
      moduleH,
    );
    final router = Rect.fromLTWH(
      box.left + 10,
      box.bottom - 10 - moduleH,
      box.width - 20,
      moduleH,
    );
    final clientX = size.width - pad - clientW;
    final clientYs = [
      for (var i = 0; i < _clients; i++)
        box.top + box.height * (i + 0.5) / _clients,
    ];
    final wire = Paint()..color = Palette.line;

    canvas.drawLine(
      Offset(pad, modem.center.dy),
      Offset(modem.left, modem.center.dy),
      wire,
    );
    canvas.drawLine(modem.bottomCenter, router.topCenter, wire);
    for (final y in clientYs) {
      canvas.drawLine(router.centerRight, Offset(clientX, y), wire);
    }

    var modemHit = 0.0;
    var routerHit = 0.0;
    final paint = Paint();
    for (var i = 0; i < _packets; i++) {
      final age = (t * 0.28 + i / _packets) % 1.0;
      final Offset at;
      if (age < 0.35) {
        at = Offset.lerp(
          Offset(pad, modem.center.dy),
          modem.center,
          age / 0.35,
        )!;
      } else if (age < 0.55) {
        modemHit = math.max(modemHit, 1 - (age - 0.35) / 0.2);
        at = Offset.lerp(modem.center, router.center, (age - 0.35) / 0.2)!;
      } else {
        routerHit = math.max(routerHit, 1 - (age - 0.55) / 0.2);
        at = Offset.lerp(
          router.center,
          Offset(clientX, clientYs[i % _clients]),
          (age - 0.55) / 0.45,
        )!;
      }
      paint.color = Color.lerp(
        Palette.amber,
        Palette.teal,
        _smooth(0.35, 0.6, age),
      )!;
      canvas.drawRect(Rect.fromCenter(center: at, width: 9, height: 9), paint);
    }

    void outline(Rect rect, Color color) => canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color,
    );

    void module(Rect rect, String name, double hit, Color color) {
      canvas.drawRect(
        rect,
        Paint()..color = color.withValues(alpha: 0.05 + hit * 0.18),
      );
      outline(rect, Color.lerp(Palette.line, color, hit)!);
      // In the corner, clear of the path the packets take through the middle.
      _label(
        canvas,
        name,
        rect.topLeft + const Offset(8, 6),
        color: Palette.paper,
      );
    }

    outline(box, Palette.line);
    module(modem, 'cable modem', modemHit, Palette.amber);
    module(router, 'router', routerHit, Palette.teal);

    _label(canvas, 'rdk-b gateway', Offset(box.left, 14));
    _label(
      canvas,
      'coax',
      Offset(pad, modem.center.dy - 8),
      anchor: Alignment.bottomLeft,
    );
    for (final y in clientYs) {
      final client = Rect.fromCenter(
        center: Offset(clientX + clientW / 2, y),
        width: clientW,
        height: 24,
      );
      canvas.drawRect(client, Paint()..color = Palette.ink);
      outline(client, Palette.line);
      _label(canvas, 'lan', client.center, anchor: Alignment.center);
    }
  }

  @override
  bool shouldRepaint(_GatewayPainter oldDelegate) => false;
}

/// Logs scroll past, a query pulls its nearest chunks from the vector index,
/// and an answer is written from what came back.
class _RagPainter extends CustomPainter {
  _RagPainter(this.clock) : super(repaint: clock);

  static const _logRows = 10;
  static const _dots = 30;
  static const _retrieved = 4;
  static const _answerLines = 8;
  static const _period = 3.4;
  final ValueNotifier<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    const pad = 20.0;
    const gap = 18.0;
    const top = 40.0;
    final columnW = (size.width - pad * 2 - gap * 2) / 3;
    final areaH = size.height - top - 20;
    final indexL = pad + columnW + gap;
    final answerL = indexL + columnW + gap;
    final cycle = t / _period;
    final epoch = cycle.floor();
    final u = cycle - epoch;
    final fade = 1 - _smooth(0.88, 1, u);
    final paint = Paint();

    _label(canvas, 'logs', const Offset(pad, 14));
    _label(canvas, 'vector index', Offset(indexL, 14));
    _label(canvas, 'answer', Offset(answerL, 14), color: Palette.teal);

    final rowH = areaH / _logRows;
    final scroll = t * 2.2;
    final first = scroll.floor();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(pad, top, columnW, areaH));
    for (var i = 0; i <= _logRows; i++) {
      final seq = first + i;
      final error = _hash(seq + 7) > 0.84;
      paint.color = error
          ? Palette.coral.withValues(alpha: 0.9)
          : Palette.line.withValues(alpha: 0.95);
      canvas.drawRect(
        Rect.fromLTWH(
          pad,
          top + (i - (scroll - first)) * rowH + rowH * 0.25,
          columnW * (0.4 + _hash(seq) * 0.6),
          rowH * 0.5,
        ),
        paint,
      );
    }
    canvas.restore();

    Offset dot(int i) => Offset(
      indexL + 6 + _hash(i * 2 + 3) * (columnW - 12),
      top + 6 + _hash(i * 2 + 4) * (areaH - 12),
    );

    final queryIndex = (_hash(epoch + 11) * _dots).floor();
    final query = dot(queryIndex);
    final nearest =
        [
          for (var i = 0; i < _dots; i++)
            if (i != queryIndex) i,
        ]..sort(
          (a, b) => (dot(a) - query).distanceSquared.compareTo(
            (dot(b) - query).distanceSquared,
          ),
        );
    final hits = nearest.take(_retrieved).toSet();
    final found = _smooth(0.08, 0.34, u) * fade;

    for (final i in hits) {
      canvas.drawLine(
        query,
        Offset.lerp(query, dot(i), found)!,
        Paint()..color = Palette.amber.withValues(alpha: 0.7 * fade),
      );
    }
    for (var i = 0; i < _dots; i++) {
      final hit = hits.contains(i);
      paint.color = hit
          ? Color.lerp(Palette.muted, Palette.amber, found)!
          : Palette.muted.withValues(alpha: 0.4);
      canvas.drawRect(
        Rect.fromCenter(
          center: dot(i),
          width: hit ? 7 : 4,
          height: hit ? 7 : 4,
        ),
        paint,
      );
    }
    canvas.drawRect(
      Rect.fromCenter(center: query, width: 10, height: 10),
      Paint()..color = Palette.coral,
    );

    final answerRowH = areaH / _answerLines;
    final barH = answerRowH * 0.4;
    for (var i = 0; i < _answerLines; i++) {
      final reveal = _smooth(0.36 + i * 0.055, 0.45 + i * 0.055, u) * fade;
      final y = top + i * answerRowH + (answerRowH - barH) / 2;
      paint.color = Palette.line.withValues(alpha: 0.35);
      canvas.drawRect(Rect.fromLTWH(answerL, y, columnW, barH), paint);
      paint.color = Palette.teal.withValues(alpha: 0.85);
      canvas.drawRect(
        Rect.fromLTWH(
          answerL,
          y,
          columnW * (0.5 + _hash(epoch * 5 + i) * 0.5) * reveal,
          barH,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RagPainter oldDelegate) => false;
}
