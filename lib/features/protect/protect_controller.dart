import 'package:flutter/foundation.dart';

import '../../core/detection/detection_engine.dart';
import '../../core/domain/privacy_finding.dart';
import '../../core/domain/protection_result.dart';
import '../../core/protection/privacy_gate_protector.dart';
import '../../core/settings/privacy_gate_settings.dart';

class ProtectController extends ChangeNotifier {
  ProtectController({
    required DetectionEngine detector,
    required PrivacyGateProtector protector,
    required PrivacyGateSettings settings,
  })  : _detector = detector,
        _protector = protector,
        _settings = settings {
    _settings.addListener(_settingsChanged);
  }

  final DetectionEngine _detector;
  final PrivacyGateProtector _protector;
  final PrivacyGateSettings _settings;

  String originalText = '';
  List<PrivacyFinding> findings = const [];
  Set<String> selectedFindingIds = <String>{};
  ProtectionResult? result;
  String restoredText = '';
  bool analyzing = false;

  PrivacyGateSettings get settings => _settings;

  Future<void> analyze(String text) async {
    originalText = text;
    result = null;
    restoredText = '';
    analyzing = true;
    notifyListeners();
    try {
      findings = await _detector.analyze(
        DetectionRequest(
          text: text,
          profileKey: _settings.profileKey,
          scopeKey: _settings.scopeKey,
          language: _settings.language,
          entities: _settings.enabledEntities,
        ),
      );
      selectedFindingIds = findings.map((item) => item.findingId).toSet();
    } finally {
      analyzing = false;
      notifyListeners();
    }
  }

  void setSelected(String findingId, bool selected) {
    if (selected) {
      selectedFindingIds.add(findingId);
    } else {
      selectedFindingIds.remove(findingId);
    }
    notifyListeners();
  }

  void protect() {
    final selected = findings.where(
      (item) => selectedFindingIds.contains(item.findingId),
    );
    result = _protector.protect(
      originalText,
      selected,
      replacementMode: _settings.replacementMode.wireValue,
    );
    restoredText = '';
    notifyListeners();
  }

  void restoreLocally() {
    final current = result;
    if (current == null || current.mappings.isEmpty) {
      return;
    }
    restoredText = _protector.restore(current.protectedText, current.mappings);
    notifyListeners();
  }

  void _settingsChanged() {
    // A previous analysis/protected result was produced under a different policy.
    // Fail closed: require a fresh scan instead of silently reusing stale findings.
    findings = const [];
    selectedFindingIds = <String>{};
    result = null;
    restoredText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(_settingsChanged);
    super.dispose();
  }
}
