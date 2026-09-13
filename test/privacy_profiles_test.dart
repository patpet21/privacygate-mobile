import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/profiles/privacy_profiles.dart';

void main() {
  test('canonical profile keys match Desktop audit', () {
    expect(
      profiles.map((profile) => profile.key).toList(),
      [
        'general_business',
        'property_management',
        'realtor_brokerage',
        'projects_renovations',
        'construction',
        'legal',
        'healthcare_general',
      ],
    );
  });

  test('canonical scope keys match Desktop audit', () {
    expect(
      scopes.map((scope) => scope.key).toList(),
      ['essential', 'financial', 'business', 'maximum', 'custom'],
    );
  });

  test('property management profile includes real-estate-sensitive entities', () {
    final profile = getProfile('property_management');
    expect(profile.entities, contains('TENANT_ID'));
    expect(profile.entities, contains('RENT_AMOUNT'));
    expect(profile.entities, contains('PROPERTY_ACCESS_CODE'));
  });
}
