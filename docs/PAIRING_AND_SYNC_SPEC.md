# PrivacyGate Desktop <-> Mobile Pairing and Sync — Draft v1

Audit basis: Desktop source `754f412596c7f32f04c3f50714dcd064704a3f13`.

## Product goal

Pair PrivacyGate Mobile explicitly with a trusted PrivacyGate Desktop installation. Desktop remains the long-term Master Vault. Mobile can operate independently with an encrypted Mobile Vault and later synchronize when Desktop becomes reachable.

The initial implementation requires no Firebase, Supabase or permanent PrivacyGate cloud backend. A future relay may be added without changing session/artifact semantics.

## Verified Desktop foundations

The current Desktop already provides useful foundations:

- browser pairing with short-lived one-time challenge, expiry, attempt limits and per-client revoke;
- a stable opaque Desktop installation/device identity;
- OS-backed secret storage;
- a stable P-256 device signing identity for signed infrastructure requests;
- durable browser AI `session_id` + turn/mapping persistence;
- separate Personal Library `document_id` identities;
- protected-only storage physically isolated from restore mappings.

The existing browser Local API is intentionally **localhost-only** and must remain so. Mobile sync therefore needs a dedicated Desktop companion/sync service rather than exposing the browser API to the LAN.

## Identity model

Keep identities distinct:

```text
Desktop installation/device identity
Mobile device identity
PrivacyGate session_id
Artifact/document_id
```

A paired Mobile device must have its own stable opaque device identity and device key material stored with Android/iOS platform security facilities.

A session remains the same session after Mobile -> Desktop -> Mobile synchronization. Artifacts/documents remain separately identifiable children/references of that session.

## Pairing UX

### Desktop

Settings -> **Mobile & Devices**

- Connect mobile device
- show short-lived QR
- paired device name/platform
- last seen / last sync
- sync state
- revoke/unpair
- make selected Library items available on mobile

### Mobile

Settings -> **Desktop connection**

- Pair a desktop
- scan QR
- verify/approve Desktop
- show Desktop name and connection status
- Sync now
- Unpair

## QR bootstrap contract

The QR is a short-lived bootstrap object, not a vault object.

It may contain or reference:

- protocol version;
- Desktop installation/device identifier;
- one-time challenge identifier/value;
- expiry;
- local service discovery information for the current network;
- Desktop public identity/key fingerprint or public-key material needed to authenticate the pairing bootstrap.

It must never contain:

- original PII;
- restore mappings;
- document contents;
- private keys;
- permanent bearer credentials;
- cloud account tokens.

## Trust establishment

Target flow:

```text
Desktop creates short-lived pairing challenge
        ↓
Desktop displays QR
        ↓
Mobile scans QR and connects to the dedicated companion service
        ↓
Mobile proves possession of its device key
        ↓
Desktop verifies challenge and explicit user approval
        ↓
Desktop records Mobile as a trusted device
        ↓
Both sides retain only the key/metadata required for future authenticated sync
```

The current browser bearer token is not the target Mobile trust mechanism. Mobile should use device-key possession plus a standard authenticated encrypted channel.

## Cryptographic direction

Do not invent a custom cipher or ad-hoc crypto protocol.

The implementation should use standard platform-supported primitives and separate concerns:

- device identity/signing;
- authenticated key agreement;
- channel/payload confidentiality;
- replay protection;
- key rotation/revocation.

The Desktop already uses P-256/ES256 signing for infrastructure requests. This is a useful compatibility precedent but does not by itself define the Mobile encryption scheme.

A final cryptographic suite must be implementation-reviewed before it is frozen. Android Keystore and iOS Keychain/Secure Enclave capabilities must be part of that review.

## Direct transport — Phase A

Create a **new dedicated Mobile Companion / Sync Service** on Desktop.

Do not change the existing browser API from localhost-only to LAN-accessible.

The Mobile sync service should expose only narrow versioned operations such as:

- pairing bootstrap/approval;
- connection/status;
- list sync metadata;
- fetch selected protected artifact;
- fetch a restore-capable bundle only when authorized;
- upload Mobile-created session/artifact;
- acknowledge synchronization;
- revoke device.

It must not expose raw SQLite/database access or a general filesystem API.

For the first version, Mobile can initiate synchronization. This avoids requiring an inbound listener on the phone and simplifies Android/iOS networking/background restrictions.

## Discovery

The QR may contain the current local endpoint during first pairing. After pairing, local discovery may use a standard LAN discovery mechanism so an IP-address change does not require re-pairing.

Discovery is not authentication. A discovered Desktop must still prove the already-paired identity before any sync data is exchanged.

## Portable sync objects

