# PrivacyGate Mobile

Cross-platform mobile client for PrivacyGate on **Android and iOS**.

## Product direction

PrivacyGate Mobile is intended to reproduce the core PrivacyGate workflow on both Android and iPhone while remaining interoperable with the existing PrivacyGate Desktop app.

Android may be the first physical device used during development, but iOS is **not** a later port. The mobile architecture, shared contracts, vault model, sync protocol, and tests must be designed for both platforms from the beginning.

Core goals:
- Import text, PDFs, images/scans, and supported shared content.
- Detect sensitive data locally where possible.
- Review detections before protection.
- Protect/anonymize using the same PrivacyGate placeholder/session conventions as Desktop.
- Export/share protected content to AI tools and other apps.
- Maintain an encrypted Mobile Vault for offline work.
- Sync sessions, mappings, and selected offline files with the Desktop Master Vault when the computer is available.
- Support MCP workflows using already-protected local files.
- Keep Android and iOS behavior compatible at the PrivacyGate session level.

## Architecture principles

1. **Desktop = Master Vault**
2. **Mobile = Full PrivacyGate client + encrypted offline vault**
3. **Android and iOS share one PrivacyGate mobile product architecture**
4. **No silent cloud storage of original sensitive content**
5. **Desktop, Android, and iOS must share the same session/mapping/placeholder contract**
6. **Offline use must remain possible when Desktop is unavailable**
7. **User controls what is retained on the phone and for how long**
8. **Platform-specific security and share features are implemented through explicit Android/iOS adapters**

## Initial phases

- Phase 0: Define compatibility contract with PrivacyGate Desktop.
- Phase 1: Cross-platform mobile bootstrap for Android and iOS; Android can be the first physical-device test.
- Phase 2: Text protect/review/restore flow.
- Phase 3: PDF/image import and export/share flow on both platforms.
- Phase 4: Encrypted Mobile Vault and offline storage controls.
- Phase 5: Desktop pairing, encrypted sync, and selected offline library.
- Phase 6: MCP and Gmail/Drive integration paths.
- Phase 7: Store hardening, Android release path, and Apple App Store release path.

## Implementation direction

Use a shared cross-platform mobile codebase unless the Desktop compatibility audit exposes a hard blocker. Flutter is the current preferred direction because it can provide one UI/business layer for Android and iOS while allowing native Kotlin/Swift adapters where platform-specific behavior is required.

Do not embed Android-only assumptions into session formats, vault metadata, sync messages, or compatibility fixtures.

## Status

Repository initialized. Mobile implementation has not started yet. The next step is to finish the Desktop compatibility audit and then bootstrap the shared Android/iOS project structure before adding protection logic.
