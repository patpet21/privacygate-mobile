# Flutter bootstrap status

Branch: `feat/flutter-cross-platform-bootstrap-20260913`

## Current state

The project has moved from a generic bootstrap toward the first Desktop-to-Mobile functional vertical slice: **Text Protect**.

Implemented source now includes:

- shared Flutter/Dart app shell for Android and iOS;
- Desktop-compatible finding, mapping, protection and session models;
- reversible/generic/mask/redact protection behavior;
- longest-token-first local restore;
- canonical Desktop profile/scope configuration;
- per-document `ProtectionPolicy` separated from general app/Vault Settings;
- explicit `scanLanguage` (`en` / `it`) used as detector language, not UI language;
- Desktop-aligned Protect controls for profile, scope, mode, confidence, paste text, scan and clear;
- review controls: filter, Protect all, Keep all, Invert, category selection and manual missed-item recovery;
- second local scan of protected text before copy/export is enabled;
- Copy protected and Restore locally actions for the text slice;
- Mobile Vault policy settings kept separate from document scan policy;
- portable SessionManifest / ProtectedArtifact / RestoreBundle draft models and strict decoder;
- source-derived fixture policy/importer for the pinned Desktop English v1 benchmark.

See `docs/PROTECT_VERTICAL_SLICE.md` for the exact behavior represented in this slice.

## Canonical fixture policy

Small hand-written cases are smoke/contract tests only. Detector parity will use the existing Desktop-owned English v1 benchmark at the pinned Desktop commit. Mobile does not rewrite expected labels to fit its implementation.

The pinned Desktop tree does not yet contain an equivalent frozen Italian JSONL corpus, so Mobile does not invent one and call it parity.

## Important limitations

`BootstrapPatternDetector` remains temporary and currently detects only the narrow bootstrap patterns. The UI/core flow is real, but production detector parity is not claimed.

The Dart reversible-value normalization currently uses `toLowerCase()` while Desktop uses Python `casefold()`. Canonical fixtures must freeze any Unicode normalization differences.

Mobile Vault/session persistence, native file handling, Android Keystore/iOS Keychain handlers and Desktop pairing/sync are not yet active. No fake persistence or fake connection has been introduced.

## Native Android/iOS host folders

Standard Android/iOS Flutter host folders still need to be generated and the checked-in suite executed with a real Flutter toolchain:

```text
flutter create --platforms=android,ios --org com.aipmlab --project-name privacygate .
flutter pub get
flutter analyze
flutter test
```

Before detector parity runs, synchronize the exact Desktop fixture corpus from a local Desktop clone:

```text
python tool/sync_desktop_fixtures.py --desktop-repo <path-to-ai-pm-lab-privacy-gate>
```

## Next gates

1. Run the real Flutter toolchain and fix any compile/analyzer/test issues before calling the branch buildable.
2. Replace the temporary detector with a Desktop-compatible detector measured against canonical Desktop fixtures.
3. Add encrypted Mobile Library/Vault persistence for the completed text slice.
4. Add Copy/Share/Save workflow only where the native/mobile implementation is real.
5. Extend the same vertical-slice method to TXT, then PDF/Office/images according to audited Desktop behavior.
6. Implement trusted Desktop pairing/sync after the session and encrypted Vault objects are stable.
