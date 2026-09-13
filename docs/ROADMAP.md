# PrivacyGate Mobile Roadmap

## Phase 0 — Desktop compatibility audit
- Inspect the stable PrivacyGate Desktop baseline.
- Identify reusable core logic vs desktop-only UI/integration code.
- Freeze the shared session, placeholder, mapping, restore, and library contract.
- Add protocol/version identifiers where required.
- Create compatibility test fixtures that can later be run against Desktop, Android, and iOS behavior.

## Phase 1 — Cross-platform mobile bootstrap
- Create one shared mobile project, with Flutter as the current preferred direction unless the audit exposes a hard blocker.
- Configure Android application ID and iOS bundle identifier deliberately before store/signing work.
- Create the minimal shared app shell and navigation.
- Add Android and iOS platform adapter boundaries from the start.
- Produce the first Android debug build and run it on a real Samsung device.
- Produce the first iOS debug build as soon as a macOS/Xcode signing environment is available.

## Phase 2 — Core protection MVP
- Paste/type text.
- Local detection.
- Review detections.
- Protect/anonymize.
- Local restore.
- Copy/share protected output.
- Keep behavior compatible on Android and iOS.

## Phase 3 — File and share workflows
- Import PDF.
- Import images/scans.
- Export protected files.
- Android Share Target for incoming text/files.
- iOS Share Extension for supported incoming text/files.
- Send/share protected content to external AI apps.
- Verify equivalent PrivacyGate outcomes even where platform UX differs.

## Phase 4 — Mobile Vault / offline mode
- Shared logical vault model.
- Android device-backed secure key storage.
- iOS Keychain-backed secure key storage.
- Storage limit presets + custom limit.
- Protected-only vs full-offline session.
- Retention/auto-cleanup controls.
- Optional biometric gate for restore using each platform's native authentication APIs.

## Phase 5 — Desktop pairing and sync
- QR/device pairing.
- Encrypted Desktop <-> Mobile communication.
- One sync protocol for Android and iOS.
- Upload new mobile sessions to Desktop Master Vault.
- Download selected/recent/favorite sessions for offline mobile use.
- Conflict/state handling.
- Compatibility/version negotiation.

## Phase 6 — Integrations
- MCP workflow improvements for mobile-created/protected files.
- Gmail mobile add-on verification and integration path.
- Drive/mobile file workflow.
- Document Android/iOS differences explicitly rather than assuming identical OS capabilities.

## Phase 7 — Store readiness
- Security/privacy review of mobile data handling.
- Android signing/release configuration and Play Store packaging.
- iOS signing, provisioning, App Store Connect packaging, privacy disclosures, and review assets.
- Verify no production signing credentials or secrets are committed to GitHub.
- Regression test Desktop <-> Android <-> iOS session compatibility before release.

## Later
- Custom PrivacyGate keyboard.
- Advanced AI response restore UX.
- Additional mobile integrations that require deeper OS-specific work.
