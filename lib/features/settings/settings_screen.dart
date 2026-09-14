import 'package:flutter/material.dart';

import '../../core/settings/privacy_gate_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.settings, super.key});

  final PrivacyGateSettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  String _storageLabel(int megabytes) {
    if (megabytes >= 1024) {
      final gb = megabytes / 1024;
      return '${gb.toStringAsFixed(gb.truncateToDouble() == gb ? 0 : 1)} GB';
    }
    return '$megabytes MB';
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Profile, protection scope, mode, confidence and scan language are document controls in Protect. Scan language selects the detector language; it is not the app-interface language.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Mobile Vault', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'These preferences define the local Vault policy. Encrypted persistence is enabled only after the native Keystore/Keychain layer is implemented.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<VaultStoragePreset>(
            value: settings.vaultStoragePreset,
            decoration: const InputDecoration(
              labelText: 'Storage limit',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final preset in VaultStoragePreset.values)
                DropdownMenuItem(value: preset, child: Text(preset.label)),
            ],
            onChanged: (value) {
              if (value != null) settings.setVaultStoragePreset(value);
            },
          ),
          if (settings.vaultStoragePreset == VaultStoragePreset.custom) ...[
            const SizedBox(height: 10),
            Text(
              'Custom limit: ${_storageLabel(settings.customVaultMegabytes)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              min: 100,
              max: 10240,
              divisions: 100,
              value: settings.customVaultMegabytes.clamp(100, 10240).toDouble(),
              label: _storageLabel(settings.customVaultMegabytes),
              onChanged: (value) => settings.setCustomVaultMegabytes(value.round()),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<VaultRetentionPolicy>(
            value: settings.retention,
            decoration: const InputDecoration(
              labelText: 'Automatic cleanup',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final policy in VaultRetentionPolicy.values)
                DropdownMenuItem(value: policy, child: Text(policy.label)),
            ],
            onChanged: (value) {
              if (value != null) settings.setRetention(value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.requireDeviceAuthForRestore,
            title: const Text('Require biometrics/device auth for restore'),
            onChanged: settings.setRequireDeviceAuthForRestore,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.syncWhenDesktopAvailable,
            title: const Text('Sync when Desktop is available'),
            onChanged: settings.setSyncWhenDesktopAvailable,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.removeMobileCopyAfterSync,
            title: const Text('Remove Mobile copy after successful sync'),
            subtitle: const Text('Never applies before Desktop acknowledges the transfer.'),
            onChanged: settings.setRemoveMobileCopyAfterSync,
          ),
        ],
      ),
    );
  }
}
