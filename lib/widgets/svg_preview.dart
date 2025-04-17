import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgPreview extends StatelessWidget {
  final String svgPath;
  final bool applyGreyFilter;
  final double width;
  final double height;
  final bool isFromAsset;

  const SvgPreview({
    super.key,
    required this.svgPath,
    this.applyGreyFilter = false,
    this.width = 50,
    this.height = 50,
    this.isFromAsset = true,
  });

  @override
  Widget build(BuildContext context) {
    final ColorFilter? colorFilter = applyGreyFilter
        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
        : null;

    final Widget svg = isFromAsset
        ? SvgPicture.asset(
            svgPath,
            width: width,
            height: height,
            fit: BoxFit.contain,
            colorFilter: colorFilter,
            placeholderBuilder: (context) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
            allowDrawingOutsideViewBox: true,
          )
        : SvgPicture.string(
            svgPath,
            width: width,
            height: height,
            fit: BoxFit.contain,
            colorFilter: colorFilter,
            placeholderBuilder: (context) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
            allowDrawingOutsideViewBox: true,
          );

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: svg,
      ),
    );
  }
}
