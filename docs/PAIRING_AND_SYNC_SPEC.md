# PrivacyGate Desktop <-> Mobile Pairing and Sync (Draft)

## Product goal

Let a PrivacyGate Mobile installation pair explicitly with a trusted PrivacyGate Desktop installation. Desktop remains the Master Vault, while Mobile can operate independently with its encrypted Mobile Vault when Desktop is unavailable.

The initial design should work without persistent cloud storage of original files or restore mappings. A relay/server can be added later without changing the user-facing pairing model.

## Pairing UX

### On Desktop

Add a Settings section such as **Mobile & Devices**:

- `Connect mobile device`
- display a short-lived QR code;
- show paired devices;
- device name/platform;
- last seen / last synced;
- sync status;
- `Revoke / Unpair`;
- optional `Make files available on mobile` controls.

### On Mobile

Settings -> **Desktop connection**:

- `Pair a desktop`;
- scan the QR code displayed by Desktop;
- show paired Desktop name;
- Connected / Offline status;
- last sync time;
- `Sync now`;
- `Unpair`.

## What the QR should represent

The QR should contain only short-lived pairing information, for example:

- Desktop/device identifier;
- one-time pairing token or challenge;
- local connection discovery information when appropriate;
- public key / key agreement material or a reference to it;
- protocol version and expiry.

It must not contain original PII, restore mappings, document contents or long-lived secrets in plaintext.

## Trust establishment

After QR scan:

1. Mobile and Desktop verify the one-time pairing challenge.
2. They establish device-specific cryptographic keys.
3. Each device stores the other as a trusted paired device.
4. Future sync requests are authenticated and encrypted.
5. Revoking a device invalidates its trust/key material.

Exact cryptographic primitives will be selected during implementation; do not invent a custom crypto scheme.

## Initial transport strategy

### Phase A — local-first

When devices can reach each other directly, Desktop exposes a narrowly scoped authenticated companion/sync service. Mobile discovers or connects to it after pairing.

This is the simplest first implementation for development and local testing.

### Phase B — remote relay

Later, allow paired devices to communicate when they are on different networks. The relay should route encrypted traffic/session envelopes rather than become a permanent plaintext document store.

The pairing identity and sync protocol should remain the same so adding the relay does not require redesigning the app.

## Sync objects

Sync should transfer versioned PrivacyGate objects, not arbitrary raw database rows.

Primary objects:

- session metadata;
- protected artifact/file;
- optional encrypted restore mapping for a **Full offline session**;
- profile/version metadata;
- sync state/version information.

Original files should transfer only when explicitly required by a supported workflow and user choice. Protected-only mobile copies should not contain the restore mapping.

## Mobile Vault modes

### Protected only

Mobile stores the protected artifact and metadata. It can use/share the protected file but cannot restore original values while Desktop is unavailable.

### Full offline session

Mobile stores the protected artifact plus the encrypted portable mapping needed for local restore. Sensitive restore should support biometric/device authentication.

## Offline behavior

If Desktop goes offline during work, Mobile should offer clear choices such as:

- Keep securely on this device;
- Keep protected file only;
- Discard local session after export.

When Desktop reconnects, Mobile can automatically or manually synchronize pending sessions according to Settings.

## Library download behavior

From either device, support explicit offline selection rather than copying arbitrary files:

- Make available on mobile;
- Selected files;
- Favorites;
- Recent 10 / Recent 25.

A storage budget (for example 500 MB / 1.5 GB / 3 GB / Custom) controls how much encrypted Mobile Vault storage is available.

## Conflict principle

Do not silently overwrite sessions. Each portable session/object must have an ID, schema version and change/version metadata. Simple first rule: protected artifacts are immutable per version; changed versions create a new revision. Mapping/session conflicts must require deterministic resolution rather than last-write-wins on sensitive data.

## Privacy boundary

Core principle:

`Mobile <-> encrypted transport <-> Desktop Master Vault`

Adding a future relay changes the route, not the trust model:

`Mobile <-> encrypted payload <-> Relay <-> encrypted payload <-> Desktop`

The relay must not become the canonical home of original PII or plaintext reversible mappings.

## Desktop implementation impact

This mobile project does not copy Desktop UI code. The Desktop repository will eventually need a focused addition:

- Mobile & Devices settings UI;
- pairing manager;
- trusted-device/key storage;
- authenticated sync/companion endpoint;
- sync service that reads/writes through the existing Library/session layer;
- audit/logging for pair, sync and revoke events.

These should be implemented as additions around the existing application/infrastructure layers rather than by modifying protection semantics.
