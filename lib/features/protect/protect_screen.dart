import 'package:flutter/material.dart';

import 'protect_controller.dart';

class ProtectScreen extends StatefulWidget {
  const ProtectScreen({required this.controller, super.key});

  final ProtectController controller;

  @override
  State<ProtectScreen> createState() => _ProtectScreenState();
}

class _ProtectScreenState extends State<ProtectScreen> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _text.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('PrivacyGate')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Development bootstrap: protection and restore use the audited PrivacyGate contract. '
                  'Detection is temporarily limited to email and US-style phone patterns.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Paste text',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.analyzing ? null : () => state.analyze(_text.text),
              child: Text(state.analyzing ? 'Scanning…' : 'Scan locally'),
            ),
            if (state.findings.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Review detections'),
              for (final finding in state.findings)
                CheckboxListTile(
                  value: state.selectedFindingIds.contains(finding.findingId),
                  onChanged: (value) => state.setSelected(
                    finding.findingId,
                    value ?? false,
                  ),
                  title: Text(finding.text),
                  subtitle: Text(finding.entityType),
                ),
              FilledButton(
                onPressed: state.selectedFindingIds.isEmpty ? null : state.protect,
                child: const Text('Protect'),
              ),
            ],
            if (state.result != null) ...[
              const SizedBox(height: 20),
              const Text('Protected output'),
              SelectableText(state.result!.protectedText),
              OutlinedButton(
                onPressed: state.restoreLocally,
                child: const Text('Restore locally'),
              ),
            ],
            if (state.restoredText.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Restored locally'),
              SelectableText(state.restoredText),
            ],
          ],
        ),
      ),
    );
  }
}