Sync transfers versioned PrivacyGate objects, not Desktop database rows.

### SessionManifest

Logical metadata such as:

- schema/protocol version;
- `session_id`;
- source device ID;
- created/updated timestamps;
- protection mode/profile;
- placeholder/schema version;
- latest turn/namespace state when relevant;
- artifact references;
- mapping availability;
- revision/sync state;
- tombstone/deletion state.

### ProtectedArtifact

- artifact/document ID;
- parent session ID when applicable;
- protected text or protected file payload;
- safe title/type;
- profile/replacement metadata;
- content hash;
- revision/timestamps.

### RestoreBundle — sensitive

- session ID;
- mapping format/schema version;
- token;
- entity type;
- original value;
- turn/namespace state when needed for compatible continuation.

A **Protected copy only** transfers SessionManifest + ProtectedArtifact but no RestoreBundle.

A **Full offline session** additionally transfers the encrypted RestoreBundle required for local restore.

## Sync behavior

### Mobile -> Desktop

```text
new/updated session manifest
protected artifacts
restore bundle when a full session exists
sync state / tombstones
```

Desktop preserves the original Mobile-created `session_id`. It must not remap an existing session into a newly generated identity.

### Desktop -> Mobile

Only user-selected/offline-policy content is transferred, such as:

- selected items;
- favorites;
- Recent 10 / Recent 25;
- explicit Full session vs Protected only choice.

No arbitrary first-N Library dump.

## Idempotency and conflicts

Every transfer must be safely repeatable.

Required rules:

- same immutable artifact ID + same content hash = already synchronized;
- interrupted transfer can resume/retry;
- repeated ACK must not duplicate data;
- mappings for the same session/token with different original values = hard conflict/fail closed;
- do not use silent last-write-wins for mappings;
- deletion requires an explicit tombstone/version so offline peers do not resurrect removed items;
- changed protected artifacts create an explicit revision/version rather than silently replacing historical identity.

## Mobile Vault modes

### Protected only

Contains protected artifact + safe metadata. It can be viewed/shared/used with AI but cannot restore original values while Desktop is unavailable.

### Full offline session

Contains protected artifact plus the encrypted restore material needed for independent local restore. Access to restore should support device authentication/biometric policy.

## Revocation

Desktop must be able to revoke one Mobile device without invalidating unrelated paired devices.

After revocation, the device must not be able to:

- request new Library/session data;
- upload new Master Vault data;
- refresh or re-establish trusted sync using stale credentials.

Local Mobile copies already retained before revocation are a separate local-data policy; revocation cannot retroactively erase an offline phone unless a later remote-management feature is explicitly designed.

## Privacy boundary

Phase A:

```text
Mobile <-> authenticated encrypted direct channel <-> Desktop Master Vault
```

Phase B, optional relay:

```text
Mobile <-> encrypted envelope <-> Relay <-> encrypted envelope <-> Desktop
```

A future relay changes reachability, not ownership. It must not become the canonical plaintext store for original PII or reversible mappings.

Existing production MCP use of Supabase OAuth / named tunnels is a separate AI access architecture and does not make Supabase a Mobile-sync dependency.

## Required security and compatibility tests

Before pairing/sync is considered production-ready:

1. used/expired/wrong pairing challenge fails;
2. repeated wrong attempts invalidate bootstrap;
3. unpaired client cannot sync;
4. wrong device key fails;
5. replayed authenticated request fails;
6. revoked device fails without affecting other paired devices;
7. Desktop and Mobile identities persist according to their platform rules;
8. Desktop -> Mobile full session restores successfully on Mobile;
9. Mobile -> Desktop full session restores successfully on Desktop;
10. protected-only copy cannot restore offline;
11. interrupted/retried sync is idempotent;
12. mapping conflict fails closed;
13. tombstone does not resurrect deleted content;
14. QR/logs/ordinary metadata contain no long-lived secrets or plaintext mappings;
15. direct transport and future relay transport preserve the same object semantics.

## Implementation impact on Desktop

Desktop will eventually require a focused additive feature set:

- Mobile & Devices UI;
- trusted-device registry;
- pairing challenge manager;
- secure device-key storage/verification;
- dedicated Mobile Companion / Sync Service;
- session/artifact sync adapter over existing application/storage services;
- protocol versioning and migration;
- safe audit events without PII;
- revoke/unpair controls.

These additions must not alter canonical Protect/Restore behavior.

## Status

The data model and existing Desktop trust foundations are now sufficiently understood to design the v1 connection. The exact cryptographic/channel implementation remains intentionally unfrozen until Android+iOS platform capabilities are checked during mobile bootstrap.
