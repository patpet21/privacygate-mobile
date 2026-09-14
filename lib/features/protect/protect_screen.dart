import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _filter = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _text.addListener(_refreshLocal);
    _filter.addListener(_refreshLocal);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _text.removeListener(_refreshLocal);
    _filter.removeListener(_refreshLocal);
    _text.dispose();
    _filter.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});
  void _refreshLocal() => setState(() {});

  Future<void> _copyProtected() async {
    final state = widget.controller;
    final current = state.result;
    if (current == null || !state.exportVerified) return;
    await Clipboard.setData(ClipboardData(text: current.protectedText));
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
                value: entityType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  if (entities.isEmpty)
                    const DropdownMenuItem(value: 'CUSTOM', child: Text('CUSTOM')),
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
                widget.controller.addManualFinding(valueController.text, entityType);
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

  void _clear() {
    _text.clear();
    _filter.clear();
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    final policy = state.policy;
    final query = _filter.text.trim().toLowerCase();
    final visibleFindings = state.findings.where((finding) {
      if (query.isEmpty) return true;
      return finding.text.toLowerCase().contains(query) ||
          finding.entityType.toLowerCase().contains(query);
    }).toList(growable: false);
    final categories = state.findings.map((item) => item.entityType).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('PrivacyGate')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Protect a document', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Review every detected item before protected content leaves this device.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Chip(
                  avatar: Icon(Icons.lock_outline, size: 16),
                  label: Text('LOCAL'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Document setup', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: policy.profileKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Industry profile',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final profile in profiles)
                          DropdownMenuItem(value: profile.key, child: Text(profile.name)),
                      ],
                      onChanged: (value) {
                        if (value != null) policy.setProfileKey(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: policy.scopeKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Protection scope',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final scope in scopes)
                          DropdownMenuItem(value: scope.key, child: Text(scope.name)),
                      ],
                      onChanged: (value) {
                        if (value != null) policy.setScopeKey(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ReplacementMode>(
                      value: policy.replacementMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Protection mode',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final mode in ReplacementMode.values)
                          DropdownMenuItem(value: mode, child: Text(mode.label)),
                      ],
                      onChanged: (value) {
                        if (value != null) policy.setReplacementMode(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Text('Detection confidence')),
                        Text(policy.confidenceThreshold.toStringAsFixed(2)),
                      ],
                    ),
                    Slider(
                      min: 0.10,
                      max: 0.95,
                      divisions: 17,
                      value: policy.confidenceThreshold,
                      label: policy.confidenceThreshold.toStringAsFixed(2),
                      onChanged: policy.setConfidenceThreshold,
                    ),
                    Text(
                      'Lower values detect more possible sensitive data; higher values are stricter.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _text,
                      minLines: 6,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Paste text',
                        hintText: 'Paste an email, lease excerpt, offer, proposal or other business text.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 142,
                          child: DropdownButtonFormField<String>(
                            value: policy.scanLanguage,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Scan language',
                              border: OutlineInputBorder(),
                              isDense: true,
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
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: state.analyzing || _text.text.trim().isEmpty
                                ? null
                                : () => state.analyze(_text.text),
                            icon: const Icon(Icons.search),
                            label: Text(state.analyzing ? 'Scanning…' : 'Scan for sensitive data'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Clear',
                          onPressed: _text.text.isEmpty && state.findings.isEmpty ? null : _clear,
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan language selects the detector used for this text. It is independent from the app-interface language.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${state.findings.length} findings')),
                Chip(label: Text('${categories.length} categories')),
                const Chip(label: Text('1 text page')),
                _verificationChip(state),
              ],
            ),
            if (state.findings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Detected items', style: Theme.of(context).textTheme.titleMedium),
                          ),
                          Text('${state.selectedCount}/${state.findings.length} protect'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _filter,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.filter_alt_outlined),
                          labelText: 'Filter findings',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          OutlinedButton(onPressed: state.selectAll, child: const Text('Protect all')),
                          OutlinedButton(onPressed: state.keepAll, child: const Text('Keep all')),
                          OutlinedButton(onPressed: state.invertSelection, child: const Text('Invert')),
                          OutlinedButton.icon(
                            onPressed: _showManualFindingDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add missed item'),
                          ),
                        ],
                      ),
                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final category in categories)
                              FilterChip(
                                label: Text(category),
                                selected: state.findings
                                    .where((item) => item.entityType == category)
                                    .every((item) => state.selectedFindingIds.contains(item.findingId)),
                                onSelected: (selected) =>
                                    state.setCategorySelected(category, selected),
                              ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      for (final finding in visibleFindings)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: state.selectedFindingIds.contains(finding.findingId),
                          onChanged: (value) => state.setSelected(
                            finding.findingId,
                            value ?? false,
                          ),
                          title: Text(finding.text),
                          subtitle: Text(
                            '${finding.entityType} · ${(finding.score * 100).toStringAsFixed(0)}%',
                          ),
                        ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: state.selectedCount == 0 || state.verificationRunning
                            ? null
                            : state.protectAndVerify,
                        icon: const Icon(Icons.shield),
                        label: Text(
                          state.verificationRunning
                              ? 'Verifying protected result…'
                              : 'Protect selected (${state.selectedCount})',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (state.result != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Protected output', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _verificationMessage(context, state),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
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
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy protected'),
                          ),
                          if (state.result!.replacementMode ==
                              ReplacementMode.reversible.wireValue)
                            OutlinedButton.icon(
                              onPressed: state.result!.mappings.isEmpty ? null : state.restoreLocally,
                              icon: const Icon(Icons.lock_open_outlined),
                              label: const Text('Restore locally'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (state.restoredText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Restored locally', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SelectableText(state.restoredText),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Development note: the workspace behavior follows the audited Desktop Protect flow, but detector parity is not complete until the production mobile detector passes the canonical Desktop corpus.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verificationChip(ProtectController state) {
    if (state.verificationRunning) {
      return const Chip(label: Text('Second scan…'));
    }
    if (!state.verificationPerformed) {
      return const Chip(label: Text('Second scan before export'));
    }
    if (state.verificationError != null || state.residualFindings.isNotEmpty) {
      return const Chip(
        avatar: Icon(Icons.warning_amber, size: 16),
        label: Text('Export blocked'),
      );
    }
    return const Chip(
      avatar: Icon(Icons.verified_user_outlined, size: 16),
      label: Text('Second scan passed'),
    );
  }

  Widget _verificationMessage(BuildContext context, ProtectController state) {
    if (state.verificationRunning) {
      return const Text('Running the second local scan before export actions are enabled.');
    }
    if (state.verificationError != null) {
      return Text(
        'Second scan failed. Copy/export remains blocked.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (state.residualFindings.isNotEmpty) {
      return Text(
        'Second scan found ${state.residualFindings.length} residual sensitive item(s). Copy/export remains blocked.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (state.verificationPerformed) {
      return const Text('Second local scan passed. Protected copy actions are enabled.');
    }
    return const Text('Second local scan has not run yet.');
  }
}
