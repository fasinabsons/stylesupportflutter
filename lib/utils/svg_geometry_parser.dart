import 'package:flutter/material.dart';

class SvgGeometry {
  const SvgGeometry({
    required this.vertices,
    required this.lines,
    required this.isClosed,
    this.id,
    this.className,
  });

  final List<Offset> vertices;
  final List<LineSegment> lines;
  final bool isClosed;

  final String? id;
  final String? className;
}

class LineSegment {
  const LineSegment(this.start, this.end);
  final Offset start;
  final Offset end;
}

class SvgGeometryParser {
  static SvgGeometry parse(Path path, {String? id, String? className}) {
    final metrics = path.computeMetrics(forceClosed: false);
    final vertices = <Offset>[];
    final lines = <LineSegment>[];
    Offset? lastPosition;
    bool isClosed = false;

    for (final metric in metrics) {
      isClosed = metric.isClosed;
      for (double t = 0; t <= metric.length; t += 5.0) {
        final tangent = metric.getTangentForOffset(t);
        if (tangent == null) continue;
        final position = tangent.position;
        vertices.add(position);
        if (lastPosition != null) {
          lines.add(LineSegment(lastPosition, position));
        }
        lastPosition = position;
      }
    }

    return SvgGeometry(
      vertices: vertices,
      lines: lines,
      isClosed: isClosed,
      id: id,
      className: className,
    );
  }
}
