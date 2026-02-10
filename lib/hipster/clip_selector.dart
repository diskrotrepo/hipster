part of '../main.dart';

class RainbowSquares extends StatelessWidget {
  const RainbowSquares({
    super.key,
    required this.count,
    required this.onSelect,
    this.size = 14,
    this.spacing = 2,
    required this.selectedIndex,
  });

  final int count;
  final int selectedIndex;
  final double size, spacing;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(
        count,
        (i) => _HoverSquare(
          color: _colourAt(i),
          size: size,
          onSelect: () => onSelect(i),
        ),
      ),
    );
  }

  Color _colourAt(int index) {
    if (count <= 1) return const Color(0xFF8B00FF);
    const double start = 270, end = 360; // violet -> red
    final hue = start + (end - start) * index / (count - 1);

    if (selectedIndex >= 0 && selectedIndex == index) {
      return HSLColor.fromAHSL(1, 1, 1, 1).toColor();
    }

    return HSLColor.fromAHSL(1, hue % 360, 1, .5).toColor();
  }
}

class _HoverSquare extends StatefulWidget {
  const _HoverSquare({
    required this.color,
    required this.size,
    required this.onSelect,
  });

  final Color color;
  final double size;
  final VoidCallback onSelect;

  @override
  State<_HoverSquare> createState() => _HoverSquareState();
}

class _HoverSquareState extends State<_HoverSquare> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelect,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          color:
              _hover ? const Color.fromARGB(255, 252, 200, 231) : widget.color,
        ),
      ),
    );
  }
}
