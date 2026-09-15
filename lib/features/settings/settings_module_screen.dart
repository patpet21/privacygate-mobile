import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';

enum SettingsModule {
  accountDevices,
  workspaces,
  services,
  apps,
  aiMcp,
  governance,
  policyCenter,
  team,
  devices,
  appInfo,
}

extension SettingsModuleMeta on SettingsModule {
  String get title => switch (this) {
        SettingsModule.accountDevices => 'Account & Devices',
        SettingsModule.workspaces => 'Workspaces',
        SettingsModule.services => 'Services',
        SettingsModule.apps => 'Apps & Integrations',
        SettingsModule.aiMcp => 'AI & MCP',
        SettingsModule.governance => 'Governance',
        SettingsModule.policyCenter => 'Policy Center',
        SettingsModule.team => 'Team & Members',
        SettingsModule.devices => 'Managed Devices',
        SettingsModule.appInfo => 'Application Info',
      };

  String get subtitle => switch (this) {
        SettingsModule.accountDevices => 'Account identity, device association and trusted Desktop pairing.',
        SettingsModule.workspaces => 'Personal and organization contexts, policies and workspace switching.',
        SettingsModule.services => 'Local Privacy Bridge, browser protection and runtime services.',
        SettingsModule.apps => 'Connected providers and the Desktop app catalog.',
        SettingsModule.aiMcp => 'Remote MCP, Local MCP and the protected-Library AI boundary.',
        SettingsModule.governance => 'Privacy preflight, policy status, local evidence and compliance metadata.',
        SettingsModule.policyCenter => 'Protection modes, sensitive-data rules and approved AI destinations.',
        SettingsModule.team => 'Organization membership, roles, seats and managed endpoints.',
        SettingsModule.devices => 'Managed endpoint status and policy association.',
        SettingsModule.appInfo => 'Mobile version, local capabilities and implementation status.',
      };

  IconData get icon => switch (this) {
        SettingsModule.accountDevices => Icons.account_circle_outlined,
        SettingsModule.workspaces => Icons.workspaces_outline,
        SettingsModule.services => Icons.hub_outlined,
        SettingsModule.apps => Icons.apps_outlined,
        SettingsModule.aiMcp => Icons.auto_awesome_outlined,
        SettingsModule.governance => Icons.verified_user_outlined,
        SettingsModule.policyCenter => Icons.policy_outlined,
        SettingsModule.team => Icons.groups_outlined,
        SettingsModule.devices => Icons.devices_other_outlined,
        SettingsModule.appInfo => Icons.info_outline_rounded,
      };
}

class SettingsModuleScreen extends StatelessWidget {
  const SettingsModuleScreen({required this.module, super.key});

