# PrivacyGate Mobile Roadmap

## Phase 0 — Desktop compatibility audit
- Inspect stable PrivacyGate Desktop baseline.
- Identify reusable core logic vs desktop-only UI/integration code.
- Freeze the shared session, placeholder, mapping, and library contract.
- Create compatibility test fixtures.

## Phase 1 — Android bootstrap
- Create Android project in Android Studio.
- Configure package/application ID.
- Run first debug build on a Samsung Android device.
- Add basic app shell and navigation.

## Phase 2 — Core protection MVP
- Paste/type text.
- Local detection.
- Review detections.
- Protect/anonymize.
- Local restore.
- Copy/share protected output.

## Phase 3 — File workflows
- Import PDF.
- Import images/scans.
- Export protected files.
- Android Share Target for incoming text/files.
- Send/share protected content to external AI apps.

## Phase 4 — Mobile Vault / offline mode
- Encrypted local vault.
- Storage limit presets + custom limit.
- Protected-only vs full-offline session.
- Retention/auto-cleanup controls.
- Optional biometric gate for restore.

## Phase 5 — Desktop pairing and sync
- QR/device pairing.
- Encrypted Desktop <-> Mobile communication.
- Upload new mobile sessions to Desktop Master Vault.
- Download selected/recent/favorite sessions for offline mobile use.
- Conflict/state handling.

## Phase 6 — Integrations
- MCP workflow improvements for mobile-created/protected files.
- Gmail mobile add-on verification and integration path.
- Drive/mobile file workflow.

## Later
- Custom PrivacyGate keyboard.
- Advanced AI response restore UX.
- iOS implementation after Android architecture is stable.
