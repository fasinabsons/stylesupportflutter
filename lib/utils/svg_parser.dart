import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'svg_geometry_parser.dart';

class VectorImage {
  final List<PathSvgItem> items;
  final Size? size;
  const VectorImage({required this.items, this.size});
}

class PathSvgItem {
  final Path path;
  final Color? fill;
  final Color? stroke;
  final double strokeWidth;
  final SvgGeometry? geometry;

  const PathSvgItem({
    required this.path,
    this.fill,
    this.stroke,
    this.strokeWidth = 1.5,
    this.geometry,
  });

  PathSvgItem copyWith({
    Path? path,
    Color? fill,
    Color? stroke,
    double? strokeWidth,
  }) {
    return PathSvgItem(
      path: path ?? this.path,
      fill: fill ?? this.fill,
      stroke: stroke ?? this.stroke,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      geometry: geometry,
    );
  }
}

Future<VectorImage> getVectorImageFromAsset(String assetPath) async {
  final svgData = await rootBundle.loadString(assetPath);
  return getVectorImageFromStringXml(svgData);
}

VectorImage getVectorImageFromStringXml(String svgString) {
  final document = XmlDocument.parse(svgString);
  final svgElement = document.findAllElements('svg').firstOrNull;
  if (svgElement == null) return const VectorImage(items: [], size: Size(300, 400));

  final styleMap = _parseStyleSheet(document);
  final size = _parseSvgSize(svgElement);
  final List<PathSvgItem> items = [];
  final defs = <String, XmlElement>{};

  for (final def in document.findAllElements('defs')) {
    for (final element in def.findElements('*')) {
      final id = element.getAttribute('id');
      if (id != null) defs[id] = element;
    }
  }

  void extract(XmlElement element, Matrix4 transform) {
    final tag = element.name.local;
    final newTransform = transform.clone()..multiply(_parseTransform(element));

    if (tag == 'g') {
      for (final child in element.children.whereType<XmlElement>()) {
        extract(child, newTransform);
      }
    } else if (tag == 'use') {
      final href = element.getAttribute('xlink:href') ?? element.getAttribute('href');
      if (href != null) {
        final id = href.replaceAll('#', '');
        final referenced = defs[id];
        if (referenced != null) extract(referenced, newTransform);
      }
    } else {
      final path = _parseToPath(element);
      if (path != null) {
        final transformedPath = path.transform(newTransform.storage);
        items.add(_buildPathSvgItem(element, transformedPath, styleMap));
      }
    }
  }

  extract(svgElement, Matrix4.identity());
  return VectorImage(items: items, size: size);
}

Map<String, Map<String, String>> _parseStyleSheet(XmlDocument doc) {
  final Map<String, Map<String, String>> styles = {};
  for (final style in doc.findAllElements('style')) {
    final content = style.innerText;
    final rules = RegExp(r'\.([^\{]+)\s*\{([^}]+)\}').allMatches(content);
    for (final rule in rules) {
      final className = rule.group(1)?.trim();
      final declarations = rule.group(2)?.split(';').where((s) => s.trim().isNotEmpty);
      if (className != null && declarations != null) {
        final map = <String, String>{};
        for (final decl in declarations) {
          final parts = decl.split(':');
          if (parts.length == 2) map[parts[0].trim()] = parts[1].trim();
        }
        styles[className] = map;
      }
    }
  }
  return styles;
}

PathSvgItem _buildPathSvgItem(XmlElement el, Path path, Map<String, Map<String, String>> styleMap) {
  final Map<String, String> merged = {};
  final className = el.getAttribute('class');
  if (className != null) {
    for (final cls in className.split(' ')) {
      merged.addAll(styleMap[cls.trim()] ?? {});
    }
  }

  final styleAttr = el.getAttribute('style');
  if (styleAttr != null) {
    for (final entry in styleAttr.split(';')) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        merged[parts[0].trim()] = parts[1].trim();
      }
    }
  }

  final fill = _parseColor(el.getAttribute('fill') ?? merged['fill']);
  final stroke = _parseColor(el.getAttribute('stroke') ?? merged['stroke']);
  final strokeWidth = double.tryParse(el.getAttribute('stroke-width') ?? merged['stroke-width'] ?? '') ?? 1.5;
  final id = el.getAttribute('id');

  return PathSvgItem(
    path: path,
    fill: fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
    geometry: SvgGeometryParser.parse(path, id: id, className: className),
  );
}

