import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/detection/detection_engine.dart';
import '../../core/domain/analysis_document.dart';
import '../../core/domain/page_content.dart';
import '../../core/domain/privacy_finding.dart';
import '../../core/domain/protection_result.dart';
import '../../core/protection/privacy_gate_protector.dart';
import '../../core/protection/protection_policy.dart';
import 'protect_state.dart';

class ProtectController extends ChangeNotifier {
  ProtectController({
    required DocumentDetectionEngine detector,
    required PrivacyGateProtector protector,
    required ProtectionPolicy policy,
  })  : _detector = detector,
        _protector = protector,
        _policy = policy {
    _policy.addListener(_policyChanged);
  }

  final DocumentDetectionEngine _detector;
  final PrivacyGateProtector _protector;
  final ProtectionPolicy _policy;

  String originalText = '';
  List<PrivacyFinding> findings = const [];
  Set<String> selectedFindingIds = <String>{};
  ProtectionResult? result;
  String restoredText = '';
  List<PrivacyFinding> residualFindings = const [];
  bool verificationPerformed = false;
  String? verificationError;

  ProtectState _state = const ProtectState();
  List<PrivacyFinding> _manualFindings = const [];
  int _workflowRevision = 0;

  ProtectionPolicy get policy => _policy;
  ProtectState get state => _state;
  ProtectPhase get phase => _state.phase;
  ProtectOperation get operation => _state.operation;
  bool get analyzing => _state.isAnalyzing;
  bool get verificationRunning => _state.isVerifying;
  int get selectedCount => selectedFindingIds.length;
  bool get hasLocalRestoreMapping => result != null && result!.mappings.isNotEmpty;

  bool get exportVerified =>
      result != null &&
      verificationPerformed &&
      !verificationRunning &&
      verificationError == null &&
      residualFindings.isEmpty;

