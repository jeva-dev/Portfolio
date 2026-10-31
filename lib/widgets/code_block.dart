import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// C++ source that types itself in when scrolled to. Untyped characters are
/// laid out but transparent, so the block never changes size while typing.
class TypedCode extends StatefulWidget {
  const TypedCode({super.key, required this.source, required this.filename});

  final String source;
  final String filename;

  @override
  State<TypedCode> createState() => _TypedCodeState();
}

class _TypedCodeState extends State<TypedCode>
    with SingleTickerProviderStateMixin {
  late final String _source = widget.source.trim();
  late final List<_Token> _tokens = _tokenize(_source);
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _source.length * 5),
  );
  bool _started = false;

  void _onVisible(bool visible) {
    if (!visible || _started) return;
    _started = true;
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

  List<InlineSpan> _spans(int typed) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final token in _tokens) {
      final end = at + token.text.length;
      if (end <= typed) {
        spans.add(TextSpan(text: token.text, style: TextStyle(color: token.color)));
      } else if (at >= typed) {
        spans.add(
          TextSpan(
            text: token.text,
            style: const TextStyle(color: Colors.transparent),
          ),
        );
      } else {
        final cut = typed - at;
        spans
          ..add(
            TextSpan(
              text: token.text.substring(0, cut),
              style: TextStyle(color: token.color),
            ),
          )
          ..add(
            TextSpan(
              text: token.text.substring(cut),
              style: const TextStyle(color: Colors.transparent),
            ),
          );
      }
      at = end;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(_source).length + 1;
    final style = Fonts.mono(14, color: Palette.paper, height: 1.65);
    return ViewportSignal(
      inset: 80,
      once: true,
      onChanged: _onVisible,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.panel,
          border: Border.all(color: Palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Palette.line)),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, color: Palette.amber),
                  const SizedBox(width: 10),
                  Text(widget.filename, style: Fonts.mono(12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 18),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      List.generate(lineCount, (i) => '${i + 1}').join('\n'),
                      textAlign: TextAlign.right,
                      style: style.copyWith(
                        color: Palette.muted.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(width: 18),
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final typed = (_controller.value * _source.length)
                              .floor();
                          return Text.rich(
                            TextSpan(style: style, children: _spans(typed)),
                            semanticsLabel: _source,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Token {
  const _Token(this.text, this.color);
  final String text;
  final Color color;
}

final _tokenPattern = RegExp(
  r'(//[^\n]*)'
  r'|("[^"\n]*")'
  r'|(#\w+|<[a-z_]+>(?=\n))'
  r'|\b(auto|const|constexpr|int|noexcept|requires|return|static|struct|decltype|once)\b'
  r'|\b(std|Engineer|string_view|movable)\b'
  r'|(\b\d+\b)'
  r'|(\[\[\w+\]\])',
);

List<_Token> _tokenize(String source) {
  final tokens = <_Token>[];
  var at = 0;
  for (final m in _tokenPattern.allMatches(source)) {
    if (m.start > at) {
      tokens.add(_Token(source.substring(at, m.start), Palette.paper));
    }
    final Color color;
    if (m[1] != null) {
      color = Palette.muted;
    } else if (m[2] != null || m[6] != null) {
      color = Palette.teal;
    } else if (m[3] != null || m[7] != null) {
      color = Palette.coral;
    } else if (m[4] != null) {
      color = Palette.amber;
    } else {
      color = Palette.teal;
    }
    tokens.add(_Token(m[0]!, color));
    at = m.end;
  }
  if (at < source.length) tokens.add(_Token(source.substring(at), Palette.paper));
  return tokens;
}
