// ------------------ svg_painter.dart ------------------
import 'package:flutter/material.dart';
import '../utils/svg_parser.dart';

class SvgPainter extends CustomPainter {
  const SvgPainter({
    required this.items,
    this.onTap,
  });

  final List<PathSvgItem> items;
  final Function(int)? onTap;

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in items) {
      final fillPaint = Paint()
        ..color = item.fill ?? Colors.transparent
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = item.stroke ?? Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = item.strokeWidth;

      if (!item.path.getBounds().isEmpty) {
        canvas.drawPath(item.path, fillPaint);
        canvas.drawPath(item.path, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SvgPainter oldDelegate) {
    return items != oldDelegate.items;
  }
}

class SvgPainterImage extends StatelessWidget {
  const SvgPainterImage({
    super.key,
    required this.item,
    required this.index,
    this.onTap,
  });

  final PathSvgItem item;
  final int index;
  final Function(int)? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap?.call(index),
      child: SizedBox.expand(
        child: CustomPaint(
          painter: SvgPainter(
            items: [item],
            onTap: onTap == null ? null : (i) => onTap!(index),
          ),
        ),
      ),
    );
  }
}