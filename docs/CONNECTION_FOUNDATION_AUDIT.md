# Desktop Connection Foundation Audit

Audit source: `patpet21/ai-pm-lab-privacy-gate` at `754f412596c7f32f04c3f50714dcd064704a3f13`.

Status: verified read-only audit of existing browser/local API and MCP identity/provisioning foundations. This is not yet the final Mobile pairing protocol.

## 1. Existing browser pairing is useful but browser-specific

`BrowserPairingRegistry` implements a local pairing model for Chromium extensions:

- one-time 8-digit challenge;
- 5-minute challenge lifetime;
- maximum five failed attempts before invalidation;
- scoped browser bearer credential;
- bearer token stored only as a SHA-256 hash in the persistent pairing registry;
- multiple browser clients can coexist;
- re-pairing the same client replaces only its old credential;
- per-client and global revocation are supported.

Tests verify one-time challenge behavior, expiry, failed-attempt invalidation, origin binding, multiple clients, re-pairing, and revocation.

### Mobile consequence

Keep the product concepts — explicit user pairing, short-lived challenge, stable client identity, independent revoke — but do not copy the browser credential mechanism as the Mobile trust model.

The current browser implementation is explicitly bound to `chrome-extension://` origins and bearer tokens.

## 2. Existing Local API cannot be exposed directly to a phone

The current Local API is intentionally localhost-only. Server creation rejects hosts other than `127.0.0.1` / `localhost`.

Therefore the Mobile app cannot simply connect to the existing browser bridge over Wi-Fi.

A Desktop-Mobile connection needs a new narrowly scoped companion/sync transport around the existing application/storage layers. It may share validation/session concepts with the Local API, but it must not weaken the localhost security boundary of the browser bridge.

## 3. Desktop already has a persistent non-identifying installation identity

`ConnectionIdentityStore` persists public connection metadata separately from secrets. Current identity fields are:

- `installation_id` — opaque 32-hex installation identity;
- `device_id` — UUID hex;
- display name;
- creation timestamp;
- schema version.

Secrets are kept in the OS secret store rather than in `connection_identity.json`. Tests verify stable identity across reloads and that secrets do not leak into the public identity JSON.

### Mobile consequence

This existing separation is a good precedent for Desktop-Mobile trust:

```text
public identity metadata != secret/key material
```

Whether Mobile pairing reuses `installation_id` directly or introduces a dedicated pairing/device ID remains a protocol-design decision, but identity and credentials must remain distinct.

## 4. Desktop already has a P-256 device signing identity

`DeviceIdentityKey` creates and persists a P-256 private key in the OS secret store and exposes the public key as a JWK with:

- `kty = EC`
- `crv = P-256`
- `use = sig`
- `alg = ES256`

It signs a canonical request containing timestamp, nonce, HTTP method, path and SHA-256 body digest. The corresponding tests verify signature validity and stable public identity.

This is stronger and more device-oriented than the browser bearer pairing mechanism.

### Important limitation

The current key is explicitly a signing identity. The audited code does not define the Desktop-Mobile encrypted session/key-agreement protocol.

Do not assume that an ES256 signing key alone solves sync encryption. The Mobile protocol must separately define authenticated key agreement / transport encryption using standard primitives and platform-backed storage.

## 5. MCP production provisioning is a different problem

The Desktop MCP provisioning path already supports remote infrastructure. It sends installation metadata and the device public JWK to a control plane, persists a named-tunnel configuration, and stores runtime credentials in the OS secret store.

Production MCP currently validates an approved Supabase OAuth issuer/JWKS configuration, and production remote access uses a named tunnel model.

This is relevant architectural evidence, but it must not be conflated with Mobile sync:

- MCP remote access is an AI/tool access path;
- Mobile sync is trusted device-to-device vault synchronization;
- Mobile must not require Supabase merely because production MCP currently uses Supabase OAuth;
- a future relay may reuse infrastructure ideas without making the cloud the Master Vault.

## 6. Secret storage boundary

Desktop secret storage currently uses:

- Windows: DPAPI-protected secret files;
- macOS: login Keychain;
- test-only memory store.

For Mobile, analogous secret/key material must use mobile platform-backed facilities. The protocol should never put long-lived device credentials, private keys, or restore mappings in ordinary app preferences or QR payloads.

## 7. Pairing UX implied by the audit

The existing browser implementation and device identity implementation together support the planned product model:

```text
Desktop: Connect mobile device
        ↓
short-lived challenge / QR
        ↓
Mobile identifies itself and proves possession of its device key
        ↓
Desktop explicitly approves and records trusted device
        ↓
future requests authenticated as that device
        ↓
Revoke one device without affecting others
```

The QR must remain bootstrap-only. It must not contain original PII, restore mappings, source files, or long-lived plaintext credentials.

## 8. Proposed protocol layers to freeze next

The final Mobile protocol should be split into layers so transport can evolve independently:

```text
Identity
  stable Desktop installation/device identity
  stable Mobile device identity

Pairing bootstrap
  short-lived challenge
  QR/discovery information
  explicit approval

Authentication
  proof of device-key possession
  replay protection using timestamps/nonces
  revocation state

Encrypted session
  authenticated key agreement / channel encryption

Sync protocol
  versioned sessions
  protected artifacts
  optional restore bundles
  acknowledgements / revisions / tombstones

Transport
  Phase A direct local connection
  Phase B optional relay
```

## 9. Direct local connection must be a new Desktop surface

Do not alter the existing localhost-only browser API to bind to the LAN.

The safer architecture is a dedicated Mobile Companion / Sync Service with its own:

- narrow endpoint set;
- paired-device authorization;
- protocol versioning;
- request size/rate limits;
- replay protection;
- encrypted payload requirements;
- no generic Library/database access;
- explicit user enable/disable and revoke controls.

This service should call existing PrivacyGate application/storage services rather than opening `library.db` to the network.

## 10. Remote relay remains optional

Nothing in this audit requires Firebase or another permanent Mobile backend.

Phase A can be direct trusted Desktop-Mobile communication when devices can reach each other.

A later Phase B relay can solve different-network reachability, but it should carry opaque encrypted sync envelopes and presence/routing metadata rather than plaintext original documents or mappings.

## 11. Security properties to test

The final pairing/sync implementation must test at minimum:

- expired/used QR challenge fails;
- repeated wrong pairing attempts invalidate the challenge;
- wrong device key fails;
- replayed signed request fails;
- revoked device fails immediately;
- one-device revoke does not break other paired devices;
- Desktop identity persists across app restart;
- Mobile identity persists across app restart/reinstall rules as explicitly designed;
- sync cannot be performed by an unpaired LAN client;
- mapping conflicts fail closed;
- no long-lived secret appears in QR, logs or ordinary metadata files;
- direct and future relay transports produce identical sync object semantics.

## Decision

The Desktop already contains useful building blocks for Mobile connection design, especially short-lived pairing concepts, revocation, stable installation identity, OS secret storage and P-256 request signing.

However, there is no existing Desktop-Mobile encrypted sync protocol to reuse as-is. The correct next step is to define a dedicated v1 pairing/sync protocol around these proven concepts while preserving the current localhost-only browser boundary.
