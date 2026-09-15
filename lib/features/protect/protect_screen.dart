import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/mobile_design.dart';
import '../../core/profiles/document_languages.dart';
import '../../core/profiles/privacy_profiles.dart';
import '../../core/settings/privacy_gate_settings.dart';
import 'protect_controller.dart';

class ProtectScreen extends StatefulWidget {
  const ProtectScreen({required this.controller, super.key});

  final ProtectController controller;

  @override
  State<ProtectScreen> createState() => _ProtectScreenState();
}

class _ProtectScreenState extends State<ProtectScreen> {
  final _text = TextEditingController();
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _text.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _text.removeListener(_refresh);
    _text.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _showPasteDialog() async {
    final draft = TextEditingController(text: _text.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste text'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: draft,
            autofocus: true,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText:
                  'Paste an email, lease excerpt, offer, proposal, or other text.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(draft.text),
            child: const Text('Use text'),
          ),
        ],
      ),
    );
    draft.dispose();
    if (value == null) return;
    _text.text = value;
    widget.controller.clear();
    setState(() => _reviewing = false);
  }

  Future<void> _showScanOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final policy = widget.controller.policy;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Scan options',
                    style: TextStyle(
                      color: PgColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'These apply to this document only. Scan language is separate from the app-interface language.',
                    style:
                        TextStyle(color: PgColors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    key: ValueKey('scope-${policy.scopeKey}'),
                    initialValue: policy.scopeKey,
                    decoration: const InputDecoration(
                      labelText: 'Protection scope',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final scope in scopes)
                        DropdownMenuItem(
                          value: scope.key,
                          child: Text(scope.name),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      policy.setScopeKey(value);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ReplacementMode>(
                    key: ValueKey('mode-${policy.replacementMode.name}'),
                    initialValue: policy.replacementMode,
                    decoration: const InputDecoration(
                      labelText: 'Protection mode',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final mode in ReplacementMode.values)
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      policy.setReplacementMode(value);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('language-${policy.scanLanguage}'),
                    initialValue: policy.scanLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Scan language',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final language in documentLanguages)
                        DropdownMenuItem(
                          value: language.code,
                          child: Text(language.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      policy.setScanLanguage(value);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detection confidence',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(policy.confidenceThreshold.toStringAsFixed(2)),
                    ],
                  ),
                  Slider(
                    min: 0.10,
                    max: 0.95,
                    divisions: 17,
                    value: policy.confidenceThreshold,
                    onChanged: (value) {
                      policy.setConfidenceThreshold(value);
                      setSheetState(() {});
                    },
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _scan() async {
    if (_text.text.trim().isEmpty || widget.controller.analyzing) return;
    await widget.controller.analyze(_text.text);
    if (!mounted) return;
    setState(() => _reviewing = true);
  }

  void _notReady(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label is planned for a later mobile integration pass.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _reviewing ? _buildReview(context) : _buildImport(context);
  }

  Widget _buildImport(BuildContext context) {
    final state = widget.controller;
    final policy = state.policy;
    final primaryProfiles = profiles.take(4).toList(growable: false);

    return PgPage(
      children: [
        const PgHeader(),
        const PgTitle(
          title: 'Protect data',
          subtitle:
              'Import your files, messages, or content to scan and protect.',
        ),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Import from'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78,
                children: [
                  _ImportTile(
                    icon: Icons.content_paste_outlined,
                    title: 'Paste text',
                    subtitle: _text.text.trim().isEmpty
                        ? 'Add text or sensitive content'
                        : '${_text.text.trim().length} characters ready',
                    active: _text.text.trim().isNotEmpty,
                    onTap: _showPasteDialog,
                  ),
                  _ImportTile(
                    icon: Icons.upload_file_outlined,
                    title: 'Upload file',
                    subtitle: 'PDF, DOCX, XLSX, PPT and more',
                    onTap: () => _notReady('File import'),
                  ),
                  _ImportTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Scan with camera',
                    subtitle: 'Scan documents and photos',
                    onTap: () => _notReady('Camera scan'),
                  ),
                  _ImportTile(
                    icon: Icons.mail_outline,
                    title: 'Gmail',
                    subtitle: 'Import from your inbox',
                    onTap: () => _notReady('Gmail import'),
                  ),
                  _ImportTile(
                    icon: Icons.cloud_outlined,
                    title: 'Google Drive',
                    subtitle: 'Import from your Drive',
                    onTap: () => _notReady('Google Drive import'),
                  ),
                  _ImportTile(
                    icon: Icons.folder_outlined,
                    title: 'Local files',
                    subtitle: 'Browse files on this device',
                    onTap: () => _notReady('Local file picker'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Protection profile'),
              const Text(
                'Choose how to categorize and protect this content.',
                style: TextStyle(color: PgColors.textSecondary),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: primaryProfiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final profile = primaryProfiles[index];
                  final selected = policy.profileKey == profile.key;
                  return _ProfileTile(
                    profile: profile,
                    selected: selected,
                    onTap: () => policy.setProfileKey(profile.key),
                  );
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const ValueKey('scan-options'),
                onPressed: _showScanOptions,
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  'Scan options · ${policy.scanLanguage.toUpperCase()} · ${getScope(policy.scopeKey).name}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          backgroundColor: const Color(0xFFF3F7FF),
          child: const Row(
            children: [
              PgIconBox(icon: Icons.desktop_windows_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desktop Vault sync is not connected yet',
                      style: TextStyle(
                        color: PgColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'This build protects text locally. Desktop pairing and encrypted Vault persistence come next.',
                      style: TextStyle(
                        color: PgColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Row(
            children: [
              const PgIconBox(icon: Icons.description_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current import',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _text.text.trim().isEmpty
                          ? 'No content selected yet'
                          : 'Pasted text · ${_text.text.trim().length} characters',
                      style: const TextStyle(color: PgColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_text.text.trim().isNotEmpty)
                IconButton(
                  tooltip: 'Clear import',
                  onPressed: () {
                    _text.clear();
                    state.clear();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            key: const ValueKey('continue-scan'),
            onPressed:
                _text.text.trim().isEmpty || state.analyzing ? null : _scan,
            icon: state.analyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              state.analyzing ? 'Scanning locally…' : 'Continue to scan',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final state = widget.controller;
    final categories = <String, int>{};
    for (final finding in state.findings) {
      categories.update(
        finding.entityType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return PgPage(
      children: [
        const PgHeader(),
        TextButton.icon(
          onPressed: () => setState(() => _reviewing = false),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to import'),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
        ),
        const SizedBox(height: 4),
        const PgTitle(
          title: 'Review detections',
          subtitle: 'Review found sensitive data and choose what to protect.',
        ),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PgIconBox(icon: Icons.description_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pasted text',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${state.findings.length} detections · ${state.policy.profile.name}',
                          style: const TextStyle(color: PgColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (categories.isNotEmpty) ...[
                const Divider(height: 28),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in categories.entries)
                      Chip(
                        avatar: Icon(_entityIcon(entry.key), size: 18),
                        label: Text(
                          '${_friendlyEntity(entry.key)} ${entry.value}',
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PgSectionHeader(
                      title: 'Detected items (${state.findings.length})',
                    ),
                  ),
                  Text(
                    '${state.selectedCount} protect',
                    style: const TextStyle(
                      color: PgColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Text(
                'Switch off an item to keep it unchanged.',
                style: TextStyle(color: PgColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: state.selectAll,
                    child: const Text('Protect all'),
                  ),
                  OutlinedButton(
                    onPressed: state.keepAll,
                    child: const Text('Keep all'),
                  ),
                  OutlinedButton(
                    onPressed: state.invertSelection,
                    child: const Text('Invert'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showManualFindingDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add missed item'),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (state.findings.isEmpty)
                const PgEmptyState(
                  icon: Icons.verified_user_outlined,
                  title: 'No sensitive items found',
                  body:
                      'You can go back, change scan options, or add a missed item manually after rescanning.',
                )
              else
                for (final finding in state.findings)
                  Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: PgIconBox(
                          icon: _entityIcon(finding.entityType),
                          size: 38,
                        ),
                        title: Text(
                          finding.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(_friendlyEntity(finding.entityType)),
                        value: state.selectedFindingIds
                            .contains(finding.findingId),
                        onChanged: (value) =>
                            state.setSelected(finding.findingId, value),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Protected output'),
              const SizedBox(height: 4),
              Text(
                state.result == null
                    ? 'Protect selected items, then PrivacyGate performs a second local scan before copy/restore actions are enabled.'
                    : _verificationMessage(state),
                style: TextStyle(
                  color: state.verificationError != null ||
                          state.residualFindings.isNotEmpty
                      ? Theme.of(context).colorScheme.error
                      : PgColors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (state.result != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PgColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PgColors.border),
                  ),
                  child: SelectableText(state.result!.protectedText),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: state.exportVerified ? _copyProtected : null,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy protected'),
                    ),
                    if (state.result!.replacementMode ==
                        ReplacementMode.reversible.wireValue)
                      OutlinedButton.icon(
                        onPressed: state.result!.mappings.isEmpty
                            ? null
                            : state.restoreLocally,
                        icon: const Icon(Icons.lock_open_outlined),
                        label: const Text('Restore locally'),
                      ),
                  ],
                ),
              ],
              if (state.restoredText.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Restored locally',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(state.restoredText),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: state.selectedCount == 0 || state.verificationRunning
                ? null
                : state.protectAndVerify,
            icon: state.verificationRunning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shield_rounded),
            label: Text(
              state.verificationRunning
                  ? 'Protecting & verifying…'
                  : 'Protect & verify (${state.selectedCount})',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vault save is intentionally not shown as completed: encrypted Mobile Vault persistence and Desktop pairing are not implemented yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PgColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Future<void> _copyProtected() async {
    final result = widget.controller.result;
    if (result == null || !widget.controller.exportVerified) return;
    await Clipboard.setData(ClipboardData(text: result.protectedText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Protected text copied.')),
    );
  }

  Future<void> _showManualFindingDialog() async {
    final valueController = TextEditingController();
    final entities = widget.controller.policy.enabledEntities;
    var entityType = entities.contains('PERSON')
        ? 'PERSON'
        : (entities.isEmpty ? 'CUSTOM' : entities.first);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add missed item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Value exactly as it appears',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: entityType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  if (entities.isEmpty)
                    const DropdownMenuItem(
                      value: 'CUSTOM',
                      child: Text('CUSTOM'),
                    ),
                  for (final entity in entities)
                    DropdownMenuItem(value: entity, child: Text(entity)),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => entityType = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                widget.controller
                    .addManualFinding(valueController.text, entityType);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    valueController.dispose();
  }

  String _verificationMessage(ProtectController state) {
    if (state.verificationRunning) return 'Running the second local scan…';
    if (state.verificationError != null) {
      return 'Second scan failed. Copy/export remains blocked.';
    }
    if (state.residualFindings.isNotEmpty) {
      return 'Second scan found ${state.residualFindings.length} residual sensitive item(s). Copy/export remains blocked.';
    }
    if (state.verificationPerformed) {
      return 'Second local scan passed. Protected copy actions are enabled.';
    }
    return 'Second local scan has not run yet.';
  }

  IconData _entityIcon(String entity) {
    if (entity.contains('EMAIL')) return Icons.mail_outline_rounded;
    if (entity.contains('PHONE')) return Icons.phone_outlined;
    if (entity.contains('ADDRESS') || entity.contains('LOCATION')) {
      return Icons.location_on_outlined;
    }
    if (entity.contains('BANK') ||
        entity.contains('CARD') ||
        entity.contains('MONEY')) {
      return Icons.account_balance_outlined;
    }
    if (entity.contains('ORGANIZATION')) return Icons.business_outlined;
    if (entity.contains('PERSON')) return Icons.person_outline_rounded;
    return Icons.privacy_tip_outlined;
  }

  String _friendlyEntity(String entity) => entity
      .toLowerCase()
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

class _ImportTile extends StatelessWidget {
  const _ImportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF2F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? PgColors.blue : PgColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PgIconBox(icon: icon),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PgColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PgColors.textSecondary,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final PrivacyProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (profile.key) {
      'property_management' => Icons.home_work_outlined,
      'realtor_brokerage' => Icons.person_pin_circle_outlined,
      'projects_renovations' => Icons.handyman_outlined,
      _ => Icons.description_outlined,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF2F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? PgColors.blue : PgColors.border),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PgIconBox(icon: icon, size: 40),
                const SizedBox(height: 8),
                Text(
                  profile.name.replaceAll(' — Recommended', ''),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? PgColors.blue : const Color(0xFFB4BDCE),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
