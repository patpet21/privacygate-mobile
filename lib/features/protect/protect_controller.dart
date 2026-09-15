import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/detection/detection_engine.dart';
import '../../core/domain/privacy_finding.dart';
import '../../core/domain/protection_result.dart';
import '../../core/protection/privacy_gate_protector.dart';
import '../../core/protection/protection_policy.dart';

class ProtectController extends ChangeNotifier {
  ProtectController({
    required DetectionEngine detector,
    required PrivacyGateProtector protector,
    required ProtectionPolicy policy,
  })  : _detector = detector,
        _protector = protector,
        _policy = policy {
    _policy.addListener(_policyChanged);
  }

  final DetectionEngine _detector;
  final PrivacyGateProtector _protector;
  final ProtectionPolicy _policy;

  String originalText = '';
  List<PrivacyFinding> findings = const [];
  Set<String> selectedFindingIds = <String>{};
  ProtectionResult? result;
  String restoredText = '';
  List<PrivacyFinding> residualFindings = const [];
  bool analyzing = false;
  bool verificationRunning = false;
  bool verificationPerformed = false;
  String? verificationError;
  int _policyRevision = 0;

  ProtectionPolicy get policy => _policy;
  int get selectedCount => selectedFindingIds.length;
  bool get hasLocalRestoreMapping => result != null && result!.mappings.isNotEmpty;

  bool get exportVerified =>
      result != null &&
      verificationPerformed &&
      !verificationRunning &&
      verificationError == null &&
      residualFindings.isEmpty;

  Future<void> analyze(String text) async {
    originalText = text;
    _clearOutput();
    findings = const [];
    selectedFindingIds = <String>{};

    if (text.trim().isEmpty) {
      notifyListeners();
      return;
    }

    final revision = _policyRevision;
    analyzing = true;
    notifyListeners();
    try {
      final detected = await _detector.analyze(_requestFor(text));
      if (revision != _policyRevision) return;
      findings = List.unmodifiable(detected);
      selectedFindingIds = detected.map((item) => item.findingId).toSet();
    } finally {
      if (revision == _policyRevision) {
        analyzing = false;
        notifyListeners();
      }
    }
  }

  void setSelected(String findingId, bool selected) {
    if (selected) {
      selectedFindingIds.add(findingId);
    } else {
      selectedFindingIds.remove(findingId);
    }
    _clearOutput();
    notifyListeners();
  }

  void selectAll() {
    selectedFindingIds = findings.map((item) => item.findingId).toSet();
    _clearOutput();
    notifyListeners();
  }

  void keepAll() {
    selectedFindingIds = <String>{};
    _clearOutput();
    notifyListeners();
  }

  void invertSelection() {
    final current = selectedFindingIds;
    selectedFindingIds = findings
        .where((item) => !current.contains(item.findingId))
        .map((item) => item.findingId)
        .toSet();
    _clearOutput();
    notifyListeners();
  }

  void setCategorySelected(String entityType, bool selected) {
    final matching = findings.where((item) => item.entityType == entityType);
    for (final finding in matching) {
      if (selected) {
        selectedFindingIds.add(finding.findingId);
      } else {
        selectedFindingIds.remove(finding.findingId);
      }
    }
    _clearOutput();
    notifyListeners();
  }

  void addManualFinding(String value, String entityType) {
    final requested = value.trim();
    if (requested.isEmpty || originalText.isEmpty) return;

    final normalizedEntity = entityType.trim().toUpperCase().replaceAll(' ', '_');
    final parts = requested.split(RegExp(r'\s+'));
    final pattern = RegExp(
      parts.map(RegExp.escape).join(r'\s+'),
      caseSensitive: false,
    );
    final additions = <PrivacyFinding>[];

    for (final match in pattern.allMatches(originalText)) {
      final overlaps = findings.any(
        (item) => match.start < item.end && item.start < match.end,
      );
      if (overlaps) continue;

      final contextStart = math.max(0, match.start - 34);
      final contextEnd = math.min(originalText.length, match.end + 34);
      additions.add(
        PrivacyFinding(
          findingId: 'manual-${match.start}-${match.end}-$normalizedEntity',
          entityType: normalizedEntity,
          text: originalText.substring(match.start, match.end),
          start: match.start,
          end: match.end,
          score: 1,
          context: originalText.substring(contextStart, contextEnd),
        ),
      );
    }

    if (additions.isEmpty) return;
    final merged = <PrivacyFinding>[...findings, ...additions]
      ..sort((a, b) => a.start.compareTo(b.start));
    findings = List.unmodifiable(merged);
    selectedFindingIds.addAll(additions.map((item) => item.findingId));
    _clearOutput();
    notifyListeners();
  }

  Future<void> protectAndVerify() async {
    final selected = findings
        .where((item) => selectedFindingIds.contains(item.findingId))
        .toList(growable: false);
    if (selected.isEmpty) return;

    final protected = _protector.protect(
      originalText,
      selected,
      replacementMode: _policy.replacementMode.wireValue,
    );
    result = protected;
    restoredText = '';
    residualFindings = const [];
    verificationError = null;
    verificationPerformed = false;
    verificationRunning = true;
    final revision = _policyRevision;
    notifyListeners();

    try {
      final residual = await _detector.analyze(_requestFor(protected.protectedText));
      if (revision != _policyRevision) return;
      residualFindings = List.unmodifiable(residual);
      verificationPerformed = true;
    } catch (error) {
      if (revision != _policyRevision) return;
      verificationError = error.toString();
      verificationPerformed = true;
    } finally {
      if (revision == _policyRevision) {
        verificationRunning = false;
        notifyListeners();
      }
    }
  }

  void restoreLocally() {
    final current = result;
    if (current == null) return;
    restoreTextLocally(current.protectedText);
  }

  String restoreTextLocally(String text) {
    final current = result;
    if (current == null || current.mappings.isEmpty || text.isEmpty) return '';
    restoredText = _protector.restore(text, current.mappings);
    notifyListeners();
    return restoredText;
  }

  void clear() {
    originalText = '';
    findings = const [];
    selectedFindingIds = <String>{};
    analyzing = false;
    _clearOutput();
    notifyListeners();
  }

  DetectionRequest _requestFor(String text) => DetectionRequest(
        text: text,
        profileKey: _policy.profileKey,
        scopeKey: _policy.scopeKey,
        scanLanguage: _policy.scanLanguage,
        entities: _policy.enabledEntities,
        confidenceThreshold: _policy.confidenceThreshold,
      );

  void _policyChanged() {
    _policyRevision += 1;
    analyzing = false;
    findings = const [];
    selectedFindingIds = <String>{};
    _clearOutput();
    notifyListeners();
  }

  void _clearOutput() {
    result = null;
    restoredText = '';
    residualFindings = const [];
    verificationRunning = false;
    verificationPerformed = false;
    verificationError = null;
  }

  @override
  void dispose() {
    _policy.removeListener(_policyChanged);
    super.dispose();
  }
}
