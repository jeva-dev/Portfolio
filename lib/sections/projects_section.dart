import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/project_visuals.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            address: '0x30',
            label: 'projects',
            title: 'Selected work, running live.',
          ),
          const SizedBox(height: 14),
          Reveal(
            child: Text(
              MediaQuery.sizeOf(context).width >= Layout.wide
                  ? 'Each model below runs in real time. Hover to overclock it.'
                  : 'Each model below runs in real time.',
              style: Fonts.body(18, color: Palette.muted),
            ),
          ),
          const SizedBox(height: 60),
          for (var i = 0; i < projects.length; i++)
            _ProjectRow(project: projects[i], index: i),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatefulWidget {
  const _ProjectRow({required this.project, required this.index});

  final Project project;
  final int index;

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Layout.wide;
    final visual = Reveal(
      offset: Offset(wide ? (widget.index.isEven ? -48 : 48) : 0, 36),
      child: _VisualPanel(project: widget.project, hover: _hover),
    );
    final details = Reveal(
      delay: const Duration(milliseconds: 120),
      child: _Details(project: widget.project, index: widget.index),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: widget.index.isEven
                    ? [
                        Expanded(flex: 6, child: visual),
                        const SizedBox(width: 64),
                        Expanded(flex: 5, child: details),
                      ]
                    : [
                        Expanded(flex: 5, child: details),
                        const SizedBox(width: 64),
                        Expanded(flex: 6, child: visual),
                      ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [visual, const SizedBox(height: 28), details],
              ),
      ),
    );
  }
}

class _VisualPanel extends StatelessWidget {
  const _VisualPanel({required this.project, required this.hover});

  final Project project;
  final bool hover;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Motion.settle,
      decoration: BoxDecoration(
        color: Palette.panel,
        border: Border.all(color: hover ? Palette.amber : Palette.line),
      ),
      child: AspectRatio(
        aspectRatio: 1.45,
        child: RepaintBoundary(
          child: LiveClock(
            speed: hover ? 2.6 : 1,
            builder: (context, clock) => CustomPaint(
              painter: painterFor(project.visual, clock),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.project, required this.index});

  final Project project;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${(index + 1).toString().padLeft(2, '0')} / ${project.kicker}',
          style: Fonts.mono(13, color: Palette.amber),
        ),
        const SizedBox(height: 12),
        Text(project.title, style: Fonts.display(52, wght: 780, wdth: 90)),
        const SizedBox(height: 16),
        Text(project.summary, style: Fonts.body(17.5)),
        const SizedBox(height: 22),
        Wrap(
          spacing: 36,
          runSpacing: 16,
          children: [
            for (final (value, label) in project.metrics)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Fonts.display(30, wght: 720, color: Palette.teal),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: Fonts.mono(12)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final tag in project.tags) TagChip(tag)],
        ),
      ],
    );
  }
}