Path? _parseToPath(XmlElement el) {
  final tag = el.name.local;
  switch (tag) {
    case 'path':
      final d = el.getAttribute('d');
      return d != null ? parseSvgPathData(d) : null;
    case 'rect':
      final x = double.tryParse(el.getAttribute('x') ?? '0') ?? 0;
      final y = double.tryParse(el.getAttribute('y') ?? '0') ?? 0;
      final w = double.tryParse(el.getAttribute('width') ?? '0') ?? 0;
      final h = double.tryParse(el.getAttribute('height') ?? '0') ?? 0;
      return Path()..addRect(Rect.fromLTWH(x, y, w, h));
    case 'circle':
      final cx = double.tryParse(el.getAttribute('cx') ?? '0') ?? 0;
      final cy = double.tryParse(el.getAttribute('cy') ?? '0') ?? 0;
      final r = double.tryParse(el.getAttribute('r') ?? '0') ?? 0;
      return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    case 'ellipse':
      final cx = double.tryParse(el.getAttribute('cx') ?? '0') ?? 0;
      final cy = double.tryParse(el.getAttribute('cy') ?? '0') ?? 0;
      final rx = double.tryParse(el.getAttribute('rx') ?? '0') ?? 0;
      final ry = double.tryParse(el.getAttribute('ry') ?? '0') ?? 0;
      return Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
    case 'polygon':
    case 'polyline':
      final raw = el.getAttribute('points');
      if (raw == null) return null;
      final path = Path();
      final points = raw.split(RegExp(r'[ ,]+')).map(double.tryParse).toList();
      if (points.length >= 4) {
        path.moveTo(points[0]!, points[1]!);
        for (int i = 2; i < points.length; i += 2) {
          if (i + 1 < points.length) {
            path.lineTo(points[i]!, points[i + 1]!);
          }
        }
        if (tag == 'polygon') path.close();
      }
      return path;
    case 'line':
      final x1 = double.tryParse(el.getAttribute('x1') ?? '0') ?? 0;
      final y1 = double.tryParse(el.getAttribute('y1') ?? '0') ?? 0;
      final x2 = double.tryParse(el.getAttribute('x2') ?? '0') ?? 0;
      final y2 = double.tryParse(el.getAttribute('y2') ?? '0') ?? 0;
      return Path()..moveTo(x1, y1)..lineTo(x2, y2);
  }
  return null;
}

Matrix4 _parseTransform(XmlElement element) {
  final value = element.getAttribute('transform');
  final matrix = Matrix4.identity();
  if (value == null) return matrix;

  final commands = value.split(')').where((e) => e.trim().isNotEmpty);
  for (final command in commands) {
    if (command.contains('translate')) {
      final nums = _parseNumbers(command);
      matrix.translate(nums[0], nums.length > 1 ? nums[1] : 0);
    } else if (command.contains('scale')) {
      final nums = _parseNumbers(command);
      matrix.scale(nums[0], nums.length > 1 ? nums[1] : nums[0]);
    } else if (command.contains('rotate')) {
      final nums = _parseNumbers(command);
      final angle = nums[0] * pi / 180;
      if (nums.length > 2) {
        matrix.translate(nums[1], nums[2]);
        matrix.rotateZ(angle);
        matrix.translate(-nums[1], -nums[2]);
      } else {
        matrix.rotateZ(angle);
      }
    }
  }
  return matrix;
}

List<double> _parseNumbers(String input) {
  final matches = RegExp(r'[-+]?[0-9]*\.?[0-9]+').allMatches(input);
  return matches.map((m) => double.parse(m.group(0)!)).toList();
}

Color? _parseColor(String? value) {
  if (value == null || value == 'none') return null;
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    final fullHex = hex.length == 3
        ? hex.split('').map((c) => '$c$c').join()
        : hex;
    return Color(int.parse('FF$fullHex', radix: 16));
  }
  return Colors.black;
}

Size? _parseSvgSize(XmlElement svgElement) {
  final viewBox = svgElement.getAttribute('viewBox');
  if (viewBox != null) {
    final values = viewBox.split(RegExp(r'[ ,]+')).map(double.tryParse).toList();
    if (values.length == 4 && values.every((e) => e != null)) {
      return Size(values[2]!, values[3]!);
    }
  }
  return null;
}
