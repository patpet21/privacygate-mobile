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

  static const _filters = [
    _LibraryFilterData('All', Icons.done_rounded),
    _LibraryFilterData('Desktop', Icons.desktop_windows_outlined),
    _LibraryFilterData('Mobile Offline', Icons.phone_android_outlined),
    _LibraryFilterData('Restoreable', Icons.restore_rounded),
    _LibraryFilterData('Favorites', Icons.star_border_rounded),
  ];

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
        _LibraryFilterBar(
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 410;
              final status = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    status,
                    const SizedBox(height: 12),
                    const OutlinedButton(onPressed: null, child: Text('Sync now')),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 12),
                  const OutlinedButton(onPressed: null, child: Text('Sync now')),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PgSectionHeader(title: 'Files in ${_filters[_filter].label.toLowerCase()}'),
              const SizedBox(height: 18),
              PgEmptyState(
                icon: _filters[_filter].icon,
                title: 'No files here yet',
                body: _emptyStateBody(_filter),
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
        const SizedBox(height: 16),
        const PgCard(
          backgroundColor: Color(0xFFF3F7FF),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PgIconBox(icon: Icons.verified_user_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Library keeps Desktop parity at the data boundary: only protected copies can become available to AI. Originals and restore mappings remain outside MCP access.',
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
      final gigabytes = megabytes / 1024;
      return '${gigabytes.toStringAsFixed(gigabytes == gigabytes.roundToDouble() ? 0 : 1)} GB capacity';
    }
    return '$megabytes MB capacity';
  }

  String _emptyStateBody(int filter) {
    switch (filter) {
      case 1:
        return 'Desktop-protected documents appear here after a trusted pairing and sync.';
      case 2:
        return 'Files explicitly kept for offline mobile access appear here.';
      case 3:
        return 'Protected files with a local restore mapping appear here.';
      case 4:
        return 'Favorite protected files appear here.';
      default:
        return 'Protected files and offline sessions will appear here once Vault persistence is implemented.';
    }
  }
}

class _LibraryFilterBar extends StatelessWidget {
  const _LibraryFilterBar({
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: [
                for (var index = 0; index < _LibraryScreenState._filters.length; index++)
                  ButtonSegment(
                    value: index,
                    label: Text(_LibraryScreenState._filters[index].label),
                    icon: Icon(_LibraryScreenState._filters[index].icon),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (value) => onSelected(value.first),
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < _LibraryScreenState._filters.length; index++)
              ChoiceChip(
                avatar: Icon(
                  _LibraryScreenState._filters[index].icon,
                  size: 18,
                  color: selected == index ? PgColors.blue : PgColors.textSecondary,
                ),
                label: Text(_LibraryScreenState._filters[index].label),
                selected: selected == index,
                onSelected: (_) => onSelected(index),
              ),
          ],
        );
      },
    );
  }
}

class _LibraryFilterData {
  const _LibraryFilterData(this.label, this.icon);

  final String label;
  final IconData icon;
}
