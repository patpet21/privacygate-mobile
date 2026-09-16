import 'dart:math';

import 'package:flutter/foundation.dart';

import '../desktop_link/desktop_protected_copy.dart';
import '../domain/library_document.dart';
import '../domain/protection_result.dart';
import '../domain/replacement_mapping.dart';
import '../vault/encrypted_vault_repository.dart';
import 'local_library_repository.dart';

class StoredProtection {
  const StoredProtection({
    required this.document,
    required this.mappings,
  });

  final LibraryDocument document;
  final List<ReplacementMapping> mappings;
}

class ProtectedLibraryService extends ChangeNotifier {
  ProtectedLibraryService({
    required LocalLibraryRepository library,
    required EncryptedVaultRepository vault,
  })  : _library = library,
        _vault = vault;

  final LocalLibraryRepository _library;
  final EncryptedVaultRepository _vault;

  static Future<ProtectedLibraryService> openDefault() async {
    final library = await LocalLibraryRepository.openDefault();
    final vault = await EncryptedVaultRepository.openDefault();
    return ProtectedLibraryService(library: library, vault: vault);
  }

  Future<List<LibraryDocument>> listDocuments() => _library.listDocuments();

  Future<LibraryDocument> saveVerifiedProtection({
    required String profileKey,
    required ProtectionResult result,
    String sourceKind = 'text',
    String sourceName = 'Paste text',
    String? title,
    List<String> labels = const <String>[],
  }) async {
    if (result.protectedText.trim().isEmpty) {
      throw ArgumentError('Protected text cannot be empty');
    }

    final now = DateTime.now().toUtc();
    final documentId = _newDocumentId(now);
    final entityTypes = result.appliedFindings
        .map((finding) => finding.entityType)
        .toSet()
        .toList(growable: false)
      ..sort();
    final hasMapping = result.mappings.isNotEmpty;
    var vaultSaved = false;

    if (hasMapping) {
      await _vault.saveMappings(documentId, result.mappings);
      vaultSaved = true;
    }

    final document = LibraryDocument(
      documentId: documentId,
      title: (title?.trim().isNotEmpty ?? false)
          ? title!.trim()
          : _defaultTitle(now.toLocal()),
      sourceKind: sourceKind,
      sourceName: sourceName,
      profileKey: profileKey,
      protectedText: result.protectedText,
      findingsCount: result.appliedFindings.length,
      entityTypes: List<String>.unmodifiable(entityTypes),
      labels: List<String>.unmodifiable(
        labels.map((label) => label.trim()).where((label) => label.isNotEmpty),
      ),
      replacementMode: result.replacementMode,
      createdAt: now,
      updatedAt: now,
      hasMapping: hasMapping,
      favorite: false,
      mcpShared: false,
    );

    try {
      await _library.save(document);
    } catch (_) {
      if (vaultSaved) await _vault.delete(documentId);
      rethrow;
    }

    notifyListeners();
    return document;
  }

  Future<LibraryDocument> saveDesktopProtectedCopy(
    DesktopProtectedCopyDocument copy,
  ) async {
    if (copy.hasMapping) {
      throw StateError('Desktop protected copies must never contain restore mappings.');
    }
    if (copy.protectedText.trim().isEmpty) {
      throw ArgumentError('Protected text cannot be empty');
    }

    final now = DateTime.now().toUtc();
    LibraryDocument? existing;
    try {
      existing = await _library.get(copy.localDocumentId);
    } on StateError {
      existing = null;
    }

    final document = LibraryDocument(
      documentId: copy.localDocumentId,
      title: copy.title,
      sourceKind: 'desktop',
      sourceName: 'Trusted Desktop',
      profileKey: copy.profileKey,
      protectedText: copy.protectedText,
      findingsCount: copy.findingsCount,
      entityTypes: List<String>.unmodifiable(copy.entityTypes),
      labels: List<String>.unmodifiable(copy.labels),
      replacementMode: 'protected_copy',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      hasMapping: false,
      favorite: existing?.favorite ?? copy.favorite,
      mcpShared: false,
    );

    await _library.save(document);
    notifyListeners();
    return document;
  }

  Future<StoredProtection> loadProtection(String documentId) async {
    final document = await _library.get(documentId);
    final mappings = document.hasMapping
        ? await _vault.loadMappings(documentId)
        : const <ReplacementMapping>[];
    if (document.hasMapping && mappings.isEmpty) {
      throw StateError('Restore mapping is unavailable for ${document.documentId}');
    }
    return StoredProtection(document: document, mappings: mappings);
  }

  Future<LibraryDocument> setFavorite(String documentId, bool favorite) async {
    final updated = await _library.setFavorite(documentId, favorite);
    notifyListeners();
    return updated;
  }

  Future<int> storageBytes() async =>
      await _library.storageBytes() + await _vault.storageBytes();

  static String _newDocumentId(DateTime now) {
    final random = Random.secure();
    final suffix = List<String>.generate(
      8,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      growable: false,
    ).join();
    return 'mob_${now.microsecondsSinceEpoch}_$suffix';
  }

  static String _defaultTitle(DateTime local) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'Protected text ${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
