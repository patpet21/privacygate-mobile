import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/settings/privacy_gate_settings.dart';

void main() {
  test('contract: Vault defaults match PrivacyGate mobile policy', () {
    final settings = PrivacyGateSettings();

    expect(settings.vaultStoragePreset, VaultStoragePreset.gb1_5);
    expect(settings.retention, VaultRetentionPolicy.sevenDays);
    expect(settings.requireDeviceAuthForRestore, isTrue);
    expect(settings.syncWhenDesktopAvailable, isTrue);
    expect(settings.removeMobileCopyAfterSync, isFalse);
  });
}
