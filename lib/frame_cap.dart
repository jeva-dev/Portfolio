import 'package:flutter/widgets.dart';

/// Decides which display refreshes become frames, averaging 60 per second on
/// any refresh rate.
class FrameGate {
  static const _interval = Duration(microseconds: 16667);

  // Vsync timestamps jitter, so a 60 Hz display must not lose frames that
  // arrive a little under the interval.
  static const _tolerance = Duration(milliseconds: 2);

  Duration? _last;

  bool admit(Duration timestamp) {
    final last = _last;
    if (last != null) {
      final delta = timestamp - last;
      if (delta < _interval - _tolerance) return false;
      // Stepping by the interval keeps rates like 144 Hz averaging 60 instead
      // of settling on a slower whole number of refreshes. After a long gap
      // there is nothing to catch up on, so it restarts from now.
      if (delta < _interval * 2) {
        _last = last + _interval;
        return true;
      }
    }
    _last = timestamp;
    return true;
  }
}

/// Caps every animation in the app at 60 FPS. Flutter has no frame rate
/// setting, so refreshes past the cap are dropped before any callback runs and
/// the next one is requested from the engine.
class FrameCappedBinding extends WidgetsFlutterBinding {
  final _gate = FrameGate();
  bool _skipped = false;

  @override
  void handleBeginFrame(Duration? rawTimeStamp) {
    // A null timestamp is the warm-up frame, which must always run.
    if (rawTimeStamp != null && !_gate.admit(rawTimeStamp)) {
      _skipped = true;
      platformDispatcher.scheduleFrame();
      return;
    }
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void handleDrawFrame() {
    if (_skipped) {
      _skipped = false;
      return;
    }
    super.handleDrawFrame();
  }
}
