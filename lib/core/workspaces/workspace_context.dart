import 'package:flutter/foundation.dart';

enum WorkspaceKind { personal, organization }

class PrivacyGateWorkspace {
  const PrivacyGateWorkspace({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.kind,
  });

  final String id;
  final String name;
  final String subtitle;
  final WorkspaceKind kind;
}

class WorkspaceContext extends ChangeNotifier {
  WorkspaceContext._();

  static final WorkspaceContext instance = WorkspaceContext._();

  final List<PrivacyGateWorkspace> _workspaces = const [
    PrivacyGateWorkspace(
      id: 'personal',
      name: 'PrivacyGate Personal',
      subtitle: 'Personal workspace',
      kind: WorkspaceKind.personal,
    ),
    PrivacyGateWorkspace(
      id: 'enterprise',
      name: 'Enterprise organization',
      subtitle: 'Organization workspace',
      kind: WorkspaceKind.organization,
    ),
  ];

  String _activeId = 'personal';

  List<PrivacyGateWorkspace> get workspaces => List.unmodifiable(_workspaces);

  PrivacyGateWorkspace get activeWorkspace =>
      _workspaces.firstWhere((workspace) => workspace.id == _activeId);

  bool get isPersonal => activeWorkspace.kind == WorkspaceKind.personal;

  void select(String workspaceId) {
    final exists = _workspaces.any((workspace) => workspace.id == workspaceId);
    if (!exists || workspaceId == _activeId) return;
    _activeId = workspaceId;
    notifyListeners();
  }
}
