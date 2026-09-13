# PrivacyGate Mobile Vault Specification

## Product rule

PrivacyGate Mobile is not a thin companion. It is a full local PrivacyGate client that can continue protecting, restoring, and managing selected content while the Desktop is unavailable.

**Desktop = Master Vault**  
**Mobile = Full PrivacyGate + encrypted offline cache/vault controlled by the user**

The Desktop remains the authoritative long-term archive and synchronization anchor. Mobile may temporarily or intentionally hold encrypted protected content and, where explicitly selected, encrypted restore mappings.

## Offline behavior

Mobile must support the following without the Desktop being online:

- import/paste text;
- import supported files, beginning with PDF and later additional document/image formats;
- run local detection and review;
- protect/anonymize locally;
- create and export/share the protected result;
- create and retain a session;
- restore locally when the required mapping is present in the Mobile Vault;
- browse content deliberately made available offline.

If Desktop connectivity disappears during a workflow, Mobile must not fail or silently discard state. The app should offer:

> Desktop unavailable. Keep this session securely on this device?

Actions:

- **Keep locally** — retain a full encrypted offline session, including restore capability;
- **Protected file only** — retain only the protected artifact and non-sensitive metadata;
- **Discard** — remove the working session from Mobile after explicit confirmation.

## Mobile Vault security boundary

All retained Mobile Vault data must be encrypted at rest. Sensitive mappings must never be stored as ordinary app files, plaintext SQLite fields, logs, caches, notifications, clipboard history, or unencrypted exports.

The Mobile Vault should use Android platform-backed key storage where possible. Full-session restore operations should support an additional user-presence gate such as device biometrics or a PrivacyGate PIN.

The security model must distinguish protected artifacts from data that can reconstruct originals.

## Two offline levels

### 1. Protected copy only

Example:

```text
Contract_ABC_protected.pdf
[[PERSON_001]]
[[ADDRESS_001]]
```

This mode may include:

- protected file or protected text;
- session identifier sufficient for organization/sync;
- protected-only metadata;
- labels/favorites/offline state.

It must not contain the reversible mapping required to reconstruct original sensitive values.

Consequences:

- safe for offline reading/sharing with AI tools;
- cannot perform local restore while Desktop is unavailable;
- restore can become available after the corresponding full session/mapping is retrieved from the trusted Desktop.

### 2. Full offline session

A full offline session contains the encrypted material required for independent restore.

Example logical contents:

```text
Contract_ABC
Protected file
Session ID
Protection metadata
Encrypted mapping
Restore capability
```

Requirements:

- encrypted at rest;
- mapping isolated from protected artifacts where practical;
- biometric/PIN user-presence option for restore;
- explicit offline status in the UI;
- auditable creation/removal state without logging sensitive values;
- removable independently from the Desktop Master Vault after successful sync.

## Offline Library

Do not automatically transfer an arbitrary fixed number of files.

Offline availability is user-controlled from either device.

Desktop action:

> Make available on mobile

Mobile action:

> Download for offline use

Suggested selection helpers:

- Recent 10
- Recent 25
- Favorites
- Selected files

Each selected item must also support choosing the offline level when applicable:

- **Protected only**
- **Full session**

Suggested Mobile Library presentation:

```text
PRIVACYGATE MOBILE LIBRARY

Available offline
Contract A          Full session
Invoice B           Protected only
Email Project C     Full session

Desktop only
Contract D
Project Report E

Storage
1.2 GB / 1.5 GB used

[ Manage Offline Files ]
```

When Desktop is unreachable and a requested item is not stored locally, Mobile should state clearly:

> Desktop unavailable — this file isn't stored offline.

No hidden fallback to a cloud copy should occur unless a future cloud/relay mode is explicitly enabled by the user and covered by a separate security design.

## Storage controls

The Mobile Vault needs an explicit storage budget controlled by the user.

Initial presets:

- 500 MB
- 1.5 GB
- 3 GB
- Custom

The UI should show current consumption, for example:

```text
820 MB of 1.5 GB used
```

A slider may be used if the selected limit remains visible numerically.

When the limit is approached, PrivacyGate must not delete restore-capable sessions silently. Cleanup must follow configured retention rules and protect pinned/favorite items as defined by product policy.

## Retention and automatic cleanup

Supported policies:

- after 1 day;
- after 7 days;
- after 30 days;
- never;
- manual removal.

