import 'package:flutter/material.dart';

class ColorPalette extends StatelessWidget {
  const ColorPalette({
    super.key,
    required this.onColorSelected,
    required this.selectedColor,
  });

  final ValueChanged<Color> onColorSelected;
  final Color selectedColor;

  final List<Color> colors = const [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.lime,
    Color(0xFFFFD700), // Gold
    Color(0xFFC0C0C0), // Silver
    Color(0xFFCD7F32), // Bronze
    Color(0xFF4B0082), // Indigo
    Color(0xFF00FFFF), // Aqua
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ColorOption(
              color: color,
              isSelected: color.toARGB32() == selectedColor.toARGB32(),
              onTap: () => onColorSelected(color),
            ),
          );
        },
      ),
    );
  }
}

class ColorOption extends StatefulWidget {
  const ColorOption({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<ColorOption> createState() => _ColorOptionState();
}

class _ColorOptionState extends State<ColorOption> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isSelected
                ? Colors.white
                : isHovering
                    ? Colors.white.withValues(alpha:0.5)
                    : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            if (isHovering)
              BoxShadow(
                color: Colors.white.withValues(alpha:0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: widget.isSelected
              ? const Center(
                  child: Icon(Icons.check, size: 18, color: Colors.white),
                )
              : null,
        ),
      ),
    );
  }
}
