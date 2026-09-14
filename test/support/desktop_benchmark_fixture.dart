import 'dart:convert';
import 'dart:io';

class ExpectedBenchmarkFinding {
  const ExpectedBenchmarkFinding({
    required this.entityType,
    required this.value,
    required this.pageNumber,
    required this.start,
    required this.end,
    required this.occurrence,
  });

  final String entityType;
  final String value;
  final int pageNumber;
  final int start;
  final int end;
  final int occurrence;

  factory ExpectedBenchmarkFinding.fromJson(Map<String, Object?> json) {
    return ExpectedBenchmarkFinding(
      entityType: json['entity_type']! as String,
      value: json['value']! as String,
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 1,
      start: (json['start']! as num).toInt(),
      end: (json['end']! as num).toInt(),
      occurrence: (json['occurrence'] as num?)?.toInt() ?? 1,
    );
  }
}

class DesktopBenchmarkCase {
  const DesktopBenchmarkCase({
    required this.id,
    required this.group,
    required this.genre,
    required this.sourceKind,
    required this.coverage,
    required this.formatTags,
    required this.pages,
    required this.expected,
  });

  final String id;
  final String group;
  final String genre;
  final String sourceKind;
  final String coverage;
  final List<String> formatTags;
  final List<String> pages;
  final List<ExpectedBenchmarkFinding> expected;

  factory DesktopBenchmarkCase.fromJson(Map<String, Object?> json) {
    final text = json['text'] as String?;
    final rawPages = json['pages'] as List<Object?>?;
    if (text == null && (rawPages == null || rawPages.isEmpty)) {
      throw const FormatException('Benchmark case must contain text or pages.');
    }

    final pages = text != null
        ? <String>[text]
        : rawPages!
            .map((page) {
              if (page is String) {
                return page;
              }
              if (page is Map<String, Object?> && page['text'] is String) {
                return page['text']! as String;
              }
              if (page is Map) {
                final normalized = Map<String, Object?>.from(page);
                final pageText = normalized['text'];
                if (pageText is String) {
                  return pageText;
                }
              }
              throw const FormatException('Unsupported benchmark page shape.');
            })
            .toList(growable: false);

    return DesktopBenchmarkCase(
      id: json['id']! as String,
      group: json['group']! as String,
      genre: (json['genre'] as String?) ?? '',
      sourceKind: (json['source_kind'] as String?) ?? 'text',
      coverage: (json['coverage'] as String?) ?? 'current',
      formatTags: ((json['format_tags'] as List<Object?>?) ?? const [])
          .cast<String>(),
      pages: pages,
      expected: ((json['expected'] as List<Object?>?) ?? const [])
          .map(
            (item) => ExpectedBenchmarkFinding.fromJson(
              Map<String, Object?>.from(item! as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

List<DesktopBenchmarkCase> loadDesktopEnglishV1({
  String root = 'test/fixtures/desktop_754f412/english/v1',
}) {
  final directory = Directory(root);
  if (!directory.existsSync()) {
    throw StateError(
      'Canonical Desktop fixtures are not synchronized. Run '
      'tool/sync_desktop_fixtures.py against the pinned Desktop repository.',
    );
  }

  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.jsonl'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final cases = <DesktopBenchmarkCase>[];
  final seenIds = <String>{};
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        continue;
      }
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        throw FormatException('${file.path}:${index + 1} is not a JSON object.');
      }
      final item = DesktopBenchmarkCase.fromJson(
        Map<String, Object?>.from(decoded),
      );
      if (!seenIds.add(item.id)) {
        throw FormatException('Duplicate canonical benchmark ID: ${item.id}');
      }
      cases.add(item);
    }
  }
  return List.unmodifiable(cases);
}
