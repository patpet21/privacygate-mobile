# PrivacyGate Mobile Architecture (Draft)

## System roles

### PrivacyGate Desktop
- Master Vault for long-term storage.
- Canonical mapping/session library.
- Existing desktop integrations, MCP, restore workflows, and release baseline remain authoritative until compatibility work is complete.

### PrivacyGate Mobile
- Full local protect/review/restore client.
- Android-first implementation.
- Encrypted offline Mobile Vault.
- Share target for text/files coming from other mobile apps.
- Can work while Desktop is offline.

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

## Desktop sync

Pair Desktop and Mobile explicitly, ideally by QR/device pairing. Sync should be encrypted and must not require persistent cloud storage of original content.

When Desktop is online, Mobile can:
- upload newly created sessions to the Master Vault;
- receive selected files/sessions for offline availability;
- reconcile metadata/state;
- optionally remove local copies after successful transfer.

## Offline library selection

Do not automatically copy arbitrary files. Support user-driven options such as:
- Make available on mobile
- Recent 10 / Recent 25
- Favorites
- Selected files

## Compatibility contract

Desktop and Mobile must agree on:
- session IDs;
- placeholder naming;
- entity types;
- mapping format;
- restore behavior;
- protected document metadata;
- library/session serialization.

Before implementing the mobile detector deeply, audit the current Desktop repository and formalize this contract.

## Integrations

### Share flow
Mobile should register as a target for supported Android share intents so text/files can pass through PrivacyGate before being sent to ChatGPT or other AI apps.

### MCP
Protected files synchronized to the Desktop library can remain available to the existing PrivacyGate MCP workflow. Mobile may later expose session/file selection that makes MCP usage easier from ChatGPT mobile.

### Gmail / Drive
Treat Gmail mobile add-on behavior and Google Drive access as integration tracks separate from the base mobile app so they do not block the Android MVP.

## Explicitly deferred

- PrivacyGate custom keyboard.
- Accessibility/overlay-based interception of AI responses.
- Exact in-app replica of the browser extension response widget inside native ChatGPT.
