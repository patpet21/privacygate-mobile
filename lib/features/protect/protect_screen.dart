import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/mobile_design.dart';
import '../../core/profiles/document_languages.dart';
import '../../core/profiles/privacy_profiles.dart';
import '../../core/protection/protection_policy.dart';
import '../../core/settings/privacy_gate_settings.dart';
import 'protect_controller.dart';

class ProtectScreen extends StatefulWidget {
  const ProtectScreen({
    required this.controller,
    required this.onOpenRestore,
    super.key,
  });

  final ProtectController controller;
  final void Function(BuildContext context) onOpenRestore;

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
    var draftValue = _text.text;

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste text'),
        content: SizedBox(
          width: 520,
          child: TextFormField(
            initialValue: draftValue,
            autofocus: true,
            minLines: 8,
            maxLines: 14,
            onChanged: (value) => draftValue = value,
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
            onPressed: () => Navigator.of(dialogContext).pop(draftValue),
            child: const Text('Use text'),
          ),
        ],
      ),
    );

    if (!mounted || value == null) return;

    setState(() => _reviewing = false);
    _text.text = value;
    widget.controller.clear();
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
                    'Scan settings',
                    style: TextStyle(
                      color: PgColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'These settings apply to this document only. Everything is processed locally.',
                    style: TextStyle(
                      color: PgColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    key: ValueKey('profile-${policy.profileKey}'),
                    initialValue: policy.profileKey,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Protection profile',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final profile in profiles)
                        DropdownMenuItem(
                          value: profile.key,
                          child: Text(
                            profile.name.replaceAll(' — Recommended', ''),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      policy.setProfileKey(value);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('scope-${policy.scopeKey}'),
                    initialValue: policy.scopeKey,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Protection level',
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
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Protection mode',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final mode in ReplacementMode.values)
                        DropdownMenuItem(
                          value: mode,
                          child: Text(
                            mode.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                  const SizedBox(height: 4),
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

  Future<void> _showImportSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import source',
                style: TextStyle(
                  color: PgColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose where the document will come from. Mobile integrations that are not ready yet stay clearly marked.',
                style: TextStyle(
                  color: PgColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              _ImportSourceRow(
                icon: Icons.upload_file_outlined,
                title: 'Upload local',
                subtitle: 'PDF, DOCX, PPTX, XLSX, PNG, JPG, TXT and CSV',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notReady('Local file import');
                },
              ),
              _ImportSourceRow(
                icon: Icons.photo_camera_outlined,
                title: 'Scan with camera',
                subtitle: 'Printed documents and photos',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notReady('Camera scan');
                },
              ),
              _ImportSourceRow(
                icon: Icons.mail_outline_rounded,
                title: 'Gmail',
                subtitle: 'Choose an email to protect locally',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notReady('Gmail import');
                },
              ),
              _ImportSourceRow(
                icon: Icons.cloud_outlined,
                title: 'Google Drive',
                subtitle: 'Import a file from Drive',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notReady('Google Drive import');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHowItWorks() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How Protect works',
                style: TextStyle(
                  color: PgColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14),
              _HowItWorksRow(
                number: '1',
                title: 'Source',
                body: 'Paste text or choose the document source.',
              ),
              _HowItWorksRow(
                number: '2',
                title: 'Scan',
                body: 'PrivacyGate detects sensitive data locally.',
              ),
              _HowItWorksRow(
                number: '3',
                title: 'Review',
                body: 'Choose exactly which findings should be protected.',
              ),
              _HowItWorksRow(
                number: '4',
                title: 'Safe copy',
                body: 'Create and verify the protected copy before using it.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSafePreview() async {
    final state = widget.controller;
    final result = state.result;
    if (result == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safe preview',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _verificationMessage(state),
                  style: const TextStyle(
                    color: PgColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PgColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PgColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(result.protectedText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFullDocumentView() async {
    if (_text.text.trim().isEmpty && widget.controller.result == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final protectedText = widget.controller.result?.protectedText;
        return DefaultTabController(
          length: protectedText == null ? 1 : 2,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.78,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full document view',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      tabs: [
                        const Tab(text: 'Original'),
                        if (protectedText != null) const Tab(text: 'Protected'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _DocumentTextViewer(text: _text.text),
                          if (protectedText != null)
                            _DocumentTextViewer(text: protectedText),
                        ],
                      ),
                    ),
                  ],
                ),
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
        content: Text('$label is not connected in this mobile build yet.'),
      ),
    );
  }

  void _clearDocument() {
    _text.clear();
    widget.controller.clear();
    setState(() => _reviewing = false);
  }

  @override
  Widget build(BuildContext context) {
    return _reviewing ? _buildReview(context) : _buildSource(context);
  }

  Widget _buildSource(BuildContext context) {
    final state = widget.controller;
    final policy = state.policy;
    final hasSource = _text.text.trim().isNotEmpty;

    return PgPage(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _ProtectAppHeader(onMenuTap: () => _notReady('Navigation menu')),
        const SizedBox(height: 22),
        const PgTitle(
          title: 'Protect',
          subtitle:
              'Protect sensitive data locally before you share a document or use it with AI.',
        ),
        _WorkspaceCard(
          activeStep: 1,
          onHowItWorks: _showHowItWorks,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SourceModeBar(
                onPasteText: _showPasteDialog,
                onImportSource: _showImportSourceSheet,
                onFullView: hasSource ? _showFullDocumentView : null,
                onSafePreview: state.result == null ? null : _showSafePreview,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 390;
                  final language = _LanguageControl(policy: policy);
                  final settings = OutlinedButton.icon(
                    key: const ValueKey('scan-options'),
                    onPressed: _showScanOptions,
                    icon: const Icon(Icons.shield_outlined, size: 19),
                    label: const Text('Scan settings'),
                  );
                  final clear = OutlinedButton.icon(
                    onPressed: hasSource ? _clearDocument : null,
                    icon: const Icon(Icons.cancel_outlined, size: 19),
                    label: const Text('Clear'),
                  );

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        language,
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: settings),
                            const SizedBox(width: 8),
                            Expanded(child: clear),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 3, child: language),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: settings),
                      const SizedBox(width: 8),
                      Expanded(child: clear),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scanButton = FilledButton.icon(
                    key: const ValueKey('continue-scan'),
                    onPressed: !hasSource || state.analyzing ? null : _scan,
                    icon: state.analyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shield_outlined),
                    label: Text(
                      state.analyzing ? 'Scanning locally…' : 'Scan locally',
                    ),
                  );
                  final previewButton = OutlinedButton(
                    onPressed: state.result == null ? null : _showSafePreview,
                    child: const Text('Safe preview'),
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        scanButton,
                        const SizedBox(height: 8),
                        previewButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 3, child: scanButton),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: previewButton),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasSource ? _showFullDocumentView : null,
                      icon: const Icon(Icons.view_column_outlined, size: 19),
                      label: const Text('Full document view'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _InfoPill(
                      icon: Icons.palette_outlined,
                      label: 'Protected values use clear placeholders',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _OriginalDocumentCard(
          text: _text.text,
          onPasteText: _showPasteDialog,
          onChooseEmail: () => _notReady('Gmail import'),
          onUploadLocal: () => _notReady('Local file import'),
          onClear: hasSource ? _clearDocument : null,
        ),
        const SizedBox(height: 14),
        _ProtectedDocumentCard(
          state: state,
          onCopy: _copyProtected,
          onSafePreview: _showSafePreview,
          onRestore: state.hasLocalRestoreMapping ? state.restoreLocally : null,
          onOpenRestore: state.hasLocalRestoreMapping
              ? () => widget.onOpenRestore(context)
              : null,
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final state = widget.controller;
    final activeStep = state.result == null ? 3 : 4;
    final categories = <String, int>{};
    for (final finding in state.findings) {
      categories.update(
        finding.entityType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return PgPage(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _ProtectAppHeader(onMenuTap: () => _notReady('Navigation menu')),
        const SizedBox(height: 22),
        const PgTitle(
          title: 'Protect',
          subtitle:
              'Review sensitive data locally, then create a verified safe copy.',
        ),
        _WorkspaceCard(
          activeStep: activeStep,
          onHowItWorks: _showHowItWorks,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to source'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('scan-options'),
                      onPressed: _showScanOptions,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Scan settings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DocumentSummaryBar(
                detections: state.findings.length,
                profile: state.policy.profile.name,
                replacementMode: state.policy.replacementMode.label,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _OriginalDocumentCard(
          text: state.originalText,
          compact: true,
          onPasteText: _showPasteDialog,
          onChooseEmail: () => _notReady('Gmail import'),
          onUploadLocal: () => _notReady('Local file import'),
          onClear: _clearDocument,
        ),
        const SizedBox(height: 14),
        PgCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detected items (${state.findings.length})',
                      style: const TextStyle(
                        color: PgColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${state.selectedCount} protect',
                    style: const TextStyle(
                      color: PgColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Switch off an item to keep it unchanged.',
                style: TextStyle(color: PgColors.textSecondary),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in categories.entries)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(_entityIcon(entry.key), size: 17),
                        label: Text(
                          '${_friendlyEntity(entry.key)} ${entry.value}',
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
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
              const Divider(height: 26),
              if (state.findings.isEmpty)
                const PgEmptyState(
                  icon: Icons.verified_user_outlined,
                  title: 'No sensitive items found',
                  body:
                      'Go back and change scan settings, or add a missed item manually.',
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
        const SizedBox(height: 14),
        _ProtectedDocumentCard(
          state: state,
          onCopy: _copyProtected,
          onSafePreview: _showSafePreview,
          onRestore: state.hasLocalRestoreMapping ? state.restoreLocally : null,
          onOpenRestore: state.hasLocalRestoreMapping
              ? () => widget.onOpenRestore(context)
              : null,
        ),
        if (state.result == null) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              key: const ValueKey('protect-verify'),
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
                    ? 'Protecting locally…'
                    : 'Protect locally (${state.selectedCount})',
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Encrypted Mobile Vault persistence and Desktop pairing are not connected yet.',
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
    final entities = widget.controller.policy.enabledEntities;
    var entityType = entities.contains('PERSON')
        ? 'PERSON'
        : (entities.isEmpty ? 'CUSTOM' : entities.first);
    var valueText = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add missed item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                autofocus: true,
                onChanged: (value) => valueText = value,
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
                widget.controller.addManualFinding(valueText, entityType);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
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

class _ProtectAppHeader extends StatelessWidget {
  const _ProtectAppHeader({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final identity = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded, color: PgColors.navy),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: PgColors.blueSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: PgColors.blue,
                size: 23,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PrivacyGate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: PgColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Enterprise organization',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PgColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: PgColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        const badges = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _StatusPill(
              label: 'LOCAL PROCESSING',
              foreground: PgColors.green,
              background: PgColors.greenSoft,
            ),
            _StatusPill(
              label: 'READY',
              foreground: PgColors.textSecondary,
              background: Color(0xFFF0F2F6),
            ),
          ],
        );

        if (constraints.maxWidth < 390) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerRight, child: badges),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 8),
            badges,
          ],
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: foreground.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.activeStep,
    required this.onHowItWorks,
    required this.child,
  });

  final int activeStep;
  final VoidCallback onHowItWorks;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Document workspace',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onHowItWorks,
                icon: const Icon(Icons.info_outline_rounded, size: 17),
                label: const Text('How it works'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WorkspaceStepper(activeStep: activeStep),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WorkspaceStepper extends StatelessWidget {
  const _WorkspaceStepper({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Source', 'Scan', 'Review', 'Safe copy'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6F6)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              _StepLabel(
                number: index + 1,
                label: labels[index],
                active: index + 1 <= activeStep,
                current: index + 1 == activeStep,
              ),
              if (index != labels.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF98A2B6),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.number,
    required this.label,
    required this.active,
    required this.current,
  });

  final int number;
  final String label;
  final bool active;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? PgColors.blueSoft : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? const Color(0xFFAFCBFF) : PgColors.border,
            ),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: active ? PgColors.blue : PgColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: current ? PgColors.navy : PgColors.textSecondary,
            fontSize: 12,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SourceModeBar extends StatelessWidget {
  const _SourceModeBar({
    required this.onPasteText,
    required this.onImportSource,
    required this.onFullView,
    required this.onSafePreview,
  });

  final VoidCallback onPasteText;
  final VoidCallback onImportSource;
  final VoidCallback? onFullView;
  final VoidCallback? onSafePreview;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _WorkspaceTab(
            icon: Icons.description_outlined,
            label: 'Document',
            active: true,
            onTap: () {},
          ),
          const SizedBox(width: 7),
          _WorkspaceTab(
            icon: Icons.content_paste_outlined,
            label: 'Paste text',
            onTap: onPasteText,
          ),
          const SizedBox(width: 7),
          _WorkspaceTab(
            icon: Icons.cloud_upload_outlined,
            label: 'Import source',
            onTap: onImportSource,
          ),
          const SizedBox(width: 7),
          PopupMenuButton<String>(
            enabled: onFullView != null || onSafePreview != null,
            onSelected: (value) {
              if (value == 'full') onFullView?.call();
              if (value == 'safe') onSafePreview?.call();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'full', child: Text('Full document view')),
              PopupMenuItem(value: 'safe', child: Text('Safe preview')),
            ],
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: PgColors.border),
              ),
              child: const Row(
                children: [
                  Text(
                    'View',
                    style: TextStyle(
                      color: PgColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFF0FBFC) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
          color: active ? const Color(0xFF8ED8DF) : PgColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: active
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF0796A7), width: 3),
                  ),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: active ? const Color(0xFF0796A7) : PgColors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF087888) : PgColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageControl extends StatelessWidget {
  const _LanguageControl({required this.policy});

  final ProtectionPolicy policy;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('workspace-language-${policy.scanLanguage}'),
      initialValue: policy.scanLanguage,
      isDense: true,
      decoration: const InputDecoration(
        labelText: 'Language',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      ),
      items: [
        for (final language in documentLanguages)
          DropdownMenuItem(
            value: language.code,
            child: Text(language.label),
          ),
      ],
      onChanged: (value) {
        if (value != null) policy.setScanLanguage(value);
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      minHeight: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFB9D2FF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: PgColors.blue),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PgColors.blue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OriginalDocumentCard extends StatelessWidget {
  const _OriginalDocumentCard({
    required this.text,
    required this.onPasteText,
    required this.onChooseEmail,
    required this.onUploadLocal,
    required this.onClear,
    this.compact = false,
  });

  final String text;
  final VoidCallback onPasteText;
  final VoidCallback onChooseEmail;
  final VoidCallback onUploadLocal;
  final VoidCallback? onClear;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    return PgCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Original document',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const _MiniPill(label: 'Local source'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(compact ? 13 : 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFEFF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFBFDDEC)),
            ),
            child: hasText
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const PgIconBox(
                            icon: Icons.description_outlined,
                            size: 44,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pasted text',
                                  style: TextStyle(
                                    color: PgColors.navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${text.trim().length} characters · kept on this device',
                                  style: const TextStyle(
                                    color: PgColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onClear != null)
                            IconButton(
                              tooltip: 'Clear document',
                              onPressed: onClear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: BoxConstraints(maxHeight: compact ? 130 : 190),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PgColors.border),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            text,
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const PgIconBox(
                        icon: Icons.description_outlined,
                        size: 54,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No document loaded',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PgColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Choose an email from Gmail, upload a local file, or switch to Paste text.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PgColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: onChooseEmail,
                            icon: const Icon(Icons.cloud_outlined),
                            label: const Text('Choose an email'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onUploadLocal,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Upload local'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onPasteText,
                            icon: const Icon(Icons.content_paste_outlined),
                            label: const Text('Paste text'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Desktop Protect formats · mobile import coming next',
                        style: TextStyle(
                          color: PgColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        alignment: WrapAlignment.center,
                        children: [
                          _FormatChip('PDF', Color(0xFFD92D20)),
                          _FormatChip('DOCX', Color(0xFF2563EB)),
                          _FormatChip('PPTX', Color(0xFFE85D04)),
                          _FormatChip('XLSX', Color(0xFF159947)),
                          _FormatChip('PNG', Color(0xFF7657F6)),
                          _FormatChip('JPG', Color(0xFF7657F6)),
                          _FormatChip('TXT', Color(0xFF66718C)),
                          _FormatChip('CSV', Color(0xFF078A96)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Original content stays on this device while PrivacyGate creates the protected copy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PgColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProtectedDocumentCard extends StatelessWidget {
  const _ProtectedDocumentCard({
    required this.state,
    required this.onCopy,
    required this.onSafePreview,
    required this.onRestore,
    required this.onOpenRestore,
  });

  final ProtectController state;
  final VoidCallback onCopy;
  final VoidCallback onSafePreview;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenRestore;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    final error =
        state.verificationError != null || state.residualFindings.isNotEmpty;

    return PgCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Protected document',
            style: TextStyle(
              color: PgColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FEFE),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFB8DFE3)),
            ),
            child: result == null
                ? const Column(
                    children: [
                      PgIconBox(
                        icon: Icons.verified_user_outlined,
                        foreground: Color(0xFF078A96),
                        background: Color(0xFFEAF8F8),
                        size: 54,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Protected version will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PgColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Your content will be scanned locally. Review the findings before PrivacyGate creates the safe copy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PgColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PgIconBox(
                            icon: error
                                ? Icons.warning_amber_rounded
                                : Icons.verified_user_outlined,
                            foreground: error
                                ? Theme.of(context).colorScheme.error
                                : const Color(0xFF078A96),
                            background: error
                                ? const Color(0xFFFFF3F2)
                                : const Color(0xFFEAF8F8),
                            size: 44,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.verificationRunning
                                      ? 'Verifying protected copy…'
                                      : state.exportVerified
                                          ? 'Protected locally'
                                          : 'Protected copy needs attention',
                                  style: const TextStyle(
                                    color: PgColors.navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _verificationMessageStatic(state),
                                  style: TextStyle(
                                    color: error
                                        ? Theme.of(context).colorScheme.error
                                        : PgColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 190),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PgColors.border),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            result.protectedText,
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: state.exportVerified ? onCopy : null,
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy protected'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onSafePreview,
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Safe preview'),
                          ),
                          if (result.replacementMode ==
                              ReplacementMode.reversible.wireValue) ...[
                            OutlinedButton.icon(
                              onPressed: onRestore,
                              icon: const Icon(Icons.lock_open_outlined),
                              label: const Text('Restore locally'),
                            ),
                            OutlinedButton.icon(
                              onPressed: onOpenRestore,
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('Open Restore'),
                            ),
                          ],
                        ],
                      ),
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
        ],
      ),
    );
  }
}

String _verificationMessageStatic(ProtectController state) {
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

class _DocumentSummaryBar extends StatelessWidget {
  const _DocumentSummaryBar({
    required this.detections,
    required this.profile,
    required this.replacementMode,
  });

  final int detections;
  final String profile;
  final String replacementMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PgColors.border),
      ),
      child: Row(
        children: [
          const PgIconBox(icon: Icons.description_outlined, size: 38),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pasted text',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$detections detections · ${profile.replaceAll(' — Recommended', '')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PgColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  replacementMode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PgColors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: PgColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PgColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ImportSourceRow extends StatelessWidget {
  const _ImportSourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: PgIconBox(icon: icon, size: 42),
      title: Text(
        title,
        style: const TextStyle(
          color: PgColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: PgColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: PgColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: PgColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTextViewer extends StatelessWidget {
  const _DocumentTextViewer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PgColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PgColors.border),
      ),
      child: SingleChildScrollView(
        child: SelectableText(text),
      ),
    );
  }
}
