import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';
import '../../core/settings/privacy_gate_settings.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({required this.settings, super.key});

  final PrivacyGateSettings settings;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  var _filter = 0;

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
          title: 'Library',
          subtitle: 'Your protected files, available everywhere.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('All')),
              ButtonSegment(value: 1, label: Text('Desktop'), icon: Icon(Icons.desktop_windows_outlined)),
              ButtonSegment(value: 2, label: Text('Mobile Offline'), icon: Icon(Icons.phone_android_outlined)),
              ButtonSegment(value: 3, label: Text('Favorites'), icon: Icon(Icons.star_border_rounded)),
            ],
            selected: {_filter},
            onSelectionChanged: (value) => setState(() => _filter = value.first),
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Mobile Vault'),
              const Text(
                'Secure storage for offline access on this device.',
                style: TextStyle(color: PgColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  minHeight: 10,
                  value: 0,
                  backgroundColor: Color(0xFFE5EAF3),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '0 MB used',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _storageLabel(settings.effectiveVaultMegabytes),
                    style: const TextStyle(color: PgColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          backgroundColor: PgColors.greenSoft,
          child: Row(
            children: [
              const PgIconBox(
                icon: Icons.desktop_windows_outlined,
                foreground: PgColors.green,
                background: Colors.white,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desktop not connected',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pairing and sync are not enabled in this build yet.',
                      style: TextStyle(color: PgColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton(onPressed: null, child: const Text('Sync now')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Files in your library'),
              const SizedBox(height: 18),
              PgEmptyState(
                icon: _filter == 3 ? Icons.star_border_rounded : Icons.folder_outlined,
                title: 'No files here yet',
                body: 'Protected files and offline sessions will appear here once Vault persistence is implemented.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Row(
            children: [
              const PgIconBox(icon: Icons.phone_android_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make available on mobile',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Offline download becomes available after Desktop pairing.',
                      style: TextStyle(color: PgColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }

  String _storageLabel(int megabytes) {
    if (megabytes >= 1024) {
      final gigabytes = megabytes / 1024;
      return '${gigabytes.toStringAsFixed(gigabytes == gigabytes.roundToDouble() ? 0 : 1)} GB capacity';
    }
    return '$megabytes MB capacity';
  }
}
