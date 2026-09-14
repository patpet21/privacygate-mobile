import 'package:flutter/foundation.dart';

import '../profiles/document_languages.dart';
import '../profiles/privacy_profiles.dart';
import '../settings/privacy_gate_settings.dart';

/// Per-document protection controls.
///
/// These mirror the Desktop Protect workspace. They are deliberately separate
/// from application/UI preferences: scanLanguage selects the detector language
/// for the current document and is not the language of the app interface.
class ProtectionPolicy extends ChangeNotifier {
  String _profileKey = defaultProfileKey;
  String _scopeKey = 'financial';
  String _scanLanguage = defaultDocumentLanguage;
  ReplacementMode _replacementMode = ReplacementMode.reversible;
  double _confidenceThreshold = 0.35;

  String get profileKey => _profileKey;
  String get scopeKey => _scopeKey;
  String get scanLanguage => _scanLanguage;
  ReplacementMode get replacementMode => _replacementMode;
  double get confidenceThreshold => _confidenceThreshold;

  PrivacyProfile get profile => getProfile(_profileKey);
  List<String> get enabledEntities => entitiesForScope(profile, _scopeKey);

  void setProfileKey(String value) {
    getProfile(value);
    if (_profileKey == value) return;
    _profileKey = value;
    notifyListeners();
  }

  void setScopeKey(String value) {
    getScope(value);
    if (_scopeKey == value) return;
    _scopeKey = value;
    notifyListeners();
  }

  void setScanLanguage(String value) {
    getDocumentLanguage(value);
    if (_scanLanguage == value) return;
    _scanLanguage = value;
    notifyListeners();
  }

  void setReplacementMode(ReplacementMode value) {
    if (_replacementMode == value) return;
    _replacementMode = value;
    notifyListeners();
  }

  void setConfidenceThreshold(double value) {
    if (value < 0.10 || value > 0.95) {
      throw ArgumentError.value(
        value,
        'value',
        'Detection confidence must be between 0.10 and 0.95.',
      );
    }
    final normalized = double.parse(value.toStringAsFixed(2));
    if (_confidenceThreshold == normalized) return;
    _confidenceThreshold = normalized;
    notifyListeners();
  }
}
