import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';
import '../../core/desktop_link/desktop_link_credential_store.dart';
import '../../core/desktop_link/desktop_protected_copy.dart';
import '../../core/desktop_link/desktop_protected_copy_client.dart';
import '../../core/domain/library_document.dart';
import '../../core/library/protected_library_service.dart';
import '../../core/settings/privacy_gate_settings.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    required this.settings,
    required this.active,
    required this.libraryProvider,
    required this.onOpenRestoreDocument,
    super.key,
  });

  final PrivacyGateSettings settings;
  final bool active;
  final Future<ProtectedLibraryService> Function() libraryProvider;
  final Future<void> Function(BuildContext context, LibraryDocument document)
      onOpenRestoreDocument;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DesktopProtectedCopyClient _desktopCopies =
      DesktopProtectedCopyClient(DesktopLinkCredentialStore());

  var _filter = 0;
  var _loading = false;
  var _desktopBusy = false;
  var _desktopPaired = false;
  var _usedBytes = 0;
  String? _error;
  String? _desktopMessage;
  String? _openingDocumentId;
  String? _savingGrantId;
  ProtectedLibraryService? _service;
  List<LibraryDocument> _documents = const [];
  List<DesktopProtectedCopyGrant> _desktopGrants = const [];

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
    widget.settings.addListener(_refreshSettings);
    if (widget.active) Future<void>.microtask(_ensureLoaded);
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.removeListener(_refreshSettings);
      widget.settings.addListener(_refreshSettings);
    }
    if (!oldWidget.active && widget.active) {
      Future<void>.microtask(_ensureLoaded);
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_refreshSettings);
    _service?.removeListener(_serviceChanged);
    super.dispose();
  }

  void _refreshSettings() {
    if (mounted) setState(() {});
  }

  void _serviceChanged() {
    if (mounted) _refreshDocuments();
  }

  Future<void> _ensureLoaded() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = await widget.libraryProvider();
      final paired = await _desktopCopies.hasCredential();
      if (!mounted) return;
      if (!identical(_service, service)) {
        _service?.removeListener(_serviceChanged);
        _service = service;
        service.addListener(_serviceChanged);
      }
      setState(() => _desktopPaired = paired);
      await _refreshDocuments(showLoading: false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshDocuments({bool showLoading = false}) async {
    final service = _service;
    if (service == null) return;
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final documents = await service.listDocuments();
      final usedBytes = await service.storageBytes();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _usedBytes = usedBytes;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (showLoading && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshDesktopTransfers() async {
    if (_desktopBusy) return;
    final paired = await _desktopCopies.hasCredential();
    if (!mounted) return;
    if (!paired) {
      setState(() {
        _desktopPaired = false;
        _desktopGrants = const [];
        _desktopMessage =
            'Pair a trusted Desktop in Settings before refreshing Desktop items.';
      });
      return;
    }

    setState(() {
      _desktopBusy = true;
      _desktopPaired = true;
      _desktopMessage = null;
    });
    try {
      final grants = await _desktopCopies.listGrants();
      if (!mounted) return;
      final fullCount = grants.where((grant) => grant.isFullOfflineSession).length;
      final protectedCount = grants.length - fullCount;
      setState(() {
        _desktopGrants = grants;
        if (grants.isEmpty) {
          _desktopMessage = 'No Library items are authorized for this device.';
        } else {
          final parts = <String>[];
          if (protectedCount > 0) {
            parts.add('$protectedCount protected ${protectedCount == 1 ? 'copy' : 'copies'}');
          }
          if (fullCount > 0) {
            parts.add('$fullCount full offline ${fullCount == 1 ? 'session' : 'sessions'}');
          }
          _desktopMessage = '${parts.join(' · ')} available from Desktop.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _desktopMessage =
            'Desktop is offline or unreachable. Open PrivacyGate Desktop and make sure Device Trust shows Online.';
      });
    } finally {
      if (mounted) setState(() => _desktopBusy = false);
    }
  }

  Future<void> _saveDesktopGrant(DesktopProtectedCopyGrant grant) async {
    if (_savingGrantId != null) return;
    setState(() {
      _savingGrantId = grant.grantId;
      _desktopMessage = null;
    });
    try {
      final service = _service ?? await widget.libraryProvider();
      if (!identical(_service, service)) {
        _service?.removeListener(_serviceChanged);
        _service = service;
        service.addListener(_serviceChanged);
      }
      final copy = await _desktopCopies.fetch(grant.grantId);
      if (copy.documentId != grant.documentId || copy.mode != grant.mode) {
        throw const DesktopProtectedCopyException(
          'Desktop returned a different item than the authorized grant.',
        );
      }
      final document = await service.saveDesktopTransfer(copy);
      await _refreshDocuments(showLoading: false);
      if (!mounted) return;
      setState(() {
        _desktopMessage = copy.isFullOfflineSession
            ? '${document.title} saved for offline Restore. The Restore mapping is stored separately in the encrypted Mobile Vault.'
            : '${document.title} saved locally as a protected-only copy. No Restore mapping was transferred.';
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _desktopMessage = message
            .replaceFirst('DesktopProtectedCopyException: ', '')
            .replaceFirst('StateError: ', '');
      });
    } finally {
      if (mounted) setState(() => _savingGrantId = null);
    }
  }

  LibraryDocument? _localDocumentFor(DesktopProtectedCopyGrant grant) {
    for (final document in _documents) {
      if (document.documentId == grant.localDocumentId) return document;
    }
    return null;
  }

  bool _isDesktopGrantSatisfied(DesktopProtectedCopyGrant grant) {
    final local = _localDocumentFor(grant);
    if (local == null) return false;
    return !grant.hasMapping || local.hasMapping;
  }

  String _grantActionLabel(DesktopProtectedCopyGrant grant) {
    final local = _localDocumentFor(grant);
    if (_savingGrantId == grant.grantId) return 'Saving…';
    if (grant.hasMapping && (local == null || !local.hasMapping)) {
      return local == null ? 'Save with offline Restore' : 'Enable offline Restore';
    }
    return local == null ? 'Save to Library' : 'Update local copy';
  }

  Future<void> _toggleFavorite(LibraryDocument document) async {
    final service = _service;
    if (service == null) return;
    try {
      await service.setFavorite(document.documentId, !document.favorite);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update favorite: $error')),
      );
    }
  }

  Future<void> _openRestore(LibraryDocument document) async {
    if (_openingDocumentId != null || !document.hasMapping) return;
    setState(() => _openingDocumentId = document.documentId);
    try {
      await widget.onOpenRestoreDocument(context, document);
    } finally {
      if (mounted) setState(() => _openingDocumentId = null);
    }
  }

  List<LibraryDocument> get _filteredDocuments {
    switch (_filter) {
      case 1:
        return _documents
            .where((document) => document.sourceKind == 'desktop')
            .toList(growable: false);
      case 2:
        return _documents
            .where((document) => document.sourceKind != 'desktop')
            .toList(growable: false);
      case 3:
        return _documents
            .where((document) => document.hasMapping)
            .toList(growable: false);
      case 4:
        return _documents
            .where((document) => document.favorite)
            .toList(growable: false);
      default:
        return _documents;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final capacityBytes = settings.effectiveVaultMegabytes * 1024 * 1024;
    final progress = capacityBytes <= 0
        ? 0.0
        : (_usedBytes / capacityBytes).clamp(0.0, 1.0).toDouble();
    final visibleDocuments = _filteredDocuments;

    return PgPage(
      children: [
        const PgHeader(),
        const PgTitle(
          title: 'Library',
          subtitle: 'Protected copies and restorable offline sessions saved locally on this device.',
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
                'Protected content stays in the Library. Restore mappings are stored separately in the encrypted device Vault.',
                style: TextStyle(color: PgColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: progress,
                  backgroundColor: const Color(0xFFE5EAF3),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatBytes(_usedBytes)} used',
                      style: const TextStyle(
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
          backgroundColor:
              _desktopPaired ? PgColors.greenSoft : const Color(0xFFFFF8EE),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 410;
              final status = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PgIconBox(
                    icon: _desktopPaired
                        ? Icons.desktop_windows_outlined
                        : Icons.link_off_rounded,
                    foreground: _desktopPaired
                        ? PgColors.green
                        : PgColors.textSecondary,
                    background: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _desktopPaired
                              ? 'Trusted Desktop paired'
                              : 'Desktop not connected',
                          style: const TextStyle(
                            color: PgColors.navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _desktopPaired
                              ? 'Refresh shows only Library items explicitly authorized for this device. Nothing downloads automatically.'
                              : 'Pair a trusted Desktop in Settings to receive explicitly authorized Library items.',
                          style: const TextStyle(color: PgColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final refreshButton = OutlinedButton.icon(
                onPressed: !_desktopPaired || _desktopBusy
                    ? null
                    : _refreshDesktopTransfers,
                icon: _desktopBusy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Desktop items'),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    status,
                    const SizedBox(height: 12),
                    refreshButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 12),
                  refreshButton,
                ],
              );
            },
          ),
        ),
        if (_desktopMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _desktopMessage!,
            style: const TextStyle(color: PgColors.textSecondary),
          ),
        ],
        if (_desktopGrants.isNotEmpty) ...[
          const SizedBox(height: 16),
          PgCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PgSectionHeader(title: 'Available from Desktop'),
                const SizedBox(height: 4),
                const Text(
                  'Protected copies contain no Restore mapping. Full offline sessions add a mapping to the encrypted Mobile Vault only after you explicitly save them.',
                  style: TextStyle(color: PgColors.textSecondary),
                ),
                const SizedBox(height: 10),
                for (var index = 0;
                    index < _desktopGrants.length;
                    index++) ...[
                  _DesktopGrantTile(
                    grant: _desktopGrants[index],
                    satisfied: _isDesktopGrantSatisfied(_desktopGrants[index]),
                    actionLabel: _grantActionLabel(_desktopGrants[index]),
                    saving: _savingGrantId == _desktopGrants[index].grantId,
                    disabled: _savingGrantId != null,
                    onSave: () => _saveDesktopGrant(_desktopGrants[index]),
                  ),
                  if (index != _desktopGrants.length - 1)
                    const Divider(height: 20),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PgSectionHeader(
                      title: 'Files in ${_filters[_filter].label.toLowerCase()}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh Library',
                    onPressed: _loading
                        ? null
                        : () => _refreshDocuments(showLoading: true),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading && _documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                PgEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Library unavailable',
                  body: _error!,
                )
              else if (visibleDocuments.isEmpty)
                PgEmptyState(
                  icon: _filters[_filter].icon,
                  title: 'No files here yet',
                  body: _emptyStateBody(_filter),
                )
              else
                for (var index = 0;
                    index < visibleDocuments.length;
                    index++) ...[
                  _LibraryDocumentTile(
                    document: visibleDocuments[index],
                    opening: _openingDocumentId ==
                        visibleDocuments[index].documentId,
                    onFavorite: () =>
                        _toggleFavorite(visibleDocuments[index]),
                    onRestore: visibleDocuments[index].hasMapping
                        ? () => _openRestore(visibleDocuments[index])
                        : null,
                  ),
                  if (index != visibleDocuments.length - 1)
                    const Divider(height: 20),
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
                  'Desktop transfer is always explicit and item-by-item. Protected copy never includes original values. Full offline session transfers the Restore mapping only through the authenticated pinned-TLS connection and immediately stores it separately in the AES-256-GCM Mobile Vault. There is no automatic Library sync.',
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    final megabytes = kilobytes / 1024;
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  String _emptyStateBody(int filter) {
    switch (filter) {
      case 1:
        return 'Desktop items you explicitly save appear here.';
      case 2:
        return 'Protected copies explicitly created on this mobile device appear here.';
      case 3:
        return 'Items with a Restore mapping encrypted in the local Mobile Vault appear here.';
      case 4:
        return 'Tap the star on a saved item to keep it in Favorites.';
      default:
        return 'Protect content locally, or refresh authorized Desktop items and explicitly save the ones you want offline.';
    }
  }
}

class _DesktopGrantTile extends StatelessWidget {
  const _DesktopGrantTile({
    required this.grant,
    required this.satisfied,
    required this.actionLabel,
    required this.saving,
    required this.disabled,
    required this.onSave,
  });

  final DesktopProtectedCopyGrant grant;
  final bool satisfied;
  final String actionLabel;
  final bool saving;
  final bool disabled;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final full = grant.isFullOfflineSession;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgIconBox(
              icon: full ? Icons.lock_clock_outlined : Icons.desktop_windows_outlined,
              foreground: full ? PgColors.purple : PgColors.blue,
              background: full ? PgColors.purpleSoft : PgColors.blueSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grant.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PgColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${grant.findingsCount} protected · ${_formatDate(grant.updatedAt)}',
                    style: const TextStyle(
                      color: PgColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (satisfied)
              const Icon(Icons.check_circle_rounded, color: PgColors.green),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _LibraryBadge(
              label: full ? 'FULL OFFLINE SESSION' : 'PROTECTED COPY',
              positive: full,
            ),
            _LibraryBadge(
              label: full ? 'ENCRYPTED RESTORE' : 'NO RESTORE',
              positive: full,
            ),
            for (final entity in grant.entityTypes.take(3))
              _LibraryBadge(label: entity.replaceAll('_', ' ')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          full
              ? 'Saving this item stores its Restore mapping separately in the encrypted Mobile Vault so Restore works offline.'
              : 'Saving this item stores protected content only. No original values or Restore mapping are downloaded.',
          style: const TextStyle(
            color: PgColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: disabled ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    satisfied ? Icons.sync_rounded : Icons.save_outlined,
                  ),
            label: Text(actionLabel),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int item) => item.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _LibraryDocumentTile extends StatelessWidget {
  const _LibraryDocumentTile({
    required this.document,
    required this.opening,
    required this.onFavorite,
    required this.onRestore,
  });

  final LibraryDocument document;
  final bool opening;
  final VoidCallback onFavorite;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgIconBox(
              icon: document.hasMapping
                  ? Icons.lock_clock_outlined
                  : Icons.description_outlined,
              foreground: document.hasMapping ? PgColors.purple : PgColors.blue,
              background:
                  document.hasMapping ? PgColors.purpleSoft : PgColors.blueSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PgColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${document.sourceName} · ${document.findingsCount} protected · ${_formatDate(document.updatedAt)}',
                    style: const TextStyle(
                      color: PgColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: document.favorite ? 'Remove favorite' : 'Add favorite',
              onPressed: onFavorite,
              icon: Icon(
                document.favorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: document.favorite
                    ? const Color(0xFFF0A000)
                    : PgColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _LibraryBadge(
              label: document.replacementMode.replaceAll('_', ' ').toUpperCase(),
              positive: document.hasMapping,
            ),
            if (document.sourceKind == 'desktop')
              const _LibraryBadge(label: 'DESKTOP'),
            if (document.hasMapping)
              const _LibraryBadge(label: 'RESTORABLE', positive: true),
            for (final entity in document.entityTypes.take(3))
              _LibraryBadge(label: entity.replaceAll('_', ' ')),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          document.protectedText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PgColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        if (document.hasMapping) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: opening ? null : onRestore,
              icon: opening
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore_rounded),
              label: Text(opening ? 'Opening…' : 'Open Restore'),
            ),
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int item) => item.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _LibraryBadge extends StatelessWidget {
  const _LibraryBadge({required this.label, this.positive = false});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? PgColors.greenSoft : const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: positive ? const Color(0xFFB7E8C7) : PgColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: positive ? PgColors.green : PgColors.blue,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
                for (var index = 0;
                    index < _LibraryScreenState._filters.length;
                    index++)
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
            for (var index = 0;
                index < _LibraryScreenState._filters.length;
                index++)
              ChoiceChip(
                avatar: Icon(
                  _LibraryScreenState._filters[index].icon,
                  size: 18,
                  color: selected == index
                      ? PgColors.blue
                      : PgColors.textSecondary,
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
