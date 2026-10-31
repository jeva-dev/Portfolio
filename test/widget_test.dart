import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/frame_cap.dart';
import 'package:portfolio/main.dart';
import 'package:portfolio/sections/hero_section.dart';
import 'package:portfolio/widgets/boot_overlay.dart';
import 'package:portfolio/widgets/memory_field.dart';

void main() {
  const sizes = {
    'phone': Size(360, 780),
    'tablet': Size(820, 1100),
    'desktop': Size(1440, 900),
  };

  for (final entry in sizes.entries) {
    testWidgets('lays out without overflow on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const PortfolioApp());
      // Past the 2.5s boot sequence, so the overlay removes itself.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);

      // Scroll the whole page so every reveal runs.
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('survives a window resize', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pump(const Duration(seconds: 3));

    tester.view.physicalSize = const Size(1000, 700);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion skips boot and stops every ticker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(BootOverlay), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BootOverlay),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kinetic name survives its text changing', (tester) async {
    final input = FieldInput();
    addTearDown(input.dispose);

    Widget name(List<String> lines) => MaterialApp(
      home: SingleChildScrollView(
        child: KineticName(
          lines: lines,
          input: input,
          intro: kAlwaysCompleteAnimation,
          fontSize: 40,
        ),
      ),
    );

    // The same update a hot reload makes after editing nameLines.
    await tester.pumpWidget(name(const ['Your', 'Name']));
    await tester.pumpWidget(name(const ['Jeva', 'Vignesh']));
    expect(tester.takeException(), isNull);
    expect(find.text('H'), findsOneWidget);

    await tester.pumpWidget(name(const ['Ab']));
    expect(tester.takeException(), isNull);
    expect(find.text('H'), findsNothing);
  });

  test('frame gate holds any display to 60 FPS', () {
    int admitted(double hz) {
      final gate = FrameGate();
      final frames = (hz * 10).round();
      var count = 0;
      for (var i = 0; i < frames; i++) {
        final at = Duration(microseconds: (i * 1e6 / hz).round());
        if (gate.admit(at)) count++;
      }
      return count;
    }

    expect(admitted(60), closeTo(600, 1));
    expect(admitted(75), closeTo(600, 10));
    expect(admitted(120), closeTo(600, 10));
    expect(admitted(144), closeTo(600, 10));
    expect(admitted(240), closeTo(600, 10));
    // A display slower than the cap keeps every frame it can show.
    expect(admitted(30), closeTo(300, 1));
  });

  testWidgets('terminal runs commands', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pump(const Duration(seconds: 3));

    final scrollable = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump(const Duration(seconds: 2));

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('nope: command not found'), findsOneWidget);
  });

  testWidgets('projects have no source links', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Zstd 4-bit SIMD'), findsOneWidget);
    expect(find.text('RDK-B Gateway'), findsOneWidget);
    expect(find.text('Log Analysis RAG'), findsOneWidget);
    expect(find.textContaining('View source'), findsNothing);
  });

  testWidgets('wheel over empty space does not fight the easing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pump(const Duration(seconds: 3));

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(position.maxScrollExtent * 0.6);
    await tester.pump(const Duration(seconds: 2));
    final start = position.pixels;

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    Future<void> wheel(Offset at, double dy) async {
      pointer.hover(at);
      await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Down over content starts the easing, then up over the left gutter.
    await wheel(const Offset(720, 450), 300);
    for (var i = 0; i < 10; i++) {
      await wheel(const Offset(5, 450), -100);
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(position.pixels, closeTo(start - 700, 1));
  });

  for (final entry in sizes.entries) {
    testWidgets('back to top button works on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const PortfolioApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));

      final button = find.text('^ back to top');
      bool ignored() => tester
          .widget<IgnorePointer>(
            find.ancestor(of: button, matching: find.byType(IgnorePointer)).first,
          )
          .ignoring;
      expect(ignored(), isTrue);

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump(const Duration(seconds: 2));
      expect(ignored(), isFalse);

      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(position.pixels, 0);
      expect(ignored(), isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
