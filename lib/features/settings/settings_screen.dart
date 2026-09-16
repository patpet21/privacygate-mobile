import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';
import '../../core/settings/privacy_gate_settings.dart';
import 'settings_module_screen.dart';
import '../../core/desktop_link/desktop_link_client.dart';
import 'desktop_connection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.settings, this.desktopLink, super.key});
  final DesktopLinkClient? desktopLink;

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

  void _openModule(SettingsModule module) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsModuleScreen(module: module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return PgPage(
      children: [
        const PgHeader(),
        const PgTitle(
          title: 'Settings',
          subtitle: 'Manage device privacy, Desktop pairing, services, AI access and organization controls.',
        ),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Desktop connection'),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.desktopLink == null ? null : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => DesktopConnectionScreen(client: widget.desktopLink!)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PgIconBox(icon: Icons.laptop_mac_outlined),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Desktop connection',
                              style: TextStyle(
                                color: PgColors.navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pair securely and explicitly enable Desktop-assisted analysis.',
                              style: TextStyle(color: PgColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const Divider(height: 28),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.sync_rounded),
                title: const Text('Selective Library transfer'),
                subtitle: const Text('Not available yet. Pairing does not synchronize files.'),
                value: false,
                onChanged: null,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Mobile Vault',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Offline capacity, cleanup and post-sync retention on this device.',
                          style: TextStyle(color: PgColors.textSecondary, height: 1.3),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Restore security',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Keep restore mappings local and protect restore with device authentication.',
                          style: TextStyle(color: PgColors.textSecondary, height: 1.3),
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
                subtitle: const Text('Native enforcement will use Android/iOS secure storage.'),
                value: settings.requireDeviceAuthForRestore,
                onChanged: settings.setRequireDeviceAuthForRestore,
              ),
              const Divider(height: 24),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.offline_pin_outlined, color: PgColors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Encrypted offline persistence becomes active after the native Keystore/Keychain adapter is implemented.',
                      style: TextStyle(color: PgColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'PrivacyGate controls',
          style: TextStyle(
            color: PgColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Desktop capabilities are grouped into touch-first modules instead of compressing the Desktop sidebar into mobile navigation.',
          style: TextStyle(color: PgColors.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 14),
        _SettingsGroup(
          title: 'Core services',
          modules: const [
            SettingsModule.accountDevices,
            SettingsModule.workspaces,
            SettingsModule.services,
          ],
          onOpen: _openModule,
        ),
        const SizedBox(height: 12),
        _SettingsGroup(
          title: 'Data, AI & governance',
          modules: const [
            SettingsModule.apps,
            SettingsModule.aiMcp,
            SettingsModule.governance,
            SettingsModule.policyCenter,
          ],
          onOpen: _openModule,
        ),
        const SizedBox(height: 12),
        _SettingsGroup(
          title: 'Organization',
          modules: const [
            SettingsModule.team,
            SettingsModule.devices,
          ],
          onOpen: _openModule,
        ),
        const SizedBox(height: 12),
        _SettingsGroup(
          title: 'Application',
          modules: const [SettingsModule.appInfo],
          onOpen: _openModule,
        ),
        const SizedBox(height: 16),
        const PgCard(
          backgroundColor: Color(0xFFF3F7FF),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PgIconBox(icon: Icons.architecture_outlined, size: 40),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mobile parity preserves Desktop logic and privacy boundaries, but uses lists, drill-down pages and vertical cards so controls remain readable on phone-size screens.',
                  style: TextStyle(color: PgColors.textSecondary, height: 1.35),
                ),
              ),
            ],
          ),
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.modules,
    required this.onOpen,
  });

  final String title;
  final List<SettingsModule> modules;
  final ValueChanged<SettingsModule> onOpen;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                color: PgColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (var index = 0; index < modules.length; index++) ...[
            _SettingsModuleTile(
              module: modules[index],
              onTap: () => onOpen(modules[index]),
            ),
            if (index != modules.length - 1)
              const Divider(height: 1, indent: 62, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SettingsModuleTile extends StatelessWidget {
  const _SettingsModuleTile({required this.module, required this.onTap});

  final SettingsModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: PgIconBox(icon: module.icon, size: 38),
      title: Text(
        module.title,
        style: const TextStyle(
          color: PgColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        module.subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: PgColors.textSecondary, height: 1.25),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
