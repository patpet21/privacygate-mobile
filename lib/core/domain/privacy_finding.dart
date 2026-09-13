class PrivacyFinding {
  const PrivacyFinding({
    required this.findingId,
    required this.entityType,
    required this.text,
    required this.start,
    required this.end,
    required this.score,
    this.pageNumber = 1,
    this.context = '',
  });

  final String findingId;
  final String entityType;
  final String text;
  final int start;
  final int end;
  final double score;
  final int pageNumber;
  final String context;
}
