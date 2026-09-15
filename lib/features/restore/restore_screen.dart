import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/mobile_design.dart';
import '../protect/protect_controller.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({required this.controller, super.key});

  final ProtectController controller;

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  late final TextEditingController _aiResult;
  String _restored = '';

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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final result = controller.result;

    return Scaffold(
      backgroundColor: PgColors.background,
      appBar: AppBar(
        backgroundColor: PgColors.background,
        surfaceTintColor: PgColors.background,
        title: const Text(
          'Restore',
          style: TextStyle(
            color: PgColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: PgPage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const PgTitle(
            title: 'Restore your AI result',
            subtitle: 'Restore original values after AI processing. Mapping and restored content stay local.',
          ),
          const _RestoreSteps(),
          const SizedBox(height: 16),
          if (!controller.hasLocalRestoreMapping)
            PgCard(
              child: Column(
                children: [
                  const PgEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No local restore mapping yet',
                    body: 'Protect content with reversible placeholders first. PrivacyGate keeps the mapping on this device for local restore.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Back to Protect'),
                  ),
                ],
              ),
            )
          else ...[
            PgCard(
              backgroundColor: const Color(0xFFF3F7FF),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PgIconBox(
                    icon: Icons.lock_outline_rounded,
                    foreground: PgColors.green,
                    background: PgColors.greenSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent local session available',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${result!.mappings.length} reversible mapping(s) available on this device.',
                          style: const TextStyle(
                            color: PgColors.textSecondary,
                            height: 1.3,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PgSectionHeader(title: 'AI result'),
                  const SizedBox(height: 4),
                  const Text(
                    'Paste the AI-edited result that still contains PrivacyGate placeholders.',
                    style: TextStyle(color: PgColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiResult,
                    minLines: 8,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      hintText: 'Paste AI result here…',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) {
                      if (_restored.isNotEmpty) setState(() => _restored = '');
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loadProtectedCopy,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Load protected copy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _aiResult.clear();
                          setState(() => _restored = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const PgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PgSectionHeader(title: 'Match original'),
                  SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, color: PgColors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A matching local mapping is loaded from the current Protect session. No original value is uploaded or exposed to AI.',
                          style: TextStyle(
                            color: PgColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                key: const ValueKey('restore-locally'),
                onPressed: _aiResult.text.trim().isEmpty ? null : _restore,
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Restore locally'),
              ),
            ),
            if (_restored.isNotEmpty) ...[
              const SizedBox(height: 16),
              PgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PgSectionHeader(
                      title: 'Restored result',
                      action: 'Copy',
                      onAction: _copyRestored,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PgColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PgColors.border),
                      ),
                      child: SelectableText(_restored),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          const PgCard(
            backgroundColor: Color(0xFFEAF8EF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PgIconBox(
                  icon: Icons.verified_user_outlined,
                  foreground: PgColors.green,
                  background: Colors.white,
                  size: 40,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '100% local restore boundary: original values and mappings stay on this device. Mobile restore never sends them to an AI provider.',
                    style: TextStyle(
                      color: PgColors.navy,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
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

class _RestoreSteps extends StatelessWidget {
  const _RestoreSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      '1 AI result',
      '2 Match original',
      '3 Restore',
      '4 Use result',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Chip(
              avatar: CircleAvatar(
                radius: 10,
                backgroundColor: index == 0 ? PgColors.blue : PgColors.blueSoft,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: index == 0 ? Colors.white : PgColors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              label: Text(steps[index].substring(2)),
            ),
            if (index != steps.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right_rounded, size: 18),
              ),
          ],
        ],
      ),
    );
  }
}
