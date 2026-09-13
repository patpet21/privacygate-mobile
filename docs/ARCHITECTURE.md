# PrivacyGate Mobile Architecture (Draft)

## System roles

### PrivacyGate Desktop
- Master Vault for long-term storage.
- Canonical mapping/session library.
- Existing desktop integrations, MCP, restore workflows, and release baseline remain authoritative until compatibility work is complete.

### PrivacyGate Mobile
- Full local protect/review/restore client on **Android and iOS**.
- Shared mobile product architecture rather than an Android app followed by an iOS rewrite.
- Encrypted offline Mobile Vault.
- Share/import entry point for text/files coming from other mobile apps.
- Can work while Desktop is offline.

Android can be the first device used for rapid physical testing, but every core contract must be platform-neutral from the beginning.

## Cross-platform implementation model

Preferred direction: one shared cross-platform application layer, currently **Flutter**, plus small native adapters when the operating system requires platform-specific behavior.

```text
                     PrivacyGate Compatibility Contract
           sessions / placeholders / mappings / restore / metadata
                                  |
                    Shared Mobile App / Core Layer
                                  |
                  +---------------+---------------+
                  |                               |
             Android adapter                  iOS adapter
             Kotlin/native                    Swift/native
                  |                               |
          Android Keystore                  iOS Keychain
          BiometricPrompt                  LocalAuthentication
          Share intents                    Share Extension
          Android files                    iOS Files/document picker
```

The cross-platform framework is an implementation detail. PrivacyGate session formats and sync messages must never depend on Flutter, Android, or iOS-specific serialization.

## Core mobile flow

`Import/Share -> Local Scan -> Review -> Protect -> Save/Share -> Optional Sync to Desktop`

Restore flow:

`Protected content -> Resolve session/mapping -> Restore locally -> Copy/Share/Export`

## Offline Mobile Vault

The user controls the local storage budget. Initial UX options may include presets such as 500 MB / 1.5 GB / 3 GB plus a custom limit.

A mobile item can exist in two modes:

1. **Protected only** — protected file/content is available offline but restore mapping is not stored on mobile.
2. **Full offline session** — protected content plus encrypted mapping/session metadata are available, allowing restore while Desktop is offline.

Full offline sessions should support device authentication/biometrics before sensitive restore operations.

The vault's logical model is shared across Android and iOS. Encryption keys remain device-local and use the strongest appropriate platform-backed secure storage available on each OS.

## Platform security adapters

### Android
- Android Keystore for device-bound key material.
- Android biometric APIs for gated restore/unlock where appropriate.
- Android share intents / share target support.
- Android Storage Access Framework or equivalent system file picker flows.

### iOS
- Keychain for device-bound secrets/key material.
- LocalAuthentication / Face ID / Touch ID for gated restore/unlock where appropriate.
- iOS Share Extension for supported incoming share workflows.
- iOS Files/document picker for user-selected files.
- App Groups only if required for controlled data exchange between the main app and an iOS extension; never as an excuse to persist plaintext sensitive mappings.

## Desktop sync

Pair Desktop and Mobile explicitly, ideally by QR/device pairing. Sync should be encrypted and must not require persistent cloud storage of original content.

When Desktop is online, Mobile can:
- upload newly created sessions to the Master Vault;
- receive selected files/sessions for offline availability;
- reconcile metadata/state;
- optionally remove local copies after successful transfer.

Android and iOS must use the same sync protocol and compatibility versioning.

## Offline library selection

Do not automatically copy arbitrary files. Support user-driven options such as:
- Make available on mobile
- Recent 10 / Recent 25
- Favorites
- Selected files

## Compatibility contract

Desktop, Android, and iOS must agree on:
- session IDs;
- placeholder naming;
- entity types;
- mapping format;
- restore behavior;
- protected document metadata;
- library/session serialization;
- protocol/version identifiers required for sync compatibility.

Before implementing the mobile detector deeply, audit the current Desktop repository and formalize this contract.

## Integrations

### Share flow
Android should register as a target for supported share intents. iOS should provide an equivalent Share Extension where platform rules allow it. Both paths must send imported content into the same PrivacyGate protection flow.

### MCP
Protected files synchronized to the Desktop library can remain available to the existing PrivacyGate MCP workflow. Mobile may later expose session/file selection that makes MCP usage easier from ChatGPT mobile.

### Gmail / Drive
Treat Gmail mobile add-on behavior and Google Drive access as integration tracks separate from the base mobile app so they do not block the mobile MVP. Platform differences must be documented rather than hidden behind assumed feature parity.

## Testing strategy

Compatibility fixtures should be executable against Desktop, Android, and iOS behavior. At minimum they must verify that the same canonical session produces compatible placeholders, mappings, metadata, and restore results.

Physical-device testing should include:
- Android phone first for fast iteration.
- iPhone before any feature is considered cross-platform complete.

## Explicitly deferred

- PrivacyGate custom keyboard.
- Accessibility/overlay-based interception of AI responses.
- Exact in-app replica of the browser extension response widget inside native ChatGPT.
