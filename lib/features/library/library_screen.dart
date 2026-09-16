import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';
import '../../core/mobile_link/desktop_connection.dart';
import '../../core/mobile_link/mobile_link_client.dart';
import '../../core/mobile_link/protected_copy.dart';
import '../../core/settings/privacy_gate_settings.dart';
import '../../core/vault/protected_library_repository.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    required this.settings,
    required this.connectionStore,
    required this.repository,
    super.key,
  });

  final PrivacyGateSettings settings;
  final DesktopConnectionStore connectionStore;
  final ProtectedLibraryRepository repository;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  var _filter = 0;
  bool _busy = false;
  DesktopConnection? _connection;
  List<ProtectedCopyGrant> _available = const [];
  List<ProtectedCopyDocument> _local = const [];
  String? _message;

  static const _filters = [
    _LibraryFilterData('All', Icons.done_rounded),
    _LibraryFilterData('Desktop', Icons.desktop_windows_outlined),
    _LibraryFilterData('Mobile Offline', Icons.phone_android_outlined),
    _LibraryFilterData('Restorable', Icons.restore_rounded),
    _LibraryFilterData('Favorites', Icons.star_border_rounded),
  ];

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_settingsChanged);
    _loadLocalState();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_settingsChanged);
    super.dispose();
  }

  void _settingsChanged() => setState(() {});

  Future<void> _loadLocalState() async {
    final connection = await widget.connectionStore.load();
    final local = await widget.repository.list();
    if (!mounted) return;
    setState(() {
      _connection = connection;
      _local = local;
    });
  }

  Future<void> _refreshFromDesktop() async {
    final connection = await widget.connectionStore.load();
    if (connection == null) {
      if (!mounted) return;
      setState(() {
        _connection = null;
        _available = const [];
        _message = 'Pair a trusted Desktop in Settings before refreshing protected copies.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
      _connection = connection;
    });
    try {
      final grants = await MobileLinkClient(connection).listProtectedCopyGrants();
      if (!mounted) return;
      setState(() {
        _available = grants;
        _message = grants.isEmpty
            ? 'No protected copies are authorized for this device.'
            : '${grants.length} protected ${grants.length == 1 ? 'copy is' : 'copies are'} available from Desktop.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveGrant(ProtectedCopyGrant grant) async {
    final connection = await widget.connectionStore.load();
    if (connection == null) {
      if (mounted) setState(() => _message = 'Desktop pairing is no longer available.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final document = await MobileLinkClient(connection).fetchProtectedCopy(grant.grantId);
      await widget.repository.save(document);
      final local = await widget.repository.list();
      if (!mounted) return;
      setState(() {
        _local = local;
        _message = '${document.title} saved locally as a protected-only copy. No restore mapping was stored.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteLocal(ProtectedCopyDocument document) async {
    await widget.repository.delete(document.documentId);
    final local = await widget.repository.list();
    if (!mounted) return;
    setState(() {
      _local = local;
      _message = 'Mobile copy removed. The Desktop protected Library is unchanged.';
    });
  }

  bool _isSaved(String documentId) => _local.any((item) => item.documentId == documentId);

  List<ProtectedCopyDocument> get _filteredLocal {
    switch (_filter) {
      case 1:
        return _local.where((item) => item.sourceKind == 'protected').toList(growable: false);
      case 2:
        return _local;
      case 3:
        return const [];
      case 4:
        return _local.where((item) => item.favorite).toList(growable: false);
      default:
        return _local;
    }
  }

  int get _usedBytes => _local.fold<int>(
        0,
        (sum, item) => sum + utf8.encode(item.protectedText).length,
      );

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final capacityBytes = settings.effectiveVaultMegabytes * 1024 * 1024;
    final usage = capacityBytes == 0 ? 0.0 : (_usedBytes / capacityBytes).clamp(0.0, 1.0);
    final filtered = _filteredLocal;

    return PgPage(
      children: [
        const PgHeader(),
        const PgTitle(
          title: 'Library',
          subtitle: 'Protected copies kept on this device only when you explicitly save them.',
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
                'Protected-only copies are stored in platform secure storage and cannot restore original values.',
                style: TextStyle(color: PgColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: usage,
                  backgroundColor: const Color(0xFFE5EAF3),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _usedBytes < 1024 * 1024
                          ? '${(_usedBytes / 1024).toStringAsFixed(1)} KB used'
                          : '${(_usedBytes / (1024 * 1024)).toStringAsFixed(1)} MB used',
                      style: const TextStyle(color: PgColors.navy, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    _storageLabel(settings.effectiveVaultMegabytes),
                    style: const TextStyle(color: PgColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          backgroundColor: _connection == null ? const Color(0xFFFFF8EE) : PgColors.greenSoft,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final status = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PgIconBox(
                    icon: _connection == null ? Icons.link_off_rounded : Icons.desktop_windows_outlined,
                    foreground: _connection == null ? PgColors.textSecondary : PgColors.green,
                    background: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _connection == null ? 'Desktop not connected' : 'Trusted Desktop paired',
                          style: const TextStyle(
                            color: PgColors.navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _connection == null
                              ? 'Pair in Settings to receive explicitly authorized protected copies.'
                              : 'Refresh lists grants only. Nothing is saved automatically.',
                          style: const TextStyle(color: PgColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final refresh = OutlinedButton.icon(
                onPressed: _connection == null || _busy ? null : _refreshFromDesktop,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Refresh grants'),
              );
              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [status, const SizedBox(height: 12), refresh],
                );
              }
              return Row(children: [Expanded(child: status), const SizedBox(width: 12), refresh]);
            },
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, style: const TextStyle(color: PgColors.textSecondary)),
        ],
        const SizedBox(height: 16),
        if (_available.isNotEmpty)
          PgCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PgSectionHeader(title: 'Available from Desktop'),
                const SizedBox(height: 4),
                const Text(
                  'Each item was explicitly authorized for this paired device. Save is still manual.',
                  style: TextStyle(color: PgColors.textSecondary),
                ),
                const SizedBox(height: 10),
                for (var index = 0; index < _available.length; index++) ...[
                  _AvailableGrantTile(
                    grant: _available[index],
                    saved: _isSaved(_available[index].documentId),
                    busy: _busy,
                    onSave: () => _saveGrant(_available[index]),
                  ),
                  if (index != _available.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        if (_available.isNotEmpty) const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PgSectionHeader(title: 'Files in ${_filters[_filter].label.toLowerCase()}'),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                PgEmptyState(
                  icon: _filters[_filter].icon,
                  title: 'No files here yet',
                  body: _emptyStateBody(_filter),
                )
              else
                for (var index = 0; index < filtered.length; index++) ...[
                  _LocalDocumentTile(
                    document: filtered[index],
                    onDelete: () => _deleteLocal(filtered[index]),
                  ),
                  if (index != filtered.length - 1) const Divider(height: 1),
                ],
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
                  'Protected-copy transfer accepts only mode=protected_copy with has_mapping=false. Any mapping-bearing payload is rejected before local persistence.',
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
        return 'Desktop-protected copies you explicitly saved appear here.';
      case 2:
        return 'Files explicitly saved for offline mobile access appear here.';
      case 3:
        return 'Protected-only Desktop copies are intentionally not restorable offline.';
      case 4:
        return 'Favorite protected files appear here.';
      default:
        return 'Refresh Desktop grants, then choose Save to Library on the specific item you want offline.';
    }
  }
}

class _AvailableGrantTile extends StatelessWidget {
  const _AvailableGrantTile({
    required this.grant,
    required this.saved,
    required this.busy,
    required this.onSave,
  });

  final ProtectedCopyGrant grant;
  final bool saved;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PgIconBox(icon: Icons.shield_outlined, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grant.title,
                  style: const TextStyle(color: PgColors.navy, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${grant.findingsCount} protected finding(s) · Protected only · No mapping',
                  style: const TextStyle(color: PgColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: saved || busy ? null : onSave,
            child: Text(saved ? 'Saved' : 'Save to Library'),
          ),
        ],
      ),
    );
  }
}

class _LocalDocumentTile extends StatelessWidget {
  const _LocalDocumentTile({required this.document, required this.onDelete});

  final ProtectedCopyDocument document;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PgIconBox(icon: Icons.offline_pin_outlined, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(color: PgColors.navy, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Protected only · Stored locally · Cannot restore originals',
                  style: TextStyle(color: PgColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  document.protectedText.replaceAll('\n', ' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: PgColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove mobile copy',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _LibraryFilterBar extends StatelessWidget {
  const _LibraryFilterBar({required this.selected, required this.onSelected});

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
