import 'package:flutter/material.dart';

import '../core/desktop_link/desktop_link_status.dart';

class PgColors {
  const PgColors._();

  static const navy = Color(0xFF11182F);
  static const blue = Color(0xFF0B63F6);
  static const blueSoft = Color(0xFFEAF2FF);
  static const green = Color(0xFF13A84A);
  static const greenSoft = Color(0xFFEAF8EF);
  static const purple = Color(0xFF7657F6);
  static const purpleSoft = Color(0xFFF0ECFF);
  static const orange = Color(0xFFFF8A1F);
  static const textSecondary = Color(0xFF66718C);
  static const border = Color(0xFFE1E6EF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F9FC);
}

class PgPage extends StatelessWidget {
  const PgPage({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 24),
    super.key,
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: padding,
        children: children,
      ),
    );
  }
}

class PgHeader extends StatelessWidget {
  const PgHeader({
    this.connected,
    super.key,
  });

  /// Optional explicit override retained for screens that need to force a
  /// preview state. Normal app screens leave this null and use the shared
  /// Desktop reachability monitor.
  final bool? connected;

  @override
  Widget build(BuildContext context) {
    if (connected != null) {
      return _buildHeader(
        connected! ? DesktopLinkStatus.connectedLocal : DesktopLinkStatus.unpaired,
      );
    }
    return ValueListenableBuilder<DesktopLinkStatus>(
      valueListenable: DesktopLinkPresence.notifier,
      builder: (context, status, _) => _buildHeader(status),
    );
  }

  Widget _buildHeader(DesktopLinkStatus status) {
    final (dotColor, label) = switch (status) {
      DesktopLinkStatus.connectedLocal =>
        (PgColors.green, 'Desktop connected · Local'),
      DesktopLinkStatus.connectedRemote =>
        (PgColors.green, 'Desktop connected · Remote'),
      DesktopLinkStatus.checking => (PgColors.blue, 'Checking Desktop…'),
      DesktopLinkStatus.offline => (PgColors.orange, 'Desktop paired · Offline'),
      DesktopLinkStatus.unpaired =>
        (const Color(0xFF98A2B6), 'Desktop not paired'),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C8DFF), Color(0xFF1261EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F0B63F6),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 29),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PrivacyGate',
                  style: TextStyle(
                    color: PgColors.navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PgColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFF0F2F7),
            child: Text(
              'PG',
              style: TextStyle(
                color: PgColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PgTitle extends StatelessWidget {
  const PgTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PgColors.navy,
              fontSize: 31,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: PgColors.textSecondary,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class PgCard extends StatelessWidget {
  const PgCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor = PgColors.surface,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: 2,
      shadowColor: const Color(0x1415223A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: PgColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class PgSectionHeader extends StatelessWidget {
  const PgSectionHeader({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

class PgIconBox extends StatelessWidget {
  const PgIconBox({
    required this.icon,
    this.foreground = PgColors.blue,
    this.background = PgColors.blueSoft,
    this.size = 46,
    super.key,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: foreground, size: size * 0.52),
    );
  }
}

class PgEmptyState extends StatelessWidget {
  const PgEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PgIconBox(icon: icon, size: 52),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: PgColors.navy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: PgColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// Uses horizontal columns on wider layouts and automatically stacks the same
/// cards on phones. This keeps Desktop-parity content readable without
/// compressing desktop rows into narrow mobile columns.
class PgResponsiveColumns extends StatelessWidget {
  const PgResponsiveColumns({
    required this.children,
    this.breakpoint = 620,
    this.spacing = 12,
    super.key,
  });

  final List<Widget> children;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.isEmpty) return const SizedBox.shrink();
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}
