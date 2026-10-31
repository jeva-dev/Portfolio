import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/portfolio_data.dart';
import '../theme.dart';
import '../widgets/motion.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Layout.wide;
    final links = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < contactLinks.length; i++)
          Reveal(
            delay: Duration(milliseconds: 80 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ContactRow(link: contactLinks[i]),
            ),
          ),
      ],
    );
    const terminal = Reveal(child: _Terminal());

    return SectionFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            address: '0x50',
            label: 'contact',
            title: 'Got a hot path that needs cooling?',
          ),
          const SizedBox(height: 52),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: links),
                const SizedBox(width: 48),
                const Expanded(flex: 6, child: terminal),
              ],
            )
          else ...[
            links,
            const SizedBox(height: 24),
            terminal,
          ],
          const SizedBox(height: 90),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Palette.line)),
            ),
            child: Text(
              '[Process exited with code 0]  $fullName, built with Flutter.',
              style: Fonts.mono(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.link});

  final ContactLink link;

  @override
  Widget build(BuildContext context) {
    return WipeLink(
      onTap: () => launchUrl(Uri.parse(link.url)),
      child: (foreground) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Text(
                link.label,
                style: Fonts.mono(12, color: foreground.withValues(alpha: 0.7)),
              ),
            ),
            Expanded(
              child: Text(
                link.value,
                style: Fonts.mono(15, color: foreground, wght: 500),
              ),
            ),
            Text('->', style: Fonts.mono(15, color: foreground)),
          ],
        ),
      ),
    );
  }
}

/// A small working shell, for visitors who would rather type than click.
class _Terminal extends StatefulWidget {
  const _Terminal();

  @override
  State<_Terminal> createState() => _TerminalState();
}

class _TerminalState extends State<_Terminal> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final List<(String, Color)> _lines = [
    ('Type "help" and press Enter.', Palette.muted),
  ];

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run(String raw) {
    final command = raw.trim().toLowerCase();
    setState(() {
      _lines.add(('\$ $raw', Palette.paper));
      switch (command) {
        case '':
          break;
        case 'help':
          _lines.add((
            'whoami  projects  skills  contact  clear',
            Palette.teal,
          ));
        case 'whoami':
          _lines.add(('$fullName, $role, $location', Palette.muted));
        case 'projects':
          for (final p in projects) {
            _lines.add(('${p.title}  ${p.kicker}', Palette.muted));
          }
        case 'skills':
          for (final l in stackLayers) {
            _lines.add(('${l.name}: ${l.skills.take(3).join(', ')}', Palette.muted));
          }
        case 'contact':
          for (final l in contactLinks) {
            _lines.add(('${l.label}: ${l.value}', Palette.muted));
          }
        case 'clear':
          _lines.clear();
        case 'sudo rm -rf /':
          _lines.add(('Nice try. This heap is managed.', Palette.coral));
        default:
          _lines.add(('$command: command not found', Palette.coral));
      }
    });
    _input.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final style = Fonts.mono(14, color: Palette.paper);
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Palette.panel,
          border: Border.all(color: Palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned to the end, and not user-scrollable, so the mouse wheel
            // keeps moving the page while the pointer is over the terminal.
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (text, color) in _lines)
                        Text(text, style: style.copyWith(color: color)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('\$ ', style: style.copyWith(color: Palette.amber)),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    onSubmitted: _run,
                    style: style,
                    cursorWidth: 8,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'help',
                      hintStyle: TextStyle(color: Palette.muted),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
