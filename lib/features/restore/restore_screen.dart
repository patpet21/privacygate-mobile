import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/mobile_design.dart';
import '../../app/workspace_header.dart';
import '../protect/protect_controller.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({
    required this.controller,
    required this.onBackToProtect,
    super.key,
  });

  final ProtectController controller;
  final VoidCallback onBackToProtect;

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  late final TextEditingController _aiResult;
  String _restored = '';
  bool _documentPreview = true;

  @override
  void initState() {
    super.initState();
    _aiResult = TextEditingController(
      text: widget.controller.result?.protectedText ?? '',
    );
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _aiResult.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _loadProtectedCopy() {
    final result = widget.controller.result;
    if (result == null) return;
    _aiResult.text = result.protectedText;
    setState(() => _restored = '');
  }

  void _startNewRestore() {
    _aiResult.clear();
    setState(() => _restored = '');
  }

  void _restore() {
    final value = widget.controller.restoreTextLocally(_aiResult.text);
    setState(() => _restored = value);
  }

  Future<void> _copyRestored() async {
    if (_restored.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _restored));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restored result copied.')),
    );
  }

  Future<void> _pasteAiResult() async {
    var draftValue = _aiResult.text;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste AI result'),
        content: SizedBox(
          width: 520,
          child: TextFormField(
            initialValue: draftValue,
            autofocus: true,
            minLines: 8,
            maxLines: 14,
            onChanged: (value) => draftValue = value,
            decoration: const InputDecoration(
              hintText: 'Paste the AI-edited result with PrivacyGate placeholders.',
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
    _aiResult.text = value;
    setState(() => _restored = '');
  }

  Future<void> _showValidationDetails() async {
    final mappings = widget.controller.result?.mappings.length ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Validation details',
                style: TextStyle(
                  color: PgColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _ValidationRow(label: 'Local mappings', value: '$mappings'),
              _ValidationRow(
                label: 'Restored values',
                value: _restored.isEmpty ? 'Not run yet' : '$mappings restored',
              ),
              const _ValidationRow(label: 'Unknown tokens', value: '0'),
              const _ValidationRow(label: 'Original values uploaded', value: 'Never'),
            ],
          ),
        ),
      ),
    );
  }

  void _notReady(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not connected in this mobile build yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final result = controller.result;
    final mappingCount = result?.mappings.length ?? 0;
    final hasMapping = controller.hasLocalRestoreMapping;
    final restored = _restored.isNotEmpty;

    return Scaffold(
      backgroundColor: PgColors.background,
      body: PgPage(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          PgWorkspaceHeader(
            primaryStatus: '100% LOCAL',
            secondaryStatus: 'ORIGINAL VALUES STAY LOCAL',
            secondaryPositive: true,
            onMenuTap: () => _notReady('Navigation menu'),
          ),
          const SizedBox(height: 18),
          const PgTitle(
            title: 'Restore your AI result',
            subtitle:
                'Restore original values after AI processing — the mapping and restored content stay local.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
              FilledButton.icon(
                onPressed: _startNewRestore,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Start new restore'),
              ),
              OutlinedButton(
                onPressed: _showValidationDetails,
                child: const Text('Validation details'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasMapping)
            PgCard(
              child: Column(
                children: [
                  const PgEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No local restore mapping yet',
                    body:
                        'Protect content with reversible placeholders first. PrivacyGate keeps the mapping on this device for local restore.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onBackToProtect();
                    },
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Back to Protect'),
                  ),
                ],
              ),
            )
          else ...[
            _RestoreStatusCard(
              mappingCount: mappingCount,
              complete: restored,
            ),
            const SizedBox(height: 12),
            _PreviewToggle(
              documentPreview: _documentPreview,
              onChanged: (value) => setState(() => _documentPreview = value),
            ),
            const SizedBox(height: 10),
            PgCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _notReady('AI-result file import'),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload AI result'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pasteAiResult,
                        icon: const Icon(Icons.content_paste_outlined),
                        label: const Text('Paste text'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _aiResult.clear();
                          setState(() => _restored = '');
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loadProtectedCopy,
                        icon: const Icon(Icons.folder_outlined),
                        label: const Text('Personal Library'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loadProtectedCopy,
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Find original'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9FE),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: PgColors.border),
                    ),
                    child: Row(
                      children: [
                        const PgIconBox(
                          icon: Icons.description_outlined,
                          size: 38,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Protect session',
                                style: TextStyle(
                                  color: PgColors.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '$mappingCount reversible mapping(s) available locally',
                                style: const TextStyle(
                                  color: PgColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const ValueKey('restore-locally'),
                      onPressed: _aiResult.text.trim().isEmpty ? null : _restore,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Restore locally'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _RestoreDocumentCard(
              title: 'AI result',
              badge: 'CONTAINS PLACEHOLDERS',
              text: _aiResult.text,
              highlightPlaceholders: true,
              documentPreview: _documentPreview,
              onChanged: (value) {
                _aiResult.text = value;
                setState(() => _restored = '');
              },
            ),
            const SizedBox(height: 12),
            _RestoreDocumentCard(
              title: 'Restored result',
              badge: restored ? 'RESTORED LOCALLY' : 'WAITING',
              positiveBadge: restored,
              text: _restored,
              documentPreview: _documentPreview,
              emptyText: 'Restore locally to see the original values here.',
              onCopy: restored ? _copyRestored : null,
            ),
            const SizedBox(height: 12),
            const Text(
              'Original values and mappings stay on this device. Mobile Restore never sends them to an AI provider.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PgColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestoreStatusCard extends StatelessWidget {
  const _RestoreStatusCard({required this.mappingCount, required this.complete});

  final int mappingCount;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      padding: const EdgeInsets.all(13),
      backgroundColor: const Color(0xFFF8FFFA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: PgColors.greenSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFB7E8C7)),
            ),
            child: Text(
              complete ? 'RESTORE COMPLETE' : 'READY TO RESTORE',
              style: const TextStyle(
                color: PgColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complete
                      ? '$mappingCount restored · 0 unresolved · 0 unknown tokens'
                      : '$mappingCount local mappings ready · 0 unknown tokens',
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  complete
                      ? 'Safe copy is ready. No PrivacyGate placeholders should remain in the restored text.'
                      : 'Load or paste an AI result, then restore locally.',
                  style: const TextStyle(
                    color: PgColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
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

class _PreviewToggle extends StatelessWidget {
  const _PreviewToggle({required this.documentPreview, required this.onChanged});

  final bool documentPreview;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onChanged(false),
            icon: const Icon(Icons.text_snippet_outlined),
            label: const Text('Text preview'),
            style: OutlinedButton.styleFrom(
              backgroundColor: documentPreview ? Colors.white : PgColors.blueSoft,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onChanged(true),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Document preview'),
            style: FilledButton.styleFrom(
              backgroundColor: documentPreview ? PgColors.blue : const Color(0xFF9DBDF7),
            ),
          ),
        ),
      ],
    );
  }
}

class _RestoreDocumentCard extends StatelessWidget {
  const _RestoreDocumentCard({
    required this.title,
    required this.badge,
    required this.text,
    required this.documentPreview,
    this.highlightPlaceholders = false,
    this.positiveBadge = false,
    this.emptyText,
    this.onChanged,
    this.onCopy,
  });

  final String title;
  final String badge;
  final String text;
  final bool documentPreview;
  final bool highlightPlaceholders;
  final bool positiveBadge;
  final String? emptyText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCopy;

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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RestoreBadge(label: badge, positive: positiveBadge),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Copy restored result',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (hasText && documentPreview) const _DocumentTabLabel(),
          if (hasText && documentPreview) const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(minHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB9CDE6)),
            ),
            child: !hasText
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        emptyText ?? 'No content yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: PgColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  )
                : documentPreview
                    ? SizedBox(
                        height: 280,
                        child: _RestoreViewer(
                          text: text,
                          highlightPlaceholders: highlightPlaceholders,
                        ),
                      )
                    : TextFormField(
                        initialValue: text,
                        minLines: 12,
                        maxLines: 16,
                        onChanged: onChanged,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.all(14),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _RestoreViewer extends StatelessWidget {
  const _RestoreViewer({
    required this.text,
    required this.highlightPlaceholders,
  });

  final String text;
  final bool highlightPlaceholders;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
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

class _RestoreBadge extends StatelessWidget {
  const _RestoreBadge({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? PgColors.greenSoft : PgColors.blueSoft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: positive ? const Color(0xFFB7E8C7) : const Color(0xFFB9D2FF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: positive ? PgColors.green : PgColors.blue,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: PgColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: PgColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
