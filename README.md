# PrivacyGate Mobile

Mobile companion and full mobile client for PrivacyGate.

## Product direction

PrivacyGate Mobile is intended to reproduce the core PrivacyGate workflow on Android first, while remaining interoperable with the existing PrivacyGate Desktop app.

Core goals:
- Import text, PDFs, images/scans, and supported shared content.
- Detect sensitive data locally where possible.
- Review detections before protection.
- Protect/anonymize using the same PrivacyGate placeholder/session conventions as Desktop.
- Export/share protected content to AI tools and other apps.
- Maintain an encrypted Mobile Vault for offline work.
- Sync sessions, mappings, and selected offline files with the Desktop Master Vault when the PC is available.
- Support MCP workflows using already-protected local files.

## Architecture principles

1. **Desktop = Master Vault**
2. **Mobile = Full PrivacyGate client + encrypted offline vault**
3. **No silent cloud storage of original sensitive content**
4. **Desktop and Mobile must share the same session/mapping/placeholder format**
5. **Offline use must remain possible when the Desktop is unavailable**
6. **User controls what is retained on the phone and for how long**

## Initial phases

- Phase 0: Define compatibility contract with PrivacyGate Desktop.
- Phase 1: Android project bootstrap and device test on Samsung Android phone.
- Phase 2: Text protect/review/restore flow.
- Phase 3: PDF/image import and export/share flow.
- Phase 4: Encrypted Mobile Vault and offline storage controls.
- Phase 5: Desktop pairing, encrypted sync, and selected offline library.
- Phase 6: MCP and Gmail/Drive integration paths.

## Status

Repository initialized. Android implementation has not started yet; first development build will be created and tested locally with Android Studio + Android SDK before release automation is added.
