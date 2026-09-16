import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../mobile_link/protected_copy.dart';

abstract interface class ProtectedLibraryRepository {
  Future<List<ProtectedCopyDocument>> list();
  Future<void> save(ProtectedCopyDocument document);
  Future<void> delete(String documentId);
}

class SecureProtectedLibraryRepository implements ProtectedLibraryRepository {
  SecureProtectedLibraryRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _indexKey = 'privacygate.mobile.protected-library.index.v1';
  static const _itemPrefix = 'privacygate.mobile.protected-library.item.v1.';

  final FlutterSecureStorage _storage;

  @override
  Future<List<ProtectedCopyDocument>> list() async {
    final ids = await _readIndex();
    final documents = <ProtectedCopyDocument>[];
    for (final id in ids) {
      final raw = await _storage.read(key: '$_itemPrefix$id');
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          documents.add(ProtectedCopyDocument.fromJson(decoded));
        }
      } on FormatException {
        // Fail closed for malformed/legacy entries; never coerce mapping-bearing data.
      }
    }
    documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<ProtectedCopyDocument>.unmodifiable(documents);
  }

  @override
  Future<void> save(ProtectedCopyDocument document) async {
    if (document.hasMapping) {
      throw ArgumentError('Protected-only Library items cannot contain restore mappings.');
    }
    final key = '$_itemPrefix${document.documentId}';
    await _storage.write(key: key, value: jsonEncode(document.toLocalJson()));
    final ids = await _readIndex();
    if (!ids.contains(document.documentId)) {
      ids.add(document.documentId);
      await _writeIndex(ids);
    }
  }

  @override
  Future<void> delete(String documentId) async {
    await _storage.delete(key: '$_itemPrefix$documentId');
    final ids = await _readIndex();
    if (ids.remove(documentId)) await _writeIndex(ids);
  }

  Future<List<String>> _readIndex() async {
    final raw = await _storage.read(key: _indexKey);
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>[];
      return decoded.whereType<String>().toSet().toList(growable: true);
    } on FormatException {
      return <String>[];
    }
  }

  Future<void> _writeIndex(List<String> ids) async {
    await _storage.write(key: _indexKey, value: jsonEncode(ids));
  }
}
