import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/mobile_design.dart';
import '../../app/workspace_header.dart';
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
          builder: (context, setSheetState) => SafeArea(
            top: false,
            child: FractionallySizedBox(
              heightFactor: 0.86,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
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
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Scan language',
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
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Done'),
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

  Future<void> _showImportSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Import source',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 24,
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
              height: MediaQuery.sizeOf(sheetContext).height * 0.82,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full document view',
                      style: TextStyle(
                        color: PgColors.navy,
                        fontSize: 24,
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
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _DocumentViewer(text: _text.text),
                          if (protectedText != null)
                            _DocumentViewer(
                              text: protectedText,
                              highlightPlaceholders: true,
                            ),
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

  Future<void> _showSafePreview() async {
    final result = widget.controller.result;
    if (result == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safe preview',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _verificationMessage(widget.controller),
                  style: const TextStyle(
                    color: PgColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _DocumentViewer(
                    text: result.protectedText,
                    highlightPlaceholders: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scan() async {
    if (_text.text.trim().isEmpty || widget.controller.analyzing) return;
    await widget.controller.analyze(_text.text);
    if (!mounted) return;
    setState(() => _reviewing = true);
  }

  void _clearDocument() {
    _text.clear();
    widget.controller.clear();
    setState(() => _reviewing = false);
  }

  void _notReady(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not connected in this mobile build yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _reviewing ? _buildReview(context) : _buildSource(context);
  }

  Widget _buildSource(BuildContext context) {
    final state = widget.controller;
    final hasSource = _text.text.trim().isNotEmpty;

    return PgPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        PgWorkspaceHeader(
          primaryStatus: 'LOCAL PROCESSING',
          secondaryStatus: state.exportVerified ? 'PROTECTED' : 'READY',
          secondaryPositive: state.exportVerified,
          onMenuTap: () => _notReady('Navigation menu'),
        ),
        const SizedBox(height: 18),
        const PgTitle(
          title: 'Protect',
          subtitle:
              'Protect sensitive data locally before you share a document or use it with AI.',
        ),
        _WorkspaceCard(
          activeStep: 1,
          onFullView: hasSource ? _showFullDocumentView : null,
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
              _WorkspaceControls(
                policy: state.policy,
                hasSource: hasSource,
                analyzing: state.analyzing,
                onScanSettings: _showScanOptions,
                onClear: _clearDocument,
                onScan: _scan,
                onSafePreview: state.result == null ? null : _showSafePreview,
              ),
              const SizedBox(height: 10),
              const _HighFidelityInfo(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DocumentPreviewCard(
          title: 'Original document',
          badge: 'Local source',
          text: _text.text,
          emptyIcon: Icons.description_outlined,
          emptyTitle: 'No document loaded',
          emptyBody:
              'Choose an email from Gmail, upload a local file, or switch to Paste text.',
          onPasteText: _showPasteDialog,
          onChooseEmail: () => _notReady('Gmail import'),
          onUploadLocal: () => _notReady('Local file import'),
        ),
        const SizedBox(height: 14),
        _ProtectedPreviewCard(
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
    final protected = state.result != null;

    return PgPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        PgWorkspaceHeader(
          primaryStatus: 'LOCAL PROCESSING',
          secondaryStatus: protected && state.exportVerified ? 'PROTECTED' : 'REVIEW',
          secondaryPositive: protected && state.exportVerified,
          onMenuTap: () => _notReady('Navigation menu'),
        ),
        const SizedBox(height: 18),
        const PgTitle(
          title: 'Protect',
          subtitle:
              'Review sensitive data locally, then create a verified safe copy.',
        ),
        _WorkspaceCard(
          activeStep: protected ? 4 : 3,
          onFullView: _showFullDocumentView,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReviewToolbar(
                onBack: () => setState(() => _reviewing = false),
                onScanSettings: _showScanOptions,
                onFullView: _showFullDocumentView,
                onSafePreview: protected ? _showSafePreview : null,
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
        _DocumentPreviewCard(
          title: 'Original document',
          badge: 'Local source',
          text: state.originalText,
          emptyIcon: Icons.description_outlined,
          emptyTitle: 'No document loaded',
          emptyBody: 'Return to Source and load content first.',
          onPasteText: _showPasteDialog,
          onChooseEmail: () => _notReady('Gmail import'),
          onUploadLocal: () => _notReady('Local file import'),
        ),
        const SizedBox(height: 14),
        if (!protected) ...[
          _ReviewFindingsCard(
            state: state,
            onAddMissed: _showManualFindingDialog,
          ),
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
          const SizedBox(height: 14),
        ],
        _ProtectedPreviewCard(
          state: state,
          onCopy: _copyProtected,
          onSafePreview: _showSafePreview,
          onRestore: state.hasLocalRestoreMapping ? state.restoreLocally : null,
          onOpenRestore: state.hasLocalRestoreMapping
              ? () => widget.onOpenRestore(context)
              : null,
        ),
        if (protected) ...[
          const SizedBox(height: 14),
          PgCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: Text(
                'Review detections (${state.findings.length})',
                style: const TextStyle(
                  color: PgColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text('${state.selectedCount} protected'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _ReviewFindingsBody(
                    state: state,
                    onAddMissed: _showManualFindingDialog,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: entityType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
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
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.activeStep,
    required this.onFullView,
    required this.child,
  });

  final int activeStep;
  final VoidCallback? onFullView;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'Document workspace',
                style: TextStyle(
                  color: PgColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  OutlinedButton.icon(
                    onPressed: onFullView,
                    icon: const Icon(Icons.description_outlined, size: 17),
                    label: const Text('Full document view'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  const _InfoPill(
                    icon: Icons.palette_outlined,
                    label: 'Protected values are color coded',
                  ),
                ],
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
          width: 26,
          height: 26,
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
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: current ? PgColors.navy : PgColors.textSecondary,
            fontSize: 13,
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

class _WorkspaceControls extends StatelessWidget {
  const _WorkspaceControls({
    required this.policy,
    required this.hasSource,
    required this.analyzing,
    required this.onScanSettings,
    required this.onClear,
    required this.onScan,
    required this.onSafePreview,
  });

  final ProtectionPolicy policy;
  final bool hasSource;
  final bool analyzing;
  final VoidCallback onScanSettings;
  final VoidCallback onClear;
  final VoidCallback onScan;
  final VoidCallback? onSafePreview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final language = SizedBox(
          width: constraints.maxWidth < 430 ? constraints.maxWidth : 145,
          child: DropdownButtonFormField<String>(
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
          ),
        );

        final buttons = <Widget>[
          language,
          OutlinedButton.icon(
            key: const ValueKey('scan-options'),
            onPressed: onScanSettings,
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('Scan settings'),
          ),
          OutlinedButton.icon(
            onPressed: hasSource ? onClear : null,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Clear'),
          ),
          FilledButton.icon(
            key: const ValueKey('continue-scan'),
            onPressed: !hasSource || analyzing ? null : onScan,
            icon: analyzing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shield_outlined, size: 18),
            label: Text(analyzing ? 'Scanning…' : 'Scan + Protect'),
          ),
          OutlinedButton(
            onPressed: onSafePreview,
            child: const Text('Safe preview'),
          ),
        ];

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: buttons,
        );
      },
    );
  }
}

class _ReviewToolbar extends StatelessWidget {
  const _ReviewToolbar({
    required this.onBack,
    required this.onScanSettings,
    required this.onFullView,
    required this.onSafePreview,
  });

  final VoidCallback onBack;
  final VoidCallback onScanSettings;
  final VoidCallback onFullView;
  final VoidCallback? onSafePreview;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to source'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('scan-options'),
          onPressed: onScanSettings,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Scan settings'),
        ),
        OutlinedButton.icon(
          onPressed: onFullView,
          icon: const Icon(Icons.description_outlined),
          label: const Text('Full view'),
        ),
        OutlinedButton.icon(
          onPressed: onSafePreview,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Safe preview'),
        ),
      ],
    );
  }
}

class _HighFidelityInfo extends StatelessWidget {
  const _HighFidelityInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: PgColors.border),
      ),
      child: const Wrap(
        spacing: 7,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.description_outlined, color: PgColors.blue, size: 18),
          Text(
            'High-fidelity preview',
            style: TextStyle(
              color: PgColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Built-in preview remains available on mobile.',
            style: TextStyle(
              color: PgColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9D2FF)),
      ),
      child: Wrap(
        spacing: 5,
        runSpacing: 2,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 16, color: PgColors.blue),
          Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              color: PgColors.blue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard({
    required this.title,
    required this.badge,
    required this.text,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
    required this.onPasteText,
    required this.onChooseEmail,
    required this.onUploadLocal,
  });

  final String title;
  final String badge;
  final String text;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;
  final VoidCallback onPasteText;
  final VoidCallback onChooseEmail;
  final VoidCallback onUploadLocal;

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MiniPill(label: badge),
            ],
          ),
          const SizedBox(height: 10),
          if (hasText)
            const _DocumentTabLabel()
          else
            const SizedBox.shrink(),
          if (hasText) const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(minHeight: hasText ? 260 : 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFBDDCE8)),
            ),
            child: hasText
                ? SizedBox(
                    height: 260,
                    child: _DocumentViewer(text: text),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PgIconBox(icon: emptyIcon, size: 54),
                      const SizedBox(height: 12),
                      Text(
                        emptyTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: PgColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptyBody,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: PgColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 12),
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

class _ProtectedPreviewCard extends StatelessWidget {
  const _ProtectedPreviewCard({
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Protected document',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (result != null)
                _MiniPill(
                  label: state.exportVerified ? 'Protected' : 'Verifying',
                  positive: state.exportVerified,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (result != null) const _DocumentTabLabel(),
          if (result != null) const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(minHeight: 280),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFFFF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFB8DFE3)),
            ),
            child: result == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PgIconBox(
                        icon: Icons.verified_user_outlined,
                        foreground: Color(0xFF078A96),
                        background: Color(0xFFEAF8F8),
                        size: 54,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Protected version will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PgColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Scan locally, review detections, and PrivacyGate will create the safe copy here.',
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
                          Icon(
                            error
                                ? Icons.warning_amber_rounded
                                : Icons.verified_user_outlined,
                            color: error
                                ? Theme.of(context).colorScheme.error
                                : const Color(0xFF078A96),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _verificationMessageStatic(state),
                              style: TextStyle(
                                color: error
                                    ? Theme.of(context).colorScheme.error
                                    : PgColors.textSecondary,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 280,
                        child: _DocumentViewer(
                          text: result.protectedText,
                          highlightPlaceholders: true,
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewFindingsCard extends StatelessWidget {
  const _ReviewFindingsCard({required this.state, required this.onAddMissed});

  final ProtectController state;
  final VoidCallback onAddMissed;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Review detections (${state.findings.length})',
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
          const SizedBox(height: 10),
          _ReviewFindingsBody(state: state, onAddMissed: onAddMissed),
        ],
      ),
    );
  }
}

class _ReviewFindingsBody extends StatelessWidget {
  const _ReviewFindingsBody({required this.state, required this.onAddMissed});

  final ProtectController state;
  final VoidCallback onAddMissed;

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

  @override
  Widget build(BuildContext context) {
    if (state.findings.isEmpty) {
      return Column(
        children: [
          const PgEmptyState(
            icon: Icons.verified_user_outlined,
            title: 'No sensitive items found',
            body: 'Change scan settings or add a missed item manually.',
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddMissed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add missed item'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
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
              onPressed: onAddMissed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add missed item'),
            ),
          ],
        ),
        const Divider(height: 24),
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
                value: state.selectedFindingIds.contains(finding.findingId),
                onChanged: (value) =>
                    state.setSelected(finding.findingId, value),
              ),
              const Divider(height: 1),
            ],
          ),
      ],
    );
  }
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
                Text(
                  '$detections detections · ${profile.replaceAll(' — Recommended', '')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
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

class _DocumentTabLabel extends StatelessWidget {
  const _DocumentTabLabel();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF078A96), Color(0xFF0B63F6)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: const Text(
          'Document',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DocumentViewer extends StatelessWidget {
  const _DocumentViewer({
    required this.text,
    this.highlightPlaceholders = false,
  });

  final String text;
  final bool highlightPlaceholders;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFB9CDE6)),
      ),
      child: SingleChildScrollView(
        child: highlightPlaceholders
            ? _PlaceholderText(text: text)
            : SelectableText(
                text,
                style: const TextStyle(
                  color: PgColors.navy,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _PlaceholderText extends StatelessWidget {
  const _PlaceholderText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final pattern = RegExp(r'\[\[PG_[^\]]+\]\]');
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            color: PgColors.navy,
            backgroundColor: Color(0xFFFFEFA3),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(
          color: PgColors.navy,
          height: 1.45,
          fontSize: 14,
        ),
        children: spans,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, this.positive = false});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? PgColors.greenSoft : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: positive ? const Color(0xFFB7E8C7) : PgColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: positive ? PgColors.green : PgColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
