import 'package:flutter/material.dart';

import '../core/workspaces/workspace_context.dart';
import 'mobile_design.dart';

class PgWorkspaceHeader extends StatefulWidget {
  const PgWorkspaceHeader({
    required this.primaryStatus,
    required this.secondaryStatus,
    this.secondaryPositive = false,
    this.onMenuTap,
    super.key,
  });

  final String primaryStatus;
  final String secondaryStatus;
  final bool secondaryPositive;
  final VoidCallback? onMenuTap;

  @override
  State<PgWorkspaceHeader> createState() => _PgWorkspaceHeaderState();
}

class _PgWorkspaceHeaderState extends State<PgWorkspaceHeader> {
  final _workspace = WorkspaceContext.instance;

  @override
  void initState() {
    super.initState();
    _workspace.addListener(_refresh);
  }

  @override
  void dispose() {
    _workspace.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _chooseWorkspace() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final current = _workspace.activeWorkspace;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose workspace',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Protect and Restore use the selected workspace context for this app session.',
                  style: TextStyle(
                    color: PgColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                for (final workspace in _workspace.workspaces)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: PgIconBox(
                      icon: workspace.kind == WorkspaceKind.personal
                          ? Icons.person_outline_rounded
                          : Icons.groups_outlined,
                      size: 42,
                    ),
                    title: Text(
                      workspace.name,
                      style: const TextStyle(
                        color: PgColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(workspace.subtitle),
                    trailing: Icon(
                      current.id == workspace.id
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: current.id == workspace.id
                          ? PgColors.blue
                          : PgColors.textSecondary,
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(workspace.id),
                  ),
                const Divider(height: 20),
                const Text(
                  'Additional synced teams will appear here when organization sync is connected.',
                  style: TextStyle(
                    color: PgColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) _workspace.select(selected);
  }

  @override
  Widget build(BuildContext context) {
    final active = _workspace.activeWorkspace;

    return LayoutBuilder(
      builder: (context, constraints) {
        final brand = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onMenuTap,
                icon: const Icon(Icons.menu_rounded, color: PgColors.navy),
              ),
              const Icon(
                Icons.shield_outlined,
                color: PgColors.blue,
                size: 28,
              ),
              const SizedBox(width: 7),
              const Text(
                'PrivacyGate',
                style: TextStyle(
                  color: PgColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        );

        final selector = InkWell(
          key: const ValueKey('workspace-selector'),
          onTap: _chooseWorkspace,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: PgColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  active.kind == WorkspaceKind.personal
                      ? Icons.shield_outlined
                      : Icons.groups_outlined,
                  color: PgColors.blue,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PgColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        active.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PgColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: PgColors.navy,
                  size: 20,
                ),
              ],
            ),
          ),
        );

        final status = Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _HeaderStatusPill(
              label: widget.primaryStatus,
              positive: true,
            ),
            _HeaderStatusPill(
              label: widget.secondaryStatus,
              positive: widget.secondaryPositive,
            ),
          ],
        );

        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: brand),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: PgColors.purple,
                    child: Text(
                      'PG',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              selector,
              const SizedBox(height: 9),
              Align(alignment: Alignment.centerRight, child: status),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: brand),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: PgColors.purple,
                  child: Text(
                    'PG',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: selector),
                const SizedBox(width: 12),
                Flexible(child: status),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeaderStatusPill extends StatelessWidget {
  const _HeaderStatusPill({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final foreground = positive ? PgColors.green : PgColors.textSecondary;
    final background = positive ? PgColors.greenSoft : const Color(0xFFF0F2F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