  Future<void> analyze(String text) async {
    final sameSource = text == originalText;
    final retainedManual = sameSource
        ? List<PrivacyFinding>.from(_manualFindings)
        : <PrivacyFinding>[];
    final retainedManualIds = retainedManual.map((item) => item.findingId).toSet();
    final retainedManualSelection = sameSource
        ? selectedFindingIds.intersection(retainedManualIds)
        : <String>{};

    final revision = ++_workflowRevision;
    originalText = text;
    _manualFindings = List.unmodifiable(retainedManual);
    findings = List.unmodifiable(retainedManual);
    selectedFindingIds = retainedManualSelection;
    _clearOutput(
      phase: ProtectPhase.source,
      operation: text.trim().isEmpty
          ? ProtectOperation.idle
          : ProtectOperation.analyzing,
    );

    if (text.trim().isEmpty) {
      notifyListeners();
      return;
    }

    final sourceDocument = AnalysisDocument(
      sourceKind: 'text',
      pages: [PageContent(pageNumber: 1, text: text)],
    );
    notifyListeners();

    try {
      final detected = await _detector.analyze(_requestFor(sourceDocument));
      if (revision != _workflowRevision) return;

      final merged = _mergeDetectedWithManual(detected, _manualFindings);
      findings = List.unmodifiable(merged);
      selectedFindingIds = {
        for (final finding in merged)
          if (!_isManualFinding(finding) ||
              retainedManualSelection.contains(finding.findingId))
            finding.findingId,
      };
      _state = _state.copyWith(phase: ProtectPhase.review);
    } finally {
      if (revision == _workflowRevision) {
        _state = _state.copyWith(operation: ProtectOperation.idle);
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
    _invalidateOutput(ProtectPhase.review);
  }

  void selectAll() {
    selectedFindingIds = findings.map((item) => item.findingId).toSet();
    _invalidateOutput(ProtectPhase.review);
  }

  void keepAll() {
    selectedFindingIds = <String>{};
    _invalidateOutput(ProtectPhase.review);
  }

  void invertSelection() {
    final current = selectedFindingIds;
    selectedFindingIds = findings
        .where((item) => !current.contains(item.findingId))
        .map((item) => item.findingId)
        .toSet();
    _invalidateOutput(ProtectPhase.review);
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
    _invalidateOutput(ProtectPhase.review);
  }

  void addManualFinding(String value, String entityType) {
    final requested = value.trim();
    if (requested.isEmpty || originalText.isEmpty) return;

    final normalizedEntity = _normalizeEntityType(entityType);
    final parts = requested.split(RegExp(r'\s+'));
    final pattern = RegExp(
      parts.map(RegExp.escape).join(r'\s+'),
      caseSensitive: false,
    );

    var changed = false;
    for (final match in pattern.allMatches(originalText)) {
      changed = _addManualFindingRange(
            start: match.start,
            end: match.end,
            entityType: normalizedEntity,
            pageNumber: 1,
          ) ||
          changed;
    }

    if (!changed) return;
    _invalidateOutput(ProtectPhase.review);
  }

  void addManualFindingRange({
    required int start,
    required int end,
    required String entityType,
    int pageNumber = 1,
  }) {
    final changed = _addManualFindingRange(
      start: start,
      end: end,
      entityType: _normalizeEntityType(entityType),
      pageNumber: pageNumber,
    );
    if (!changed) return;
    _invalidateOutput(ProtectPhase.review);
  }

  Future<void> protectAndVerify() async {
    final selected = findings
        .where((item) => selectedFindingIds.contains(item.findingId))
        .toList(growable: false);
    if (selected.isEmpty) return;

    final revision = ++_workflowRevision;
    final sourceDocument = AnalysisDocument(
      sourceKind: 'text',
      pages: [PageContent(pageNumber: 1, text: originalText)],
    );
    final protected = _protector.protect(
      sourceDocument,
      selected,
      replacementMode: _policy.replacementMode,
    );
    result = protected;
    restoredText = '';
    residualFindings = const [];
    verificationError = null;
    verificationPerformed = false;
    _state = const ProtectState(
      phase: ProtectPhase.protected,
      operation: ProtectOperation.verifying,
    );
    notifyListeners();

    try {
      final protectedDocument = AnalysisDocument(
        sourceKind: 'protected',
        pages: protected.protectedPages,
      );
      final residual = await _detector.analyze(_requestFor(protectedDocument));
      if (revision != _workflowRevision) return;
      residualFindings = List.unmodifiable(residual);
      verificationPerformed = true;
    } catch (error) {
      if (revision != _workflowRevision) return;
      verificationError = error.toString();
      verificationPerformed = true;
    } finally {
      if (revision == _workflowRevision) {
        _state = _state.copyWith(operation: ProtectOperation.idle);
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
    ++_workflowRevision;
    originalText = '';
    findings = const [];
    selectedFindingIds = <String>{};
    _manualFindings = const [];
    _clearOutput(phase: ProtectPhase.source);
    notifyListeners();
  }

  DocumentDetectionRequest _requestFor(AnalysisDocument document) =>
      DocumentDetectionRequest(
        document: document,
        profileKey: _policy.profileKey,
        scopeKey: _policy.scopeKey,
        scanLanguage: _policy.scanLanguage,
        entities: _policy.enabledEntities,
        confidenceThreshold: _policy.confidenceThreshold,
      );

  bool _addManualFindingRange({
    required int start,
    required int end,
    required String entityType,
    required int pageNumber,
  }) {
    if (pageNumber != 1 || start < 0 || end <= start || end > originalText.length) {
      return false;
    }

    final manual = <PrivacyFinding>[..._manualFindings];
    final working = <PrivacyFinding>[...findings];
    final sameRangeManualIndex = manual.indexWhere(
      (item) =>
          item.pageNumber == pageNumber && item.start == start && item.end == end,
    );
    final existing = sameRangeManualIndex >= 0
        ? manual[sameRangeManualIndex]
        : null;

    if (existing != null && existing.entityType == entityType) {
      final wasSelected = selectedFindingIds.contains(existing.findingId);
      selectedFindingIds.add(existing.findingId);
      return !wasSelected;
    }

    final candidate = _manualFindingForRange(
      start: start,
      end: end,
      entityType: entityType,
      pageNumber: pageNumber,
    );

    final overlapsManual = manual.any(
      (item) => item.findingId != existing?.findingId && _overlaps(item, candidate),
    );
    if (overlapsManual) return false;

    if (existing != null) {
      manual.removeWhere((item) => item.findingId == existing.findingId);
      working.removeWhere((item) => item.findingId == existing.findingId);
      selectedFindingIds.remove(existing.findingId);
    }

    final overlappingAutomaticIds = working
        .where((item) => !_isManualFinding(item) && _overlaps(item, candidate))
        .map((item) => item.findingId)
        .toSet();

    working.removeWhere((item) => overlappingAutomaticIds.contains(item.findingId));
    selectedFindingIds.removeAll(overlappingAutomaticIds);

    manual.add(candidate);
    working.add(candidate);
    _sortFindings(manual);
    _sortFindings(working);

    _manualFindings = List.unmodifiable(manual);
    findings = List.unmodifiable(working);
    selectedFindingIds.add(candidate.findingId);
    return true;
  }

  PrivacyFinding _manualFindingForRange({
    required int start,
    required int end,
    required String entityType,
    required int pageNumber,
  }) {
    final contextStart = math.max(0, start - 34);
    final contextEnd = math.min(originalText.length, end + 34);
    return PrivacyFinding(
      findingId: 'manual-p$pageNumber-$start-$end-$entityType',
      entityType: entityType,
      text: originalText.substring(start, end),
      start: start,
      end: end,
      score: 1,
      pageNumber: pageNumber,
      context: originalText.substring(contextStart, contextEnd),
    );
  }

  List<PrivacyFinding> _mergeDetectedWithManual(
    List<PrivacyFinding> detected,
    List<PrivacyFinding> manual,
  ) {
    final merged = <PrivacyFinding>[
      for (final finding in detected)
        if (!manual.any((manualFinding) => _overlaps(finding, manualFinding)))
          finding,
      ...manual,
    ];
    _sortFindings(merged);
    return merged;
  }

  void _policyChanged() {
    ++_workflowRevision;
    final manualIds = _manualFindings.map((item) => item.findingId).toSet();
    selectedFindingIds = selectedFindingIds.intersection(manualIds);
    findings = List.unmodifiable(_manualFindings);
    _clearOutput(phase: ProtectPhase.source);
    notifyListeners();
  }

  void _invalidateOutput(ProtectPhase phase) {
    ++_workflowRevision;
    _clearOutput(phase: phase);
    notifyListeners();
  }

  void _clearOutput({
    ProtectPhase? phase,
    ProtectOperation operation = ProtectOperation.idle,
  }) {
    result = null;
    restoredText = '';
    residualFindings = const [];
    verificationPerformed = false;
    verificationError = null;
    _state = ProtectState(
      phase: phase ?? _state.phase,
      operation: operation,
    );
  }

  static String _normalizeEntityType(String entityType) =>
      entityType.trim().toUpperCase().replaceAll(' ', '_');

  static bool _isManualFinding(PrivacyFinding finding) =>
      finding.findingId.startsWith('manual-');

  static bool _overlaps(PrivacyFinding first, PrivacyFinding second) =>
      first.pageNumber == second.pageNumber &&
      first.start < second.end &&
      second.start < first.end;

  static void _sortFindings(List<PrivacyFinding> values) {
    values.sort((a, b) {
      final pageCompare = a.pageNumber.compareTo(b.pageNumber);
      if (pageCompare != 0) return pageCompare;
      final startCompare = a.start.compareTo(b.start);
      if (startCompare != 0) return startCompare;
      return a.end.compareTo(b.end);
    });
  }

  @override
  void dispose() {
    _policy.removeListener(_policyChanged);
    super.dispose();
  }
}