Recommended rules:

- cleanup affects only Mobile copies, never the Desktop Master Vault;
- a newly created unsynced full session must not be auto-deleted before successful synchronization unless the user explicitly chooses a destructive policy and confirms it;
- favorites/pinned items may be exempt from cleanup;
- protected-only copies and full sessions may have different retention policies later if needed.

## Sync model

When a paired Desktop becomes reachable, Mobile and Desktop reconcile state over the trusted encrypted pairing channel.

Mobile to Desktop:

```text
New session       -> Master Vault
New mapping       -> Master Vault
Protected file    -> Desktop Library
Metadata/state    -> Reconcile
```

Desktop to Mobile:

```text
Selected offline files  -> Mobile Vault
Favorites               -> Optional download set
Recent files             -> Optional download set
Metadata/state           -> Reconcile
```

After a successful transfer from Mobile to Desktop, present a simple choice:

> Successfully transferred to Desktop.

- **Keep mobile copy**
- **Remove mobile copy**

Sync should be resumable and idempotent. Repeating a transfer must not create duplicate sessions or regenerate conflicting placeholder mappings.

## Source of truth and conflict rules

Desktop is the long-term Master Vault, but Mobile-created sessions are authoritative for their own immutable protection identity until first successful ingestion by Desktop.

The shared compatibility contract must define at minimum:

- globally unique session ID;
- source device ID;
- creation timestamp;
- placeholder schema/version;
- protection mode/profile;
- entity types;
- mapping serialization version;
- content/artifact hashes where useful;
- revision/state metadata;
- sync status;
- deletion/tombstone semantics.

Desktop must preserve the original session identity when ingesting a Mobile-created session.

Conflicting mappings for the same session ID are a hard error and must never be merged heuristically.

## Settings — Mobile Vault

Suggested Mobile settings section:

### Mobile Vault

- Storage limit
- Offline Library
- Automatic cleanup
- Require biometrics/PIN for restore
- Sync when Desktop is available
- Remove Mobile copy after successful sync (optional preference)
- Vault status / encrypted storage used

Suggested Desktop settings integration:

### Mobile & Devices

- Connect mobile device
- Show pairing QR code
- Paired devices
- Last sync
- Make files available on mobile
- Revoke/unpair device

The Desktop settings UI should not be implemented until the pairing/session protocol is defined well enough that the UI is not encoding unstable assumptions.

## Connectivity evolution

### Stage 1 — direct trusted Desktop/Mobile connection

```text
Mobile <-> encrypted pairing channel <-> Desktop
```

The core product must work without a permanent PrivacyGate cloud service.

### Stage 2 — optional relay/server architecture

A later relay may allow paired devices to communicate across different networks or while direct reachability is unavailable.

```text
Mobile -> encrypted relay path -> Desktop
```

The relay must not redefine the data model. It changes transport, not ownership.

The target security property is that the relay is not the Master Vault and does not require plaintext original PII or plaintext restore mappings.

Persistent cloud storage, account-based multi-device sync, key escrow, recovery, and organization management are separate future architecture decisions and must not be implied by the first Mobile Vault implementation.

## Required compatibility tests

Before calling the Mobile Vault compatible with Desktop, test at minimum:

1. Protect the same fixture on Desktop and Mobile and verify placeholder/schema compatibility.
2. Create a session on Mobile, sync it to Desktop, and restore successfully on Desktop.
3. Create a session on Desktop, download it as a full offline session, and restore successfully on Mobile.
4. Download the same Desktop item as protected-only and verify Mobile cannot restore while Desktop is unavailable.
5. Interrupt a sync and verify retry does not duplicate the session.
6. Sync a Mobile-created protected PDF and verify Desktop Library metadata remains valid.
7. Remove a Mobile copy after successful transfer and verify the Desktop Master Vault remains intact.
8. Trigger automatic cleanup and verify unsynced critical sessions are not silently destroyed.
9. Revoke a paired device and verify it cannot request new Desktop content.
10. Verify no plaintext mapping/original sensitive values are written to logs or ordinary app storage during these workflows.

## Implementation boundary

This document defines behavior and compatibility. It does not yet choose the final Android database/encryption stack, transport library, relay provider, biometric API wrapper, or server architecture.

Those implementation choices should be made only after the Desktop compatibility audit freezes the session/mapping/library contract at an identified Desktop repository commit.
