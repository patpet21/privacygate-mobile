# PrivacyGate Mobile

Cross-platform mobile client for PrivacyGate on **Android and iOS**.

## Product direction

PrivacyGate Mobile reproduces the core PrivacyGate workflow on phones while remaining interoperable with PrivacyGate Desktop.

Android is the first physical-device development target, but the mobile architecture is shared from the beginning so iOS is not treated as a later rewrite.

Core goals:
- Import/paste text and later supported files/images.
- Detect sensitive data locally.
- Review detections before protection.
- Protect/anonymize using the same PrivacyGate placeholder/session conventions as Desktop.
- Restore locally when the required mapping is available in the Mobile Vault.
- Export/share protected content to AI tools and other apps.
- Maintain an encrypted Mobile Vault for offline work.
- Sync sessions, mappings, and selected offline files with the Desktop Master Vault.

## Architecture principles

1. **Desktop = Master Vault**
2. **Mobile = Full PrivacyGate client + encrypted offline vault**
3. **Android and iOS share one mobile product architecture**
4. **No silent cloud storage of original sensitive content**
5. **Desktop and Mobile share one session/mapping/placeholder contract**
6. **Offline use remains possible when Desktop is unavailable**
7. **User controls what is retained on the phone and for how long**

## Current implementation branch

`feat/flutter-cross-platform-bootstrap-20260913`

Current bootstrap contains:
- Flutter/Dart project manifest and app entrypoint;
- Paste -> Scan -> Review -> Protect -> Restore locally flow;
- Desktop-compatible base reversible placeholder generation;
- reversible mapping/restore models;
- temporary shell detector for email and US-style phone patterns;
- Mobile Vault/key-store boundaries;
- unit tests for the base protect/restore contract.

The temporary detector is **not** production parity. The next pass replaces it with the audited Desktop-compatible detector/profile layer.

See `docs/FLUTTER_BOOTSTRAP_STATUS.md` for the exact state and next gates.
