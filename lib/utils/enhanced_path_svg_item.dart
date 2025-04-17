import 'package:flutter/material.dart';
import 'svg_parser.dart';

class EnhancedPathSvgItem {
  final PathSvgItem originalItem;

  EnhancedPathSvgItem(this.originalItem);

  Color? get fill => originalItem.fill;

  EnhancedPathSvgItem copyWith({PathSvgItem? originalItem}) {
    return EnhancedPathSvgItem(originalItem ?? this.originalItem);
  }
}
