import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'data/portfolio_data.dart';
import 'sections/about_section.dart';
import 'sections/contact_section.dart';
import 'sections/experience_section.dart';
import 'sections/hero_section.dart';
import 'sections/projects_section.dart';
import 'sections/stack_section.dart';
import 'theme.dart';
import 'widgets/boot_overlay.dart';
import 'widgets/motion.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const _links = ['home', 'about', 'stack', 'projects', 'trace', 'contact'];

  final _scroll = ScrollController();
  final _keys = List.generate(_links.length, (_) => GlobalKey());
  final _active = ValueNotifier<int>(0);
  final _revealed = ValueNotifier<bool>(false);
  final _nearBottom = ValueNotifier<bool>(false);

  late final Ticker _wheelTicker;
  double _wheelTarget = 0;
  Duration _wheelLast = Duration.zero;

  @override
  void initState() {
    super.initState();
    _wheelTicker = createTicker(_onWheelTick);
    _scroll.addListener(_updateActive);
    _scroll.addListener(_updateNearBottom);
  }

  @override
  void dispose() {
    _wheelTicker.dispose();
    _scroll.dispose();
    _active.dispose();
    _revealed.dispose();
    _nearBottom.dispose();
    super.dispose();
  }

  void _updateActive() {
    final probe = MediaQuery.sizeOf(context).height * 0.4;
    var active = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      if (box.localToGlobal(Offset.zero).dy <= probe) active = i;
    }
    _active.value = active;
  }

  void _updateNearBottom() {
    final position = _scroll.position;
    _nearBottom.value =
        position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 120;
  }

  /// Mouse wheels jump in big notches on the web, so they are eased here.
  /// Touch and trackpad drags still go through the scroll view directly.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scroll.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      final delta = (resolved as PointerScrollEvent).scrollDelta.dy;
      final position = _scroll.position;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(
          (position.pixels + delta).clamp(0.0, position.maxScrollExtent),
        );
        return;
      }
      final base = _wheelTicker.isActive ? _wheelTarget : position.pixels;
      _wheelTarget = (base + delta).clamp(0.0, position.maxScrollExtent);
      if (!_wheelTicker.isActive) {
        _wheelLast = Duration.zero;
        _wheelTicker.start();
      }
    });
  }

  void _onWheelTick(Duration elapsed) {
    final dt = (elapsed - _wheelLast).inMicroseconds / 1e6;
    _wheelLast = elapsed;
    if (!_scroll.hasClients) return;
    final pixels = _scroll.position.pixels;
    final next = pixels + (_wheelTarget - pixels) * (1 - math.exp(-dt * 13));
    if ((_wheelTarget - next).abs() < 0.5) {
      _scroll.jumpTo(_wheelTarget);
      _wheelTicker.stop();
    } else {
      _scroll.jumpTo(next);
    }
  }

  void _goTo(int index) {
    final box = _keys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scroll.hasClients) return;
    _wheelTicker.stop();
    final position = _scroll.position;
    final target = (position.pixels + box.localToGlobal(Offset.zero).dy - 40)
        .clamp(0.0, position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: _scroll,
              child: Listener(
                // Without this, the wheel over empty space goes straight to
                // the scroll view and fights the easing in _onWheelTick.
                behavior: HitTestBehavior.opaque,
                onPointerSignal: _onPointerSignal,
                child: Focus(
                  autofocus: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Scrolling repaints the viewport. Giving each section
                      // its own layer stops that re-recording the whole page.
                      RepaintBoundary(
                        child: HeroSection(
                          key: _keys[0],
                          scroll: _scroll,
                          revealed: _revealed,
                          onNavigate: _goTo,
                        ),
                      ),
                      RepaintBoundary(child: AboutSection(key: _keys[1])),
                      RepaintBoundary(child: StackSection(key: _keys[2])),
                      RepaintBoundary(child: ProjectsSection(key: _keys[3])),
                      RepaintBoundary(child: ExperienceSection(key: _keys[4])),
                      RepaintBoundary(child: ContactSection(key: _keys[5])),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: _TopBar(
                scroll: _scroll,
                active: _active,
                links: _links,
                onNavigate: _goTo,
              ),
            ),
          ),
          _BackToTop(visible: _nearBottom, onTap: () => _goTo(0)),
          if (showSampleBanner)
            const Positioned(right: 12, bottom: 12, child: _SampleBanner()),
          Positioned.fill(
            child: RepaintBoundary(
              child: BootOverlay(onReveal: () => _revealed.value = true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.scroll,
    required this.active,
    required this.links,
    required this.onNavigate,
  });

  final ScrollController scroll;
  final ValueNotifier<int> active;
  final List<String> links;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.ink, Palette.ink.withValues(alpha: 0)],
          stops: const [0.55, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: scroll,
            builder: (context, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _progress(scroll),
                child: Container(height: 2, color: Palette.amber),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Layout.gutter(width),
              compact ? 10 : 18,
              Layout.gutter(width),
              compact ? 22 : 30,
            ),
            child: Row(
              children: [
                if (!compact) ...[
                  Text(
                    initials,
                    style: Fonts.display(20, wght: 900, wdth: 120),
                  ),
                  const Spacer(),
                ],
                Expanded(
                  flex: compact ? 1 : 0,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: compact
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: ValueListenableBuilder(
                      valueListenable: active,
                      builder: (context, current, _) => Row(
                        children: [
                          for (var i = 1; i < links.length; i++)
                            _NavLink(
                              label: links[i],
                              active: current == i,
                              onTap: () => onNavigate(i),
                            ),
                        ],
                      ),
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

  double _progress(ScrollController scroll) {
    if (!scroll.hasClients || !scroll.position.hasContentDimensions) return 0;
    final max = scroll.position.maxScrollExtent;
    return max <= 0 ? 0 : (scroll.position.pixels / max).clamp(0.0, 1.0);
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final lit = widget.active || _hover;
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _hover = v),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: Fonts.mono(
                    13,
                    color: lit ? Palette.paper : Palette.muted,
                  ),
                  child: Text(widget.label),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  curve: Motion.settle,
                  width: widget.active ? 22 : 0,
                  height: 2,
                  color: Palette.amber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades in at the end of the page. On narrow screens the footer text wraps
/// across the full width, so the button sits in the gap above it instead.
class _BackToTop extends StatelessWidget {
  const _BackToTop({required this.visible, required this.onTap});

  final ValueListenable<bool> visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
    return Positioned(
      right: Layout.gutter(width),
      bottom: width < 720 ? 88 : 14,
      child: ValueListenableBuilder(
        valueListenable: visible,
        builder: (context, shown, child) => IgnorePointer(
          ignoring: !shown,
          child: ExcludeFocus(
            excluding: !shown,
            child: ExcludeSemantics(
              excluding: !shown,
              child: AnimatedSlide(
                offset: shown ? Offset.zero : const Offset(0, 0.4),
                duration: duration,
                curve: Motion.settle,
                child: AnimatedOpacity(
                  opacity: shown ? 1 : 0,
                  duration: duration,
                  curve: Motion.settle,
                  child: child,
                ),
              ),
            ),
          ),
        ),
        child: ColoredBox(
          color: Palette.ink,
          child: WipeLink(
            onTap: onTap,
            child: (foreground) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Text(
                '^ back to top',
                style: Fonts.mono(13, color: foreground, wght: 500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SampleBanner extends StatelessWidget {
  const _SampleBanner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: Palette.coral,
        child: Text(
          'Sample content: edit lib/data/portfolio_data.dart',
          style: Fonts.mono(11, color: Palette.ink, wght: 600),
        ),
      ),
    );
  }
}
