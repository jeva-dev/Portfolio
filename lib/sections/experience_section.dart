import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme.dart';
import '../widgets/motion.dart';

/// Work history, presented as a debugger backtrace with the current role on
/// top. Frames count down, so the first job is always frame #0.
class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionFrame(
      top: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            address: '0x40',
            label: 'trace',
            title: 'How I got here.',
          ),
          const SizedBox(height: 40),
          ScrambleText(
            '(gdb) backtrace',
            style: Fonts.mono(15, color: Palette.paper),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < jobs.length; i++)
            Reveal(
              delay: Duration(milliseconds: 110 * i),
              child: _Frame(job: jobs[i], index: i),
            ),
        ],
      ),
    );
  }
}

class _Frame extends StatefulWidget {
  const _Frame({required this.job, required this.index});

  final Job job;
  final int index;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final width = MediaQuery.sizeOf(context).width;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Motion.settle,
        padding: EdgeInsets.fromLTRB(
          _hover && width >= 600 ? 30 : 18,
          22,
          18,
          22,
        ),
        decoration: BoxDecoration(
          color: _hover ? Palette.panel : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: widget.index == 0 || _hover ? Palette.amber : Palette.line,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: Fonts.mono(14),
                children: [
                  TextSpan(
                    text: '#${jobs.length - 1 - widget.index}  ',
                    style: const TextStyle(color: Palette.amber),
                  ),
                  TextSpan(
                    text: job.company,
                    style: const TextStyle(color: Palette.teal),
                  ),
                  TextSpan(
                    text: '::${job.title}',
                    style: const TextStyle(color: Palette.paper),
                  ),
                  TextSpan(text: ' (${job.period})'),
                ],
              ),
            ),
            for (final section in job.sections) _SectionBlock(section: section),
          ],
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final JobSection section;

  @override
  Widget build(BuildContext context) {
    final heading = section.heading;
    final client = section.client;
    final summary = section.summary;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null)
              Text('// $heading', style: Fonts.mono(14, color: Palette.amber)),
            if (client != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('client = $client', style: Fonts.mono(13)),
              ),
            if (summary != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(summary, style: Fonts.body(17)),
              ),
            if (heading != null || summary != null) const SizedBox(height: 12),
            for (final point in section.points) _Point(text: point),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              '>',
              style: Fonts.mono(14, color: Palette.teal, height: 1.85),
            ),
          ),
          Expanded(
            child: Text(text, style: Fonts.body(16, color: Palette.muted)),
          ),
        ],
      ),
    );
  }
}
