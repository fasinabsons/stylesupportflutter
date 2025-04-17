// models/coloring_page.dart

class ColoringPage {
  final String id;
  final String category;
  final String svgPath;
  final String funFact;
  final bool isNumbered;
  int partsCount;

  ColoringPage({
    required this.id,
    required this.category,
    required this.svgPath,
    required this.funFact,
    required this.isNumbered,
    this.partsCount = 0, // Updated dynamically when parsing SVG
  });

  @override
  String toString() {
    return 'ColoringPage(id: $id, category: $category, partsCount: $partsCount)';
  }
}

final Map<String, List<ColoringPage>> pagesByCategory = {
  'Animals': [
    ColoringPage(
      id: '1',
      category: 'Animals',
      svgPath: 'assets/coloring_pages/parrot.svg',
      funFact: 'Parrots can live up to 50 years and are known for mimicking sounds!',
      isNumbered: true,
    ),
    ColoringPage(
      id: '2',
      category: 'Animals',
      svgPath: 'assets/coloring_pages/unicorn.svg',
      funFact: 'Unicorns are mythical creatures often symbolizing purity and magic!',
      isNumbered: true,
    ),
    ColoringPage(
      id: '3',
      category: 'Animals',
      svgPath: 'assets/coloring_pages/baby_dragon.svg',
      funFact: 'Dragons in mythology are often depicted as fire-breathing creatures!',
      isNumbered: true,
    ),
    ColoringPage(
      id: '4',
      category: 'Animals',
      svgPath: 'assets/coloring_pages/mermaid.svg',
      funFact: 'Mermaids are legendary beings said to live in the ocean and sing enchanting songs!',
      isNumbered: true,
    ),
    ColoringPage(
      id: '5',
      category: 'Animals',
      svgPath: 'assets/coloring_pages/cute-cat.svg',
      funFact: 'Cats are known for their agility and playful personalities!',
      isNumbered: true,
    ),
    ColoringPage(
      id: '6',
      category: 'Animals',
      svgPath: 'assets/coloring_pages/cute-horse.svg',
      funFact: 'Horses are majestic animals known for their strength and beauty!',
      isNumbered: true,
    ),
    ColoringPage(
      id: '7',
      category: 'Animals',
      svgPath: 'assets/coloring_pages/deer.svg',
      funFact: 'Deer are gentle creatures found in forests and meadows!',
      isNumbered: true,
    ),
  ],
  'Food': [
    ColoringPage(
      id: '8',
      category: 'Food',
      svgPath: 'assets/coloring_pages/ice-cream.svg',
      funFact: 'Ice cream is a popular dessert enjoyed by people of all ages!',
      isNumbered: true,
    ),
    ColoringPage(
      id: '9',
      category: 'Food',
      svgPath: 'assets/coloring_pages/muffin.svg',
      funFact: 'Muffins are a delicious baked good perfect for breakfast or snacks!',
      isNumbered: true,
    ),
  ],
  'Fantasy': [
    ColoringPage(
      id: '10',
      category: 'Fantasy',
      svgPath: 'assets/coloring_pages/witch.svg',
      funFact: 'Witches are often depicted as magical beings with mysterious powers!',
      isNumbered: true,
    ),
  ],
};

final List<ColoringPage> pages = pagesByCategory.values.expand((pages) => pages).toList();