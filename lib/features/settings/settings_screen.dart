import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';
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

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return PgPage(
      children: [
        const PgHeader(),
        const PgTitle(
          title: 'Settings',
          subtitle: 'Manage your sync, storage, connections, and privacy preferences.',
        ),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Desktop connection'),
              const SizedBox(height: 12),
              const Row(
                children: [
                  PgIconBox(icon: Icons.laptop_mac_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not connected',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mobile pairing will be added in the Desktop companion pass.',
                          style: TextStyle(color: PgColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
              const Divider(height: 28),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.sync_rounded),
                title: const Text('Sync when desktop is available'),
                subtitle: const Text('Applies after a trusted Desktop connection exists.'),
                value: settings.syncWhenDesktopAvailable,
                onChanged: settings.setSyncWhenDesktopAvailable,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  PgIconBox(
                    icon: Icons.storage_outlined,
                    foreground: PgColors.purple,
                    background: PgColors.purpleSoft,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mobile Vault storage',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Choose how much space to use on this device.',
                          style: TextStyle(color: PgColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in VaultStoragePreset.values)
                    ChoiceChip(
                      label: Text(preset.label),
                      selected: settings.vaultStoragePreset == preset,
                      onSelected: (_) => settings.setVaultStoragePreset(preset),
                    ),
                ],
              ),
              if (settings.vaultStoragePreset == VaultStoragePreset.custom) ...[
                const SizedBox(height: 12),
                Text(
                  'Custom limit: ${_storageLabel(settings.customVaultMegabytes)}',
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Slider(
                  min: 100,
                  max: 10240,
                  divisions: 100,
                  value: settings.customVaultMegabytes.clamp(100, 10240).toDouble(),
                  onChanged: (value) => settings.setCustomVaultMegabytes(value.round()),
                ),
              ],
              const Divider(height: 28),
              DropdownButtonFormField<VaultRetentionPolicy>(
                key: ValueKey('retention-${settings.retention.name}'),
                initialValue: settings.retention,
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
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove mobile copy after successful sync'),
                subtitle: const Text('Never applies before Desktop acknowledges the transfer.'),
                value: settings.removeMobileCopyAfterSync,
                onChanged: settings.setRemoveMobileCopyAfterSync,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Row(
            children: [
              const PgIconBox(
                icon: Icons.offline_pin_outlined,
                foreground: PgColors.green,
                background: PgColors.greenSoft,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline mode',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Encrypted offline persistence is not active until the native Keystore/Keychain adapter is implemented.',
                      style: TextStyle(color: PgColors.textSecondary, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            children: [
              const Row(
                children: [
                  PgIconBox(
                    icon: Icons.fingerprint_rounded,
                    foreground: PgColors.purple,
                    background: PgColors.purpleSoft,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometric lock',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Add an extra layer of protection for restore.',
                          style: TextStyle(color: PgColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require biometrics/device auth for restore'),
                subtitle: const Text('Native enforcement will be wired to Android/iOS secure storage.'),
                value: settings.requireDeviceAuthForRestore,
                onChanged: settings.setRequireDeviceAuthForRestore,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PgSectionHeader(title: 'Connected apps'),
                    const SizedBox(height: 10),
                    const _ConnectionRow(icon: Icons.mail_outline, label: 'Gmail'),
                    const _ConnectionRow(icon: Icons.cloud_outlined, label: 'Google Drive'),
                    const _ConnectionRow(icon: Icons.folder_outlined, label: 'Local Files'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PgCard(
                backgroundColor: const Color(0xFFFBFAFF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PgSectionHeader(title: 'AI tools & MCP'),
                    const SizedBox(height: 10),
                    const PgIconBox(
                      icon: Icons.auto_awesome,
                      foreground: PgColors.purple,
                      background: PgColors.purpleSoft,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Use protected files with AI tools',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'MCP connection is not enabled in this build.',
                      style: TextStyle(color: PgColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: null, child: const Text('Manage AI tools')),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _SettingsShortcut(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Alerts and sync activity',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _SettingsShortcut(
                icon: Icons.shield_outlined,
                title: 'Privacy defaults',
                subtitle: 'Default privacy settings',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _storageLabel(int megabytes) {
    if (megabytes >= 1024) {
      final gb = megabytes / 1024;
      return '${gb.toStringAsFixed(gb.truncateToDouble() == gb ? 0 : 1)} GB';
    }
    return '$megabytes MB';
  }
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          PgIconBox(icon: icon, size: 34),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: PgColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const Text(
            'Off',
            style: TextStyle(color: PgColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SettingsShortcut extends StatelessWidget {
  const _SettingsShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      child: Row(
        children: [
          PgIconBox(icon: icon, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: PgColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}
