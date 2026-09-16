import 'dart:convert';
import 'dart:io';

import '../domain/library_document.dart';
import '../storage/platform_private_storage.dart';

class LibraryIntegrityException implements Exception {
  const LibraryIntegrityException([this.message = 'Local Library data is invalid']);

  final String message;

  @override
  String toString() => 'LibraryIntegrityException: $message';
}

class LocalLibraryRepository {
  LocalLibraryRepository({required Directory directory}) : _directory = directory;

  static const String format = 'privacygate-mobile-library-v1';

  final Directory _directory;

  File get indexFile => File(
        '${_directory.path}${Platform.pathSeparator}library.json',
      );

  static Future<LocalLibraryRepository> openDefault({
    PlatformPrivateStorage? storage,
  }) async {
    final directory = await (storage ?? PlatformPrivateStorage()).libraryDirectory();
    return LocalLibraryRepository(directory: directory);
  }

  Future<List<LibraryDocument>> listDocuments({
    bool includeDeleted = false,
  }) async {
    final documents = await _readAll();
    final visible = includeDeleted
        ? documents
        : documents.where((document) => document.deletedAt == null).toList();
    visible.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return List<LibraryDocument>.unmodifiable(visible);
  }

  Future<LibraryDocument> get(String documentId) async {
    final documents = await _readAll();
    for (final document in documents) {
      if (document.documentId == documentId) return document;
    }
    throw StateError('Library document not found: $documentId');
  }

  Future<void> save(LibraryDocument document) async {
    final documents = await _readAll();
    final index = documents.indexWhere(
      (item) => item.documentId == document.documentId,
    );
    if (index >= 0) {
      documents[index] = document;
    } else {
      documents.add(document);
    }
    await _writeAll(documents);
  }

  Future<LibraryDocument> setFavorite(String documentId, bool favorite) async {
    final current = await get(documentId);
    final updated = LibraryDocument(
      documentId: current.documentId,
      title: current.title,
      sourceKind: current.sourceKind,
      sourceName: current.sourceName,
      profileKey: current.profileKey,
      protectedText: current.protectedText,
      findingsCount: current.findingsCount,
      entityTypes: current.entityTypes,
      labels: current.labels,
      replacementMode: current.replacementMode,
      createdAt: current.createdAt,
      updatedAt: DateTime.now().toUtc(),
      hasMapping: current.hasMapping,
      favorite: favorite,
      mcpShared: current.mcpShared,
      deletedAt: current.deletedAt,
    );
    await save(updated);
    return updated;
  }

  Future<int> storageBytes() async {
    final file = indexFile;
    if (!await file.exists()) return 0;
    return file.length();
  }

  Future<List<LibraryDocument>> _readAll() async {
    final file = indexFile;
    if (!await file.exists()) return <LibraryDocument>[];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        throw const LibraryIntegrityException('Library index must be an object');
      }
      final root = Map<String, dynamic>.from(decoded);
      if (root['format'] != format) {
        throw const LibraryIntegrityException('Unsupported Library index format');
      }
      final rawDocuments = root['documents'];
      if (rawDocuments is! List) {
        throw const LibraryIntegrityException('Library documents must be a list');
      }
      return rawDocuments.map((raw) {
        if (raw is! Map) {
          throw const LibraryIntegrityException('Library document entry is invalid');
        }
        return _fromJson(Map<String, dynamic>.from(raw));
      }).toList(growable: true);
    } on LibraryIntegrityException {
      rethrow;
    } on FormatException catch (error) {
      throw LibraryIntegrityException('Malformed Library data: ${error.message}');
    } on TypeError {
      throw const LibraryIntegrityException('Malformed Library data');
    }
  }

  Future<void> _writeAll(List<LibraryDocument> documents) async {
    await _directory.create(recursive: true);
    final payload = jsonEncode(<String, dynamic>{
      'format': format,
      'documents': documents.map(_toJson).toList(growable: false),
    });
    final temporary = File('${indexFile.path}.tmp');
    await temporary.writeAsString(payload, flush: true);
    if (await indexFile.exists()) await indexFile.delete();
    await temporary.rename(indexFile.path);
  }

  static Map<String, dynamic> _toJson(LibraryDocument document) =>
      <String, dynamic>{
        'documentId': document.documentId,
        'title': document.title,
        'sourceKind': document.sourceKind,
        'sourceName': document.sourceName,
        'profileKey': document.profileKey,
        'protectedText': document.protectedText,
        'findingsCount': document.findingsCount,
        'entityTypes': document.entityTypes,
        'labels': document.labels,
        'replacementMode': document.replacementMode,
        'createdAt': document.createdAt.toUtc().toIso8601String(),
        'updatedAt': document.updatedAt.toUtc().toIso8601String(),
        'hasMapping': document.hasMapping,
        'favorite': document.favorite,
        'mcpShared': document.mcpShared,
        'deletedAt': document.deletedAt?.toUtc().toIso8601String(),
      };

  static LibraryDocument _fromJson(Map<String, dynamic> raw) {
    final deletedValue = raw['deletedAt'];
    if (deletedValue != null && deletedValue is! String) {
      throw const LibraryIntegrityException('Library deletedAt is invalid');
    }
    return LibraryDocument(
      documentId: _string(raw, 'documentId'),
      title: _string(raw, 'title'),
      sourceKind: _string(raw, 'sourceKind'),
      sourceName: _string(raw, 'sourceName'),
      profileKey: _string(raw, 'profileKey'),
      protectedText: _string(raw, 'protectedText'),
      findingsCount: _integer(raw, 'findingsCount'),
      entityTypes: _strings(raw, 'entityTypes'),
      labels: _strings(raw, 'labels'),
      replacementMode: _string(raw, 'replacementMode'),
      createdAt: DateTime.parse(_string(raw, 'createdAt')).toUtc(),
      updatedAt: DateTime.parse(_string(raw, 'updatedAt')).toUtc(),
      hasMapping: _boolean(raw, 'hasMapping'),
      favorite: _boolean(raw, 'favorite'),
      mcpShared: _boolean(raw, 'mcpShared'),
      deletedAt: deletedValue == null ? null : DateTime.parse(deletedValue).toUtc(),
    );
  }

  static String _string(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! String) {
      throw LibraryIntegrityException('Library field $key is invalid');
    }
    return value;
  }

  static int _integer(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! int) {
      throw LibraryIntegrityException('Library field $key is invalid');
    }
    return value;
  }

  static bool _boolean(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! bool) {
      throw LibraryIntegrityException('Library field $key is invalid');
    }
    return value;
  }

  static List<String> _strings(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw LibraryIntegrityException('Library field $key is invalid');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}
