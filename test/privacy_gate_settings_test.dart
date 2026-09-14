import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/settings/privacy_gate_settings.dart';

void main() {
  test('contract: defaults match PrivacyGate product policy', () {
    final settings = PrivacyGateSettings();

    expect(settings.profileKey, 'general_business');
    expect(settings.scopeKey, 'maximum');
    expect(settings.language, 'en');
    expect(settings.replacementMode, ReplacementMode.reversible);
    expect(settings.vaultStoragePreset, VaultStoragePreset.gb1_5);
    expect(settings.retention, VaultRetentionPolicy.sevenDays);
    expect(settings.requireDeviceAuthForRestore, isTrue);
    expect(settings.syncWhenDesktopAvailable, isTrue);
    expect(settings.removeMobileCopyAfterSync, isFalse);
  });

  test('contract: profile and scope resolve canonical enabled entity set', () {
    final settings = PrivacyGateSettings()
      ..setProfileKey('property_management')
      ..setScopeKey('maximum');

    expect(settings.enabledEntities, contains('TENANT_ID'));
    expect(settings.enabledEntities, contains('RENT_AMOUNT'));
    expect(settings.enabledEntities, contains('PROPERTY_ACCESS_CODE'));
  });
}
