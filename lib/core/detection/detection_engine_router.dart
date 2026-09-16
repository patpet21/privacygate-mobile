import '../domain/privacy_finding.dart';
import 'detection_engine.dart';

enum DetectionEngineKind {
  desktop,
  mobileEnhanced,
  mobileBasic,
}

class DetectionEngineUnavailableException implements Exception {
  const DetectionEngineUnavailableException([
    this.message = 'Detection engine unavailable',
  ]);

  final String message;

  @override
  String toString() => 'DetectionEngineUnavailableException: $message';
}

typedef DetectionEngineAvailability = Future<bool> Function();

/// Chooses the strongest available detector without changing the finding contract.
///
/// Order is deliberate:
/// 1. paired/reachable Desktop engine (Presidio + spaCy + PrivacyGate recognizers)
/// 2. optional on-device Enhanced engine (future ONNX NER pack)
/// 3. deterministic Mobile Basic rules
///
/// Only an explicit [DetectionEngineUnavailableException] triggers a fallback
/// after an engine was selected. Programming/protocol errors surface normally so
/// a broken Desktop bridge cannot silently masquerade as a successful basic scan.
class DetectionEngineRouter implements DetectionEngine {
  DetectionEngineRouter({
    required DetectionEngine mobileBasic,
    DetectionEngine? desktop,
    DetectionEngineAvailability? desktopAvailable,
    DetectionEngine? mobileEnhanced,
    DetectionEngineAvailability? mobileEnhancedAvailable,
  })  : _mobileBasic = mobileBasic,
        _desktop = desktop,
        _desktopAvailable = desktopAvailable,
        _mobileEnhanced = mobileEnhanced,
        _mobileEnhancedAvailable = mobileEnhancedAvailable;

  final DetectionEngine _mobileBasic;
  final DetectionEngine? _desktop;
  final DetectionEngineAvailability? _desktopAvailable;
  final DetectionEngine? _mobileEnhanced;
  final DetectionEngineAvailability? _mobileEnhancedAvailable;

  DetectionEngineKind _lastUsed = DetectionEngineKind.mobileBasic;

  DetectionEngineKind get lastUsed => _lastUsed;

  @override
  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async {
    if (_desktop != null && await _isAvailable(_desktopAvailable)) {
      try {
        final result = await _desktop.analyze(request);
        _lastUsed = DetectionEngineKind.desktop;
        return result;
      } on DetectionEngineUnavailableException {
        // Connection disappeared between availability probe and request.
      }
    }

    if (_mobileEnhanced != null &&
        await _isAvailable(_mobileEnhancedAvailable)) {
      try {
        final result = await _mobileEnhanced.analyze(request);
        _lastUsed = DetectionEngineKind.mobileEnhanced;
        return result;
      } on DetectionEngineUnavailableException {
        // Optional model became unavailable; deterministic rules remain safe.
      }
    }

    final result = await _mobileBasic.analyze(request);
    _lastUsed = DetectionEngineKind.mobileBasic;
    return result;
  }

  Future<bool> _isAvailable(DetectionEngineAvailability? probe) async {
    if (probe == null) return true;
    try {
      return await probe();
    } on DetectionEngineUnavailableException {
      return false;
    }
  }
}
