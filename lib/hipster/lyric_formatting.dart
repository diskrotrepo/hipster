part of '../main.dart';

class BracketColorText extends StatelessWidget {
  const BracketColorText({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final expr = RegExp(r'(\[.*?]|\(.*?\))');
    final spans = <InlineSpan>[];

    text.splitMapJoin(
      expr,
      onMatch: (m) {
        final chunk = m.group(0)!;
        spans.add(
          TextSpan(
            text: chunk,
            style: TextStyle(
              color: chunk.startsWith('[')
                  ? Colors.pinkAccent
                  : Colors.lightBlueAccent,
            ),
          ),
        );
        return '';
      },
      onNonMatch: (n) {
        spans.add(
          TextSpan(
            text: n,
            style: const TextStyle(color: Colors.white),
          ),
        );
        return '';
      },
    );

    return SelectableText.rich(
      TextSpan(style: const TextStyle(fontSize: 16), children: spans),
      textAlign: TextAlign.left,
    );
  }
}
