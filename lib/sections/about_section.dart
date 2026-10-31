import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme.dart';
import '../widgets/code_block.dart';
import '../widgets/motion.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Layout.wide;
    final prose = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < aboutParagraphs.length; i++)
          Reveal(
            delay: Duration(milliseconds: 80 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(aboutParagraphs[i], style: Fonts.body(19)),
            ),
          ),
      ],
    );
    const code = Reveal(
      child: TypedCode(source: engineerCode, filename: 'engineer.hpp'),
    );

    return SectionFrame(
      top: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            address: '0x10',
            label: 'about',
            title: 'Close to the metal, on purpose.',
          ),
          const SizedBox(height: 56),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: prose),
                const SizedBox(width: 64),
                const Expanded(flex: 6, child: code),
              ],
            )
          else ...[
            prose,
            const SizedBox(height: 16),
            code,
          ],
          const SizedBox(height: 64),
          Wrap(
            spacing: 56,
            runSpacing: 28,
            children: [
              for (var i = 0; i < stats.length; i++)
                Reveal(
                  delay: Duration(milliseconds: 90 * i),
                  child: _CountUp(stat: stats[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountUp extends StatefulWidget {
  const _CountUp({required this.stat});

  final Stat stat;

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.settle,
  );

  void _onVisible(bool visible) {
    if (!visible || _controller.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stat = widget.stat;
    return ViewportSignal(
      inset: 40,
      once: true,
      onChanged: _onVisible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _curve,
            builder: (context, _) => Text(
              '${(stat.value * _curve.value).round()}${stat.suffix}',
              style: Fonts.display(58, wght: 800, color: Palette.amber),
            ),
          ),
          const SizedBox(height: 6),
          Text(stat.label, style: Fonts.mono(13)),
        ],
      ),
    );
  }
}
