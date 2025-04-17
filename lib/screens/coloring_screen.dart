import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/coloring_page.dart';
import '../utils/history_manager.dart';
import '../utils/progress_manager.dart';
import '../utils/svg_parser.dart';
import '../widgets/color_palette.dart';
import '../widgets/svg_painter.dart';
import '../utils/enhanced_path_svg_item.dart';

class ColoringScreen extends StatefulWidget {
  final ColoringPage page;
  const ColoringScreen({super.key, required this.page});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen>
    with SingleTickerProviderStateMixin, HistoryManager<List<EnhancedPathSvgItem>> {
  Size? _size;
  List<EnhancedPathSvgItem> _items = [];
  Color selectedColor = Colors.red;
  bool showFunFact = false;
  late ConfettiController _confettiController;
  late ProgressManager _progressManager;
  int? _highlightedIndex;
  late AnimationController _highlightAnimation;
  late Animation<double> _highlightOpacity;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _highlightAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _highlightOpacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _highlightAnimation, curve: Curves.easeInOut),
    );
    _progressManager = ProgressManager();
    _init();
  }

  Future<void> _init() async {
    try {
      final vectorImage = await getVectorImageFromAsset(widget.page.svgPath);
      _size = vectorImage.size;
      _items = vectorImage.items.map((item) => EnhancedPathSvgItem(item)).toList();
      widget.page.partsCount = _items.length;
      saveToHistory(_items);
      _highlightedIndex = _findNextUncoloredIndex();
      await _progressManager.loadProgress();
      _progressManager.applySavedColors(_items, widget.page.id, setState);
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing coloring page: $e');
      setState(() => _size = const Size(300, 400));
    }
  }

  void _onTap(int index) {
    saveToHistory(_items);
    setState(() {
      final old = _items[index];
      _items[index] = old.copyWith(
        originalItem: old.originalItem.copyWith(fill: selectedColor),
      );
      if (_items.every((item) => item.fill != null)) {
        showFunFact = true;
        _progressManager.saveProgress(widget.page, _items);
        _confettiController.play();
      }
      _highlightedIndex = _findNextUncoloredIndex();
    });
  }

  int? _findNextUncoloredIndex() {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].fill == null) return i;
    }
    return null;
  }

  void _undo() {
    if (canUndo) {
      setState(() {
        _items = List.from(undo()!);
        _highlightedIndex = _findNextUncoloredIndex();
      });
    }
  }

  void _redo() {
    if (canRedo) {
      setState(() {
        _items = List.from(redo()!);
        _highlightedIndex = _findNextUncoloredIndex();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _highlightAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_size == null || _items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.page.category)),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: Center(
                    child: FittedBox(
                      child: SizedBox(
                        width: _size!.width,
                        height: _size!.height,
                        child: Stack(
                          children: [
                            for (int index = 0; index < _items.length; index++)
                              SvgPainterImage(
                                item: _items[index].originalItem,
                                index: index,
                                onTap: _onTap,
                              ),
                            if (_highlightedIndex != null)
                              AnimatedBuilder(
                                animation: _highlightOpacity,
                                builder: (context, child) => CustomPaint(
                                  painter: HighlightPainter(
                                    path: _items[_highlightedIndex!].originalItem.path,
                                    opacity: _highlightOpacity.value,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.redo), onPressed: _redo),
                  ],
                ),
              ),
              ColorPalette(
                onColorSelected: (color) {
                  setState(() {
                    selectedColor = color;
                    for (int i = 0; i < _items.length; i++) {
                      if (_items[i].fill == null) {
                        _items[i] = _items[i].copyWith(
                          originalItem: _items[i].originalItem.copyWith(fill: color.withValues(alpha:0.2)),
                        );
                      }
                    }
                  });
                },
                selectedColor: selectedColor,
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.pink, Colors.yellow, Colors.green, Colors.blue],
          ),
          if (showFunFact)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 40, color: Colors.amber),
                    Text(widget.page.funFact, style: const TextStyle(fontSize: 18)),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Library'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HighlightPainter extends CustomPainter {
  final Path path;
  final double opacity;

  const HighlightPainter({required this.path, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha:opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return opacity != oldDelegate.opacity || path != oldDelegate.path;
  }
}
