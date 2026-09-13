import 'package:flutter/foundation.dart';

import '../../core/detection/detection_engine.dart';
import '../../core/domain/privacy_finding.dart';
import '../../core/domain/protection_result.dart';
import '../../core/protection/privacy_gate_protector.dart';

class ProtectController extends ChangeNotifier {
  ProtectController({
    required DetectionEngine detector,
    required PrivacyGateProtector protector,
  })  : _detector = detector,
        _protector = protector;

  final DetectionEngine _detector;
  final PrivacyGateProtector _protector;

  String originalText = '';
  List<PrivacyFinding> findings = const [];
  Set<String> selectedFindingIds = <String>{};
  ProtectionResult? result;
  String restoredText = '';
  bool analyzing = false;

  Future<void> analyze(String text) async {
    originalText = text;
    result = null;
    restoredText = '';
    analyzing = true;
    notifyListeners();
    try {
      findings = await _detector.analyze(text);
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
    result = _protector.protect(originalText, selected);
    restoredText = '';
    notifyListeners();
  }

  void restoreLocally() {
    final current = result;
    if (current == null) {
      return;
    }
    restoredText = _protector.restore(current.protectedText, current.mappings);
    notifyListeners();
  }
}
