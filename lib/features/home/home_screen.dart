import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onSelectTab,
    super.key,
  });

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return PgPage(
      children: [
        const PgHeader(),
        const PgTitle(
          title: 'Your privacy, your control.',
          subtitle: 'Protect your data, use it confidentially, everywhere.',
        ),
        _QuickActions(onSelectTab: onSelectTab),
        const SizedBox(height: 16),
        PgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PgSectionHeader(title: 'Privacy status'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: PgColors.greenSoft,
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ready',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Local',
                          style: TextStyle(
                            color: PgColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local protection is ready',
                          style: TextStyle(
                            color: PgColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Protect works locally now. Desktop sync, policy, apps, MCP and organization metadata appear after pairing.',
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _OverviewMetrics(),
        const SizedBox(height: 16),
        PgResponsiveColumns(
          children: [
            PgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PgSectionHeader(
                    title: 'Recent documents',
                    action: 'View all',
                    onAction: () => onSelectTab(2),
                  ),
                  const SizedBox(height: 14),
                  const PgEmptyState(
                    icon: Icons.description_outlined,
                    title: 'No protected files yet',
                    body: 'Protected documents will appear here when Vault persistence is enabled.',
                  ),
                ],
              ),
            ),
            const PgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PgSectionHeader(title: 'Connected apps'),
                  SizedBox(height: 10),
                  _MiniConnection(icon: Icons.mail_outline, label: 'Gmail'),
                  _MiniConnection(icon: Icons.cloud_outlined, label: 'Google Drive'),
                  _MiniConnection(icon: Icons.folder_outlined, label: 'Local Files'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PgResponsiveColumns(
          children: [
            PgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PgSectionHeader(
                    title: 'Recent activity',
                    action: 'View all',
                    onAction: () => onSelectTab(3),
                  ),
                  const SizedBox(height: 12),
                  const PgEmptyState(
                    icon: Icons.monitor_heart_outlined,
                    title: 'No activity yet',
                    body: 'Protection, restore, sync and connection events will be listed here.',
                  ),
                ],
              ),
            ),
            PgCard(
              backgroundColor: const Color(0xFFFBFAFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PgSectionHeader(title: 'AI tools & MCP'),
                  const SizedBox(height: 10),
                  const PgIconBox(
                    icon: Icons.auto_awesome,
                    foreground: PgColors.purple,
                    background: PgColors.purpleSoft,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Use protected files with AI tools',
                    style: TextStyle(
                      color: PgColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The mobile app keeps the same protected-Library boundary as Desktop. MCP controls are exposed from Settings.',
                    style: TextStyle(
                      color: PgColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => onSelectTab(4),
                    child: const Text('Manage AI & MCP'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PgCard(
          backgroundColor: const Color(0xFFF3F7FF),
          child: Row(
            children: [
              const PgIconBox(icon: Icons.shield_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your privacy is our priority',
                      style: TextStyle(
                        color: PgColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sensitive-data detection, protection and restore mappings remain local in the current mobile build.',
                      style: TextStyle(color: PgColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, String subtitle, VoidCallback? onTap})>[
      (
        icon: Icons.shield_outlined,
        label: 'Protect',
        subtitle: 'Hide sensitive data',
        onTap: () => onSelectTab(1),
      ),
      (
        icon: Icons.history_rounded,
        label: 'Restore',
        subtitle: 'Recover originals',
        onTap: () => onSelectTab(1),
      ),
      (
        icon: Icons.auto_awesome_outlined,
        label: 'Scan',
        subtitle: 'Find sensitive data',
        onTap: () => onSelectTab(1),
      ),
      (
        icon: Icons.folder_outlined,
        label: 'Library',
        subtitle: 'Protected files',
        onTap: () => onSelectTab(2),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: item.onTap,
          child: PgCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            backgroundColor: index == 0 ? const Color(0xFFF2F7FF) : PgColors.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                PgIconBox(icon: item.icon, size: 44),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: index == 0 ? PgColors.blue : PgColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: PgColors.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewMetrics extends StatelessWidget {
  const _OverviewMetrics();

  @override
  Widget build(BuildContext context) {
    const metrics = [
      _MetricData(Icons.description_outlined, 'Protected docs', '0', 'Vault persistence pending'),
      _MetricData(Icons.gpp_good_outlined, 'Blocked actions', '0', 'No persisted events'),
      _MetricData(Icons.devices_outlined, 'Device status', 'Local', 'Desktop not paired'),
      _MetricData(Icons.hub_outlined, 'AI access', 'Off', 'MCP not connected'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return PgCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PgIconBox(icon: metric.icon, size: 36),
              const SizedBox(height: 8),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PgColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.value,
                style: const TextStyle(
                  color: PgColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.caption,
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
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.icon, this.label, this.value, this.caption);

  final IconData icon;
  final String label;
  final String value;
  final String caption;
}

class _MiniConnection extends StatelessWidget {
  const _MiniConnection({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          PgIconBox(icon: icon, size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: PgColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const Text(
            'Off',
            style: TextStyle(
              color: PgColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
