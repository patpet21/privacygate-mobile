import 'package:flutter/foundation.dart';

enum ReplacementMode {
  reversible('reversible', 'Reversible placeholders'),
  generic('generic', 'Generic placeholders'),
  mask('mask', 'Masked values (keep last 4)'),
  redact('redact', 'Permanent redaction');

  const ReplacementMode(this.wireValue, this.label);
  final String wireValue;
  final String label;
}

enum VaultStoragePreset {
  mb500(500, '500 MB'),
  gb1_5(1536, '1.5 GB'),
  gb3(3072, '3 GB'),
  custom(-1, 'Custom');

  const VaultStoragePreset(this.megabytes, this.label);
  final int megabytes;
  final String label;
}

enum VaultRetentionPolicy {
  oneDay(1, '1 day'),
  sevenDays(7, '7 days'),
  thirtyDays(30, '30 days'),
  never(-1, 'Never');

  const VaultRetentionPolicy(this.days, this.label);
  final int days;
  final String label;
}

/// Application/Vault preferences only.
///
/// Profile, protection scope, replacement mode, confidence and scan language are
/// per-document controls and live in ProtectionPolicy, matching Desktop Protect.
class PrivacyGateSettings extends ChangeNotifier {
  VaultStoragePreset _vaultStoragePreset = VaultStoragePreset.gb1_5;
  int _customVaultMegabytes = 1536;
  VaultRetentionPolicy _retention = VaultRetentionPolicy.sevenDays;
  bool _requireDeviceAuthForRestore = true;
  bool _syncWhenDesktopAvailable = true;
  bool _removeMobileCopyAfterSync = false;

  VaultStoragePreset get vaultStoragePreset => _vaultStoragePreset;
  int get customVaultMegabytes => _customVaultMegabytes;
  VaultRetentionPolicy get retention => _retention;
  bool get requireDeviceAuthForRestore => _requireDeviceAuthForRestore;
  bool get syncWhenDesktopAvailable => _syncWhenDesktopAvailable;
  bool get removeMobileCopyAfterSync => _removeMobileCopyAfterSync;

  int get effectiveVaultMegabytes => _vaultStoragePreset == VaultStoragePreset.custom
      ? _customVaultMegabytes
      : _vaultStoragePreset.megabytes;

  void setVaultStoragePreset(VaultStoragePreset value) {
    if (_vaultStoragePreset == value) return;
    _vaultStoragePreset = value;
    notifyListeners();
  }

  void setCustomVaultMegabytes(int value) {
    if (value < 100) {
      throw ArgumentError.value(value, 'value', 'Vault limit must be at least 100 MB.');
    }
    if (_customVaultMegabytes == value) return;
    _customVaultMegabytes = value;
    notifyListeners();
  }

  void setRetention(VaultRetentionPolicy value) {
    if (_retention == value) return;
    _retention = value;
    notifyListeners();
  }

  void setRequireDeviceAuthForRestore(bool value) {
    if (_requireDeviceAuthForRestore == value) return;
    _requireDeviceAuthForRestore = value;
    notifyListeners();
  }

  void setSyncWhenDesktopAvailable(bool value) {
    if (_syncWhenDesktopAvailable == value) return;
    _syncWhenDesktopAvailable = value;
    notifyListeners();
  }

  void setRemoveMobileCopyAfterSync(bool value) {
    if (_removeMobileCopyAfterSync == value) return;
    _removeMobileCopyAfterSync = value;
    notifyListeners();
  }
}
