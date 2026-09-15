# PrivacyGate Mobile Desktop-Parity Specification

Date: 2026-09-15

## Source of truth

- Mobile repository: `patpet21/privacygate-mobile`
- Mobile parity branch: `feat/mobile-desktop-parity-20260915`
- Desktop source of truth: `patpet21/ai-pm-lab-privacy-gate`
- Pinned Desktop commit: `754f412596c7f32f04c3f50714dcd064704a3f13`
- Desktop is read-only for this mobile work.

## Product rule

Mobile preserves Desktop logic, privacy boundaries and feature taxonomy, but it does not compress Desktop layouts onto a phone.

Desktop tables become mobile lists or drill-down pages. Desktop split panes become sequential steps or tabs. Long filter rows become wrapping or horizontally scrollable chips. Organization/admin surfaces live under Settings so the five-tab mobile navigation stays usable.

## Primary mobile navigation

1. Home
2. Protect
3. Library
4. Activity
5. Settings

## Desktop-to-mobile mapping

| Desktop | Mobile |
| --- | --- |
| Overview | Home |
| Protect | Protect |
| Restore | Protect/Restore flow, Home shortcut, Library action |
| Library | Library |
| Activity | Activity |
| Apps | Settings > Apps & Integrations + Home summary |
| MCP / AI Direct | Settings > AI & MCP + Home summary |
| Governance | Settings > Governance |
| Policy Center | Settings > Policy Center |
| Team | Settings > Team & Members |
| Devices | Settings > Managed Devices |
| Settings > Account & Devices | Settings > Account & Devices |
| Settings > Services | Settings > Services |

## Home

Home is the mobile adaptation of Desktop Overview.

Required blocks:

- PrivacyGate header and Desktop connection status.
- Quick actions: Protect, Restore, Scan, Library.
- Local privacy status.
- Compact overview metrics derived only from available mobile state.
- Recent documents.
- Connected apps summary.
- Recent activity.
- AI tools & MCP summary.
- Privacy/local-processing boundary note.

No invented enterprise metrics. When persistence or Desktop sync is unavailable, the UI must say so explicitly.

## Protect

Protect remains the primary operational flow and should track Desktop behavior closely.

Mobile stages:

1. Import source.
2. Select protection profile.
3. Configure per-document scan controls.
4. Scan locally.
5. Review detections.
6. Choose Protect vs Keep per finding.
7. Preview protected copy.
8. Run second scan / privacy preflight before handoff.
9. Save protected copy and local restore mapping according to selected policy.

Desktop split-pane original/protected views become tabs or sequential preview screens on mobile.

## Restore

Restore entry points:

- Home quick action.
- Protect after a protected copy exists.
- Library item action when a local mapping is available.

Mobile restore stages:

1. AI result / protected result.
2. Match original session or mapping.
3. Preview restore.
4. Restore locally.

Originals and restore mappings remain local.

## Library

Required mobile concepts:

- All.
- Desktop.
- Mobile Offline.
- Restorable.
- Favorites.
- Mobile Vault capacity and storage policy.
- Desktop sync state.
- Protected file list.
- Offline file list.
- Restore availability.
- Protected-only vs full-session status.

Only protected copies may cross the AI/MCP boundary. Originals and restore mappings remain excluded.

## Activity

Activity aggregates local metadata events for:

- Protect.
- Restore.
- Sync.
- Desktop connection.
- Policy sync.
- App / MCP handoff.

Activity telemetry is not sent to a server unless a future explicitly documented feature changes that behavior.

## Settings architecture

### Device controls

- Desktop connection.
- Sync when Desktop is available.
- Mobile Vault capacity.
- Automatic cleanup.
- Remove mobile copy after successful sync.
- Require biometrics/device auth for restore.

### Core services

- Account & Devices.
- Workspaces.
- Services.

### Data, AI & governance

- Apps & Integrations.
- AI & MCP.
- Governance.
- Policy Center.

### Organization

- Team & Members.
- Managed Devices.

### Application

- Application Info.

## Desktop feature parity notes

### Apps

Mirror the Desktop provider taxonomy and policy state without pretending that an unimplemented mobile connector is live. Gmail, Google Drive and Local Files are first-class sources. Additional providers remain policy/catalog entries until their mobile connector work is implemented.

### MCP / AI Direct

Expose the same conceptual separation as Desktop:

- Remote MCP.
- Local MCP.
- Protected Library boundary.
- Originals and restore mappings excluded.

### Governance

Mobile Governance is a touch-first summary of:

- Workspace.
- Policy.
- Devices.
- Activity.
- Current Privacy Preflight.
- Local evidence.

### Policy Center

Expose the Desktop protection modes:

- Required protect.
- Protect by default.
- Employee choice.
- Allow visible.

Policy-managed sensitive-data rules and AI/app destination controls must be represented as read-only until trusted policy sync and edit permissions exist on mobile.

### Team and Devices

Admin screens show identity, role, seat, access and managed-device metadata only. They do not expose document contents, protected file contents, restore mappings or connector credentials.

## Responsive rules

- No phone-width `RenderFlex` overflow is acceptable.
- Use 2-column card grids only where content has enough vertical room.
- Use vertical stacking below the mobile breakpoint for dense cards.
- Use wrapping chips for phone-width Library filters.
- Use drill-down pages instead of Desktop-sized tables.
- Use sticky or visually prominent primary actions in Protect/Restore flows.
- Respect SafeArea and bottom navigation insets.

## Current implementation priority

P0:

- Remove Home quick-action overflow.
- Prevent clipped Library filters.
- Keep narrow-width Settings readable.
- Add phone-width widget smoke coverage.

P1:

- Complete Home/Overview parity.
- Complete Settings module architecture.
- Complete Library persistence/status UI.

P2:

- Dedicated Restore flow.
- Desktop pairing and sync.
- Secure native Vault persistence.
- Activity persistence.
- Mobile app/provider connectors.
- MCP controls backed by real connection state.
- Organization policy/team/device sync.

## Acceptance criteria

A parity pass is acceptable when:

- `flutter analyze` reports no issues.
- `flutter test` passes.
- 360 logical-pixel phone width has no overflow on Home, Protect, Library, Activity or Settings.
- Desktop-only controls are clearly marked rather than presented as live.
- Protected data boundaries match Desktop behavior.
- The five-tab navigation remains unchanged.
- Settings drill-down screens expose the Desktop feature taxonomy without turning the main Settings page into one unbounded form.