  final SettingsModule module;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PgColors.background,
      appBar: AppBar(
        backgroundColor: PgColors.background,
        surfaceTintColor: PgColors.background,
        title: Text(
          module.title,
          style: const TextStyle(
            color: PgColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: PgPage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            module.subtitle,
            style: const TextStyle(
              color: PgColors.textSecondary,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildModule(context),
          const SizedBox(height: 16),
          const PgCard(
            backgroundColor: Color(0xFFF3F7FF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PgIconBox(icon: Icons.shield_outlined, size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mobile follows Desktop privacy boundaries. Document contents, originals and restore mappings are not exposed to organization metadata, app catalogs or MCP controls.',
                    style: TextStyle(color: PgColors.textSecondary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModule(BuildContext context) {
    return switch (module) {
      SettingsModule.accountDevices => _accountDevices(),
      SettingsModule.workspaces => _workspaces(),
      SettingsModule.services => _services(),
      SettingsModule.apps => _apps(),
      SettingsModule.aiMcp => _aiMcp(),
      SettingsModule.governance => _governance(),
      SettingsModule.policyCenter => _policyCenter(),
      SettingsModule.team => _team(),
      SettingsModule.devices => _devices(),
      SettingsModule.appInfo => _appInfo(),
    };
  }

  List<Widget> _accountDevices() => const [
        _ModuleCard(
          title: 'PrivacyGate Account',
          icon: Icons.person_outline_rounded,
          children: [
            _StatusRow(label: 'Profile', value: 'Mobile local profile'),
            _StatusRow(label: 'Plan / entitlement', value: 'Desktop-managed'),
            _StatusRow(label: 'Connected apps', value: 'Available after pairing'),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'Your devices',
          icon: Icons.devices_outlined,
          children: [
            _StatusRow(label: 'This phone', value: 'Active local device', positive: true),
            _StatusRow(label: 'Desktop companion', value: 'Not connected'),
            _StatusRow(label: 'Document sync', value: 'Disabled until trusted pairing'),
          ],
        ),
      ];

  List<Widget> _workspaces() => const [
        _ModuleCard(
          title: 'Workspace context',
          icon: Icons.workspaces_outline,
          children: [
            _StatusRow(label: 'Personal workspace', value: 'Local mobile context'),
            _StatusRow(label: 'Organization workspace', value: 'Available after Desktop sync'),
            _StatusRow(label: 'Policy enforcement', value: 'Applied locally when policy is synced'),
          ],
        ),
        SizedBox(height: 12),
        _Callout(
          icon: Icons.business_outlined,
          title: 'Enterprise parity',
          body: 'Organization Overview, Team, Devices, Governance and Policy Center stay separate logically, but are grouped under Settings on mobile so the five-tab navigation remains usable.',
        ),
      ];

  List<Widget> _services() => const [
        _ModuleCard(
          title: 'Local Privacy Bridge',
          icon: Icons.shield_outlined,
          children: [
            _StatusRow(label: 'Desktop service', value: 'Managed by Desktop companion'),
            _StatusRow(label: 'Bridge port', value: 'Desktop-only control'),
            _StatusRow(label: 'Browser-session mappings', value: 'Remain on Desktop'),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'Browser Protection',
          icon: Icons.language_outlined,
          children: [
            _StatusRow(label: 'Paired browsers', value: 'Desktop-managed'),
            _StatusRow(label: 'Extension install', value: 'Open from Desktop'),
            _StatusRow(label: 'Prompt protection', value: 'Local on paired device'),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'PrivacyGate runtime services',
          icon: Icons.settings_input_component_outlined,
          children: [
            _StatusRow(label: 'Local automation / n8n', value: 'Desktop service'),
            _StatusRow(label: 'MCP AI Direct', value: 'See AI & MCP'),
          ],
        ),
      ];

  List<Widget> _apps() => const [
        _ModuleCard(
          title: 'Connected on Desktop',
          icon: Icons.link_outlined,
          children: [
            _AppRow(name: 'Google Drive', note: 'OAuth / API'),
            _AppRow(name: 'Gmail', note: 'Gmail add-on / account'),
            _AppRow(name: 'Local Files', note: 'Device source boundary'),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'Provider catalog',
          icon: Icons.apps_outlined,
          children: [
            _AppRow(name: 'Google Calendar', note: 'Policy-controlled'),
            _AppRow(name: 'OneDrive', note: 'MCP / OAuth review'),
            _AppRow(name: 'SharePoint', note: 'MCP / OAuth review'),
            _AppRow(name: 'Outlook', note: 'MCP / OAuth review'),
            _AppRow(name: 'Microsoft Teams', note: 'MCP / OAuth review'),
            _AppRow(name: 'Notion', note: 'OAuth / API'),
            _AppRow(name: 'Dropbox', note: 'OAuth / API'),
            _AppRow(name: 'Box', note: 'OAuth / API'),
            _AppRow(name: 'Airtable', note: 'MCP / OAuth review'),
          ],
        ),
      ];

  List<Widget> _aiMcp() => const [
        _ModuleCard(
          title: 'Remote MCP',
          icon: Icons.cloud_outlined,
          children: [
            _StatusRow(label: 'ChatGPT / Claude', value: 'Desktop-managed connection'),
            _StatusRow(label: 'Authentication', value: 'Configured on Desktop'),
            _StatusRow(label: 'Exposed data', value: 'Protected Library only', positive: true),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'Local MCP',
          icon: Icons.hub_outlined,
          children: [
            _StatusRow(label: 'Local clients', value: 'Desktop setup'),
            _StatusRow(label: 'Public tunnel', value: 'Not required for Local MCP'),
            _StatusRow(label: 'Originals / mappings', value: 'Never exposed', positive: true),
          ],
        ),
        SizedBox(height: 12),
        _Callout(
          icon: Icons.auto_awesome_outlined,
          title: 'Client-ready use cases',
          body: 'Private AI knowledge access, property operations assistant and project document assistant all consume protected copies rather than original documents.',
        ),
      ];

  List<Widget> _governance() => const [
        _ModuleCard(
          title: 'Governance overview',
          icon: Icons.verified_user_outlined,
          children: [
            _StatusRow(label: 'Workspace', value: 'Synced from Desktop'),
            _StatusRow(label: 'Policy', value: 'Read-only mobile summary'),
            _StatusRow(label: 'Managed devices', value: 'Metadata only'),
            _StatusRow(label: 'Activity', value: 'Local metadata events'),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'Current Privacy Preflight',
          icon: Icons.fact_check_outlined,
          children: [
            _StatusRow(label: 'Detected', value: 'From active Protect session'),
            _StatusRow(label: 'Protected', value: 'From active Protect session'),
            _StatusRow(label: 'Residual', value: 'Second scan before handoff'),
          ],
        ),
        SizedBox(height: 12),
        _Callout(
          icon: Icons.storage_outlined,
          title: 'Local evidence',
          body: 'Governance can summarize tamper-evident local metadata when activity persistence is implemented. It does not upload document contents.',
        ),
      ];

  List<Widget> _policyCenter() => const [
        _ModuleCard(
          title: 'Flexible protection modes',
          icon: Icons.tune_rounded,
          children: [
            _PolicyMode(label: 'Required protect', note: 'Always protected; user cannot bypass the rule.'),
            _PolicyMode(label: 'Protect by default', note: 'Protected automatically with a clear default.'),
            _PolicyMode(label: 'Employee choice', note: 'User decides case by case before protection.'),
            _PolicyMode(label: 'Allow visible', note: 'May remain visible when company policy permits it.'),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'Sensitive-data rules',
          icon: Icons.rule_folder_outlined,
          children: [
            _RuleList(),
          ],
        ),
        SizedBox(height: 12),
        _ModuleCard(
          title: 'AI & Apps destinations',
          icon: Icons.alt_route_outlined,
          children: [
            _StatusRow(label: 'Approved AI destinations', value: 'Synced policy'),
            _StatusRow(label: 'Connected apps', value: 'Allow / block by policy'),
            _StatusRow(label: 'Second local scan', value: 'Before AI handoff', positive: true),
          ],
        ),
      ];

  List<Widget> _team() => const [
        _ModuleCard(
          title: 'Members & access',
          icon: Icons.groups_outlined,
          children: [
            _StatusRow(label: 'Active members', value: 'Available after organization sync'),
            _StatusRow(label: 'Admins / managers', value: 'Metadata only'),
            _StatusRow(label: 'Disabled access', value: 'Metadata only'),
            _StatusRow(label: 'Licensed seats', value: 'Desktop-managed'),
          ],
        ),
        SizedBox(height: 12),
        _Callout(
          icon: Icons.lock_outline_rounded,
          title: 'Admin boundary',
          body: 'Organization admins can see identity, access and managed-device metadata. Original documents, protected file contents, restore mappings and connector tokens remain local.',
        ),
      ];

  List<Widget> _devices() => const [
        _ModuleCard(
          title: 'Managed devices',
          icon: Icons.devices_other_outlined,
          children: [
            _StatusRow(label: 'Device inventory', value: 'Available after organization sync'),
            _StatusRow(label: 'Assigned user', value: 'Metadata only'),
            _StatusRow(label: 'Platform', value: 'Metadata only'),
            _StatusRow(label: 'Policy version', value: 'Synced from Desktop'),
            _StatusRow(label: 'Status', value: 'Active / disabled / revoked'),
          ],
        ),
      ];

  List<Widget> _appInfo() => const [
        _ModuleCard(
          title: 'Mobile build',
          icon: Icons.phone_android_outlined,
          children: [
            _StatusRow(label: 'Version', value: '0.1.0+1'),
            _StatusRow(label: 'Platforms', value: 'Android + iOS'),
            _StatusRow(label: 'Protection engine', value: 'Local core ready', positive: true),
            _StatusRow(label: 'Vault persistence', value: 'Native secure-storage pass pending'),
            _StatusRow(label: 'Desktop pairing', value: 'Companion integration pending'),
          ],
        ),
        SizedBox(height: 12),
        _Callout(
          icon: Icons.code_outlined,
          title: 'Desktop source of truth',
          body: 'Mobile parity is based on the pinned Desktop architecture while adapting tables, split panes and admin navigation to touch-first mobile patterns.',
        ),
      ];
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PgIconBox(icon: icon, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.positive = false,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: PgColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: positive ? PgColors.green : PgColors.textSecondary,
                fontWeight: positive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.name, required this.note});

  final String name;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.extension_outlined, color: PgColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(
                    color: PgColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Desktop',
            style: TextStyle(
              color: PgColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyMode extends StatelessWidget {
  const _PolicyMode({required this.label, required this.note});

  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: PgColors.blue, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: PgColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  note,
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

class _RuleList extends StatelessWidget {
  const _RuleList();

  @override
  Widget build(BuildContext context) {
    const rules = [
      'Credit card',
      'Customer ID',
      'Email address',
      'Employee ID',
      'Location',
      'Money amount',
      'Person name',
      'Phone number',
      'Street address',
      'Bank account',
      'Routing number',
      'Social Security Number',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final rule in rules)
          Chip(
            avatar: const Icon(Icons.shield_outlined, size: 16, color: PgColors.blue),
            label: Text(rule),
          ),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PgCard(
      backgroundColor: const Color(0xFFF3F7FF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PgIconBox(icon: icon, size: 40),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
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
