class LibraryDocument {
  const LibraryDocument({
    required this.documentId,
    required this.title,
    required this.sourceKind,
    required this.sourceName,
    required this.profileKey,
    required this.protectedText,
    required this.findingsCount,
    required this.entityTypes,
    required this.labels,
    required this.replacementMode,
    required this.createdAt,
    required this.updatedAt,
    required this.hasMapping,
    this.favorite = false,
    this.mcpShared = false,
    this.deletedAt,
  });

  final String documentId;
  final String title;
  final String sourceKind;
  final String sourceName;
  final String profileKey;
  final String protectedText;
  final int findingsCount;
  final List<String> entityTypes;
  final List<String> labels;
  final String replacementMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasMapping;
  final bool favorite;
  final bool mcpShared;
  final DateTime? deletedAt;
}
