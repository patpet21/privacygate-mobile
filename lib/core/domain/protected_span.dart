class ProtectedSpan {
  const ProtectedSpan({
    required this.pageNumber,
    required this.start,
    required this.end,
    required this.entityType,
    required this.findingId,
    required this.replacementText,
  });

  final int pageNumber;
  final int start;
  final int end;
  final String entityType;
  final String findingId;
  final String replacementText;
}
