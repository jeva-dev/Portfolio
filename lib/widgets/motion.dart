import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// Reports when its child enters or leaves the screen, so animation only runs
/// for what a visitor can see.
class ViewportSignal extends StatefulWidget {
  const ViewportSignal({
    super.key,
    required this.onChanged,
    required this.child,
    this.inset = 0,
    this.once = false,
  });

  final ValueChanged<bool> onChanged;
  final Widget child;

  /// How far inside the viewport the child must be to count as visible.
  final double inset;

  /// Stops watching the scroll position after first becoming visible.
  final bool once;

  @override
  State<ViewportSignal> createState() => _ViewportSignalState();
}

class _ViewportSignalState extends State<ViewportSignal> {
  ScrollPosition? _position;
  bool? _visible;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_finished) return;
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_check);
      _position = next;
      _position?.addListener(_check);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted || _finished) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final height = MediaQuery.sizeOf(context).height;
    final visible =
        top < height - widget.inset && top + box.size.height > widget.inset;
    if (visible != _visible) {
      _visible = visible;
      widget.onChanged(visible);
      if (visible && widget.once) {
        _finished = true;
        _position?.removeListener(_check);
        _position = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Depending on the size re-runs the check after a window resize.
    MediaQuery.sizeOf(context);
    if (!_finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
    return widget.child;
  }
}

/// Runs [controller] forward the first time the child scrolls into view.
class _OnceVisible extends StatefulWidget {
  const _OnceVisible({
    required this.duration,
    required this.delay,
    required this.builder,
  });

  final Duration duration;
  final Duration delay;
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  State<_OnceVisible> createState() => _OnceVisibleState();
}

class _OnceVisibleState extends State<_OnceVisible>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;

  void _onVisible(bool visible) {
    if (!visible || _started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewportSignal(
      inset: 40,
      once: true,
      onChanged: _onVisible,
      child: widget.builder(context, _controller),
    );
  }
}

/// Fades and lifts its child the first time it scrolls into view.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 36),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return _OnceVisible(
      duration: const Duration(milliseconds: 950),
      delay: delay,
      builder: (context, animation) {
        final curved = animation.drive(CurveTween(curve: Motion.settle));
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => Opacity(
            opacity: curved.value,
            child: Transform.translate(
              offset: offset * (1 - curved.value),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Raises each word out of a clipped baseline, one after another.
class RisingTitle extends StatelessWidget {
  const RisingTitle(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return Semantics(
      header: true,
      label: text,
      child: ExcludeSemantics(
        child: _OnceVisible(
          duration: Duration(milliseconds: 800 + words.length * 90),
          delay: Duration.zero,
          builder: (context, animation) => Wrap(
            spacing: (style.fontSize ?? 16) * 0.24,
            children: [
              for (var i = 0; i < words.length; i++)
                _RisingWord(
                  word: words[i],
                  style: style,
                  animation: animation.drive(
                    CurveTween(
                      curve: Interval(
                        i * 0.8 / words.length * 0.6,
                        math.min(1, i * 0.8 / words.length * 0.6 + 0.6),
                        curve: Motion.settle,
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

class _RisingWord extends StatelessWidget {
  const _RisingWord({
    required this.word,
    required this.style,
    required this.animation,
  });

  final String word;
  final TextStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: animation,
        child: Text(word, style: style),
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, 1.05 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Monospace label that resolves from hex noise, left to right.
class ScrambleText extends StatelessWidget {
  const ScrambleText(this.text, {super.key, required this.style});

  static const _glyphs = '0123456789abcdef';

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: _OnceVisible(
          duration: Duration(
            milliseconds: math.min(1300, 450 + text.length * 26),
          ),
          delay: Duration.zero,
          builder: (context, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final resolved = (animation.value * text.length * 1.15).floor();
              final frame = (animation.value * 26).floor();
              final chars = List.generate(text.length, (i) {
                final c = text[i];
                if (i < resolved || c == ' ') return c;
                return _glyphs[(i * 7 + frame * 13) % _glyphs.length];
              });
              return Text(chars.join(), style: style);
            },
          ),
        ),
      ),
    );
  }
}

/// A clock in seconds that only advances while its child is on screen.
/// [speed] eases toward a new rate instead of jumping to it.
class LiveClock extends StatefulWidget {
  const LiveClock({super.key, required this.builder, this.speed = 1});

  final Widget Function(BuildContext, ValueNotifier<double>) builder;
  final double speed;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock>
    with SingleTickerProviderStateMixin {
  // Starting mid-cycle means a still frame is never an empty visualization.
  final _time = ValueNotifier<double>(24);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  late double _speed = widget.speed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      _speed += (widget.speed - _speed) * (1 - math.exp(-dt * 5));
      _time.value += dt * _speed;
    });
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
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewportSignal(
      onChanged: _onVisible,
      child: widget.builder(context, _time),
    );
  }
}

/// Link whose amber fill wipes in on hover or keyboard focus.
class WipeLink extends StatefulWidget {
  const WipeLink({
    super.key,
    required this.onTap,
    required this.child,
    this.outlined = true,
  });

  final VoidCallback onTap;
  final Widget Function(Color foreground) child;
  final bool outlined;

  @override
  State<WipeLink> createState() => _WipeLinkState();
}

class _WipeLinkState extends State<WipeLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final active = _hover || _focus;
    return Semantics(
      button: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: active ? 1 : 0),
            duration: const Duration(milliseconds: 380),
            curve: Motion.settle,
            builder: (context, value, _) {
              final foreground = Color.lerp(
                Palette.paper,
                Palette.ink,
                value,
              )!;
              return DecoratedBox(
                decoration: BoxDecoration(
                  border: widget.outlined
                      ? Border.all(
                          color: Color.lerp(
                            Palette.line,
                            Palette.amber,
                            value,
                          )!,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0, 1),
                          heightFactor: 1,
                          child: const ColoredBox(color: Palette.amber),
                        ),
                      ),
                    ),
                    widget.child(foreground),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Eyebrow and title shared by every section after the hero.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.address,
    required this.label,
    required this.title,
  });

  final String address;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = (width * 0.062).clamp(38.0, 84.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScrambleText(
          '$address  $label',
          style: Fonts.mono(13, color: Palette.amber, tracking: 0.04),
        ),
        const SizedBox(height: 18),
        // The tall line height keeps descenders inside each word's clip.
        RisingTitle(
          title,
          style: Fonts.display(size, wght: 780, wdth: 92, height: 1.2),
        ),
      ],
    );
  }
}

class SectionFrame extends StatelessWidget {
  const SectionFrame({super.key, required this.child, this.top = 140});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) {
    final gutter = Layout.gutter(MediaQuery.sizeOf(context).width);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.color = Palette.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: Palette.line)),
      child: Text(text, style: Fonts.mono(12, color: color)),
    );
  }
}
