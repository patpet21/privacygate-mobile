typedef Point = (double, double);
typedef Polygon = List<Point>;

class OcrTextRegion {
  const OcrTextRegion({
    required this.text,
    required this.start,
    required this.end,
    required this.confidence,
    required this.polygon,
    this.level = 'word',
    this.lineIndex = 0,
  });

  final String text;
  final int start;
  final int end;
  final double confidence;
  final Polygon polygon;
  final String level;
  final int lineIndex;

  bool overlaps(int rangeStart, int rangeEnd) =>
      rangeStart < end && start < rangeEnd;
}

class OcrPageLayout {
  const OcrPageLayout({
    required this.pageNumber,
    required this.width,
    required this.height,
    this.regions = const [],
  });

  final int pageNumber;
  final int width;
  final int height;
  final List<OcrTextRegion> regions;

  List<OcrTextRegion> regionsForRange(int start, int end) {
    final words = regions
        .where(
          (region) =>
              region.level == 'word' && region.overlaps(start, end),
        )
        .toList(growable: false);
    if (words.isNotEmpty) return List.unmodifiable(words);
    return List.unmodifiable(
      regions.where(
        (region) =>
            region.level == 'line' && region.overlaps(start, end),
      ),
    );
  }
}
