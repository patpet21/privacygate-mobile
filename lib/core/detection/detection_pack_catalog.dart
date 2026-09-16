import 'dart:convert';

import 'generated_detection_pack.dart';

class DetectionPackCatalog {
  DetectionPackCatalog._(this._value) {
    if (_value['schema'] != 'privacygate-detection-pack') {
      throw StateError('Unsupported PrivacyGate detection pack schema');
    }
    final version = _value['schema_version'];
    if (version is! int || version < 1) {
      throw StateError('Invalid PrivacyGate detection pack version');
    }
    final hash = _value['sha256'];
    if (hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw StateError('Invalid PrivacyGate detection pack digest');
    }
  }

  factory DetectionPackCatalog.generated() {
    final decoded = jsonDecode(generatedDetectionPackJson);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('PrivacyGate detection pack must be a JSON object');
    }
    return DetectionPackCatalog._(decoded);
  }

  final Map<String, dynamic> _value;

  int get schemaVersion => _value['schema_version'] as int;
  String get sha256 => _value['sha256'] as String;
  String get defaultProfileKey => _requiredString('default_profile_key');
  String get defaultScopeKey => _requiredString('default_scope_key');
  String get defaultLanguage => _requiredString('default_language');

  List<Map<String, dynamic>> get profileValues => _objectList('profiles');
  List<Map<String, dynamic>> get scopeValues => _objectList('scopes');
  List<Map<String, dynamic>> get languageValues => _objectList('languages');

  List<String> get allEntities => List<String>.unmodifiable(
        (_value['all_entities'] as List<dynamic>).cast<String>(),
      );

  List<String> get semanticEntities => List<String>.unmodifiable(
        (_value['semantic_entities'] as List<dynamic>).cast<String>(),
      );

  Map<String, dynamic> profileValue(String key) =>
      profileValues.firstWhere((value) => value['key'] == key);

  Map<String, dynamic> scopeValue(String key) =>
      scopeValues.firstWhere((value) => value['key'] == key);

  List<String> group(String key) {
    final groups = _value['entity_groups'];
    if (groups is! Map<String, dynamic>) {
      throw StateError('Detection pack entity_groups are invalid');
    }
    final value = groups[key];
    if (value is! List<dynamic>) {
      throw StateError('Detection pack is missing entity group $key');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  String engineKind(String key) {
    final engines = _value['engines'];
    if (engines is! Map<String, dynamic>) {
      throw StateError('Detection pack engines are invalid');
    }
    final engine = engines[key];
    if (engine is! Map<String, dynamic>) {
      throw StateError('Detection pack is missing engine $key');
    }
    final kind = engine['kind'];
    if (kind is! String || kind.isEmpty) {
      throw StateError('Detection pack engine $key is invalid');
    }
    return kind;
  }

  String _requiredString(String key) {
    final value = _value[key];
    if (value is! String || value.isEmpty) {
      throw StateError('Detection pack is missing $key');
    }
    return value;
  }

  List<Map<String, dynamic>> _objectList(String key) {
    final value = _value[key];
    if (value is! List<dynamic>) {
      throw StateError('Detection pack is missing $key');
    }
    return List<Map<String, dynamic>>.unmodifiable(
      value.map((item) {
        if (item is! Map<String, dynamic>) {
          throw StateError('Detection pack $key contains an invalid item');
        }
        return item;
      }),
    );
  }
}

final DetectionPackCatalog detectionPackCatalog = DetectionPackCatalog.generated();
