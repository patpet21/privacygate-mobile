import '../detection/detection_pack_catalog.dart';

class PrivacyProfile {
  const PrivacyProfile({
    required this.key,
    required this.name,
    required this.description,
    required this.entities,
    this.threshold = 0.35,
  });

  final String key;
  final String name;
  final String description;
  final List<String> entities;
  final double threshold;
}

class ProtectionScope {
  const ProtectionScope(this.key, this.name, this.description);

  final String key;
  final String name;
  final String description;
}

final String defaultProfileKey = detectionPackCatalog.defaultProfileKey;
final String defaultScopeKey = detectionPackCatalog.defaultScopeKey;

final List<PrivacyProfile> profiles = List<PrivacyProfile>.unmodifiable(
  detectionPackCatalog.profileValues.map((value) {
    return PrivacyProfile(
      key: value['key'] as String,
      name: value['name'] as String,
      description: value['description'] as String,
      threshold: (value['threshold'] as num).toDouble(),
      entities: List<String>.unmodifiable(
        (value['entities'] as List<dynamic>).cast<String>(),
      ),
    );
  }),
);

final List<ProtectionScope> scopes = List<ProtectionScope>.unmodifiable(
  detectionPackCatalog.scopeValues.map((value) {
    return ProtectionScope(
      value['key'] as String,
      value['name'] as String,
      value['description'] as String,
    );
  }),
);

PrivacyProfile getProfile(String key) =>
    profiles.firstWhere((profile) => profile.key == key);

ProtectionScope getScope(String key) =>
    scopes.firstWhere((scope) => scope.key == key);

List<String> allProfileEntities() => detectionPackCatalog.allEntities;

List<String> entitiesForScope(PrivacyProfile profile, String scopeKey) {
  final scope = detectionPackCatalog.scopeValue(scopeKey);

  switch (scope['mode']) {
    case 'all_profiles':
      return allProfileEntities();
    case 'profile':
      return List<String>.unmodifiable(profile.entities);
    case 'intersection':
      final allowed = <String>{};
      for (final groupName in (scope['groups'] as List<dynamic>).cast<String>()) {
        allowed.addAll(detectionPackCatalog.group(groupName));
      }
      return List<String>.unmodifiable(profile.entities.where(allowed.contains));
    default:
      throw StateError('Detection pack has unsupported scope mode ${scope['mode']}');
  }
}
