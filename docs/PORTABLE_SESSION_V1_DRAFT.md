# PrivacyGate Portable Session v1 — Draft Compatibility Contract

Status: draft for implementation review.  
Desktop reference: `patpet21/ai-pm-lab-privacy-gate@754f412596c7f32f04c3f50714dcd064704a3f13`.

This document defines the logical cross-platform contract. It does **not** require Desktop, Android and iOS to use the same database or at-rest encryption implementation.

## 1. Compatibility principles

1. Desktop, Android and iOS share one PrivacyGate placeholder/mapping/session dialect.
2. `session_id` and `artifact_id`/`document_id` are distinct identities.
3. Protected-only content must remain usable without possessing restore mappings.
4. Restore mappings are sensitive vault material and must never be included in a protected-only export.
5. Sync transfers versioned objects, not raw SQLite rows.
6. Mapping conflicts fail closed.
7. Platform-specific at-rest encryption is allowed; portable transport encryption is a separate layer.

## 2. Session identity

A portable session ID should preserve the existing Desktop browser/local-session shape:

- cryptographically random 16 bytes;
- serialized as 32 lowercase hexadecimal characters;
- globally unique for practical product purposes;
- immutable for the lifetime of that PrivacyGate session.

A Mobile-created session keeps the same `session_id` when ingested by Desktop.

## 3. Artifact identity

Each protected document/file/text artifact has its own identity separate from `session_id`.

For Desktop Personal Library compatibility, artifact IDs may use UUIDv4 hex / 32 lowercase hex representation. Identity meaning, not string appearance, distinguishes artifact ID from session ID.

One session may reference zero, one or many artifacts.

## 4. Placeholder contract

### 4.1 Base reversible placeholder

Canonical Desktop base form:

`[[PG_<ENTITY_TYPE>_<NNN>]]`

Example:

`[[PG_EMAIL_ADDRESS_001]]`

Rules:

- counter is three digits beginning at `001`;
- counters are per entity type within the protection operation;
- same case-insensitive original value + same entity type reuses the same token;
- entity identifiers are the canonical PrivacyGate entity IDs.

### 4.2 Session-turn namespace

Current Desktop browser sessions namespace reversible tokens as:

`[[PG_B<SESSION_PREFIX>_T<TURN>_<ENTITY_TYPE>_<NNN>]]`

where:

- `SESSION_PREFIX` = first 8 hex characters of `session_id`, uppercased;
- `TURN` = four-digit positive turn counter beginning at `0001`.

Example:

`[[PG_B57F4839E_T0001_PERSON_001]]`

For v1 compatibility, Mobile should not create a new competing session-turn token dialect. A session-scoped Mobile AI/protection turn should preserve this established token shape unless a later schema version explicitly replaces it across all platforms.

The historical `B` prefix is retained for compatibility even when the session originates on Mobile.

### 4.3 Multi-source namespace

Existing multi-source package protection uses:

`S<index>_<source-key>`

inserted after `PG_`, for example:

`[[PG_S1_GMAIL_BODY_PERSON_001]]`

This namespace identifies independent sources within one protection package and is semantically different from the session-turn namespace.

## 5. Mapping contract

The canonical logical mapping is:

```text
ReplacementMapping
  token
  entity_type
  original_text
```

No platform may silently change a token's original value after it has been committed to a session.

If the same `session_id + token` resolves to different `original_text` values on two peers, synchronization must fail closed and require explicit recovery rather than heuristically choosing a winner.

## 6. SessionManifest v1

Logical fields:

```text
schema_version: "pg-session-v1"
session_id: 32-hex
source_device_id: opaque device id
created_at: UTC timestamp
updated_at: UTC timestamp
turn: integer >= 0
profile_key: canonical PrivacyGate profile key
scope_key: canonical PrivacyGate scope key when applicable
language: canonical language code
replacement_mode: reversible | redact | generic | mask
placeholder_schema: "pg-placeholder-v1"
mapping_schema: "pg-mapping-v1"
mapping_state: none | protected-only | available-encrypted
artifact_refs: []
revision: monotonic/object revision metadata
sync_state: local | pending | synced | conflict | deleted
```

Not every historical Desktop object currently stores every field. The portable layer may derive/attach required metadata without altering existing Desktop protection semantics.

## 7. ProtectedArtifact v1

Logical fields:

```text
schema_version: "pg-artifact-v1"
artifact_id
session_id: optional when artifact is standalone, required when session-owned
source_kind
content_type / format
safe_title
profile_key
replacement_mode
protected_payload or protected-file reference
protected_text companion when applicable
entity_types
findings_count
content_hash
created_at
updated_at
revision
tombstone/deleted state
```

Sensitive original source filenames/paths must not automatically cross the safe boundary. User-facing metadata must be reviewed/sanitized before being treated as protected-only metadata.

## 8. RestoreBundle v1

Sensitive logical payload:

```text
schema_version: "pg-restore-v1"
session_id
turn
mappings[]:
  token
  entity_type
  original_text
```

The clear logical structure may exist transiently in trusted process memory, but a retained/transmitted RestoreBundle must be encrypted according to the local vault / paired-device channel.

It must never be placed inside the protected-only artifact store, logs, notifications, analytics, clipboard history, ordinary preferences or unencrypted exports.

## 9. Offline modes

### Protected copy only

Contains:

- SessionManifest with `mapping_state = protected-only` or equivalent;
- ProtectedArtifact(s);
- no RestoreBundle.

Result: usable/shareable as protected content, but local restore is unavailable.

### Full offline session

Contains:

- SessionManifest;
- ProtectedArtifact(s);
- encrypted RestoreBundle;
- local vault keying/biometric policy metadata that does not reveal sensitive values.

Result: local restore works while Desktop is offline.

## 10. Restore semantics

Text restore follows the Desktop semantic contract: literal token -> original replacement using the session's mappings.

Mappings are applied longest-token-first to avoid accidental shorter-token interference.

Session/artifact restore layers may add integrity/fingerprint checks and must fail closed on missing, ambiguous or conflicting mapping identity.

Automatic lookup by the 8-character token session prefix is a convenience hint only. It must never select among multiple matching sessions by guesswork.

## 11. Turn continuation

When a session is synchronized, the current turn counter is part of session state.

A destination that continues the session must allocate a strictly later turn and must not regenerate an already-used session-turn namespace.

Example:

```text
Desktop/Mobile stored turn = 12
next protection turn = 13
namespace = B<SESSION8>_T0013
```

## 12. Detection/profile compatibility

Serialized profile keys, scope keys, entity IDs and language codes must use the canonical Desktop-compatible identifiers.

The detector implementation may differ by platform, but accepted Mobile behavior is defined by golden compatibility fixtures.

Current canonical language codes are `en` and `it`.

## 13. Revision and synchronization rules

- object transfers are idempotent;
- immutable protected artifact + same ID/hash is treated as already present;
- modified artifacts create an explicit revision;
- mappings are not last-write-wins;
- deletion is represented with a versioned tombstone;
- successful ingestion is acknowledged before Mobile considers an unsynced full session safely archived to Desktop;
- cleanup must not silently destroy an unsynced full session.

## 14. Encryption boundaries

### At rest

Platform-specific:

- Desktop Windows: current-user DPAPI today;
- Desktop macOS: Keychain-backed key + AES-GCM today;
- Android: platform-backed secure key/vault implementation;
- iOS: Keychain/Secure Enclave appropriate implementation.

### In transit / portable

Must be independent from DPAPI/Keychain. Pairing/sync will use a standard authenticated encrypted protocol between trusted devices.

Do not serialize a DPAPI/Keychain ciphertext and call it a portable RestoreBundle.

## 15. Protected-only boundary inherited from Desktop

Desktop already maintains a physically separate Protected Library containing protected text and safe metadata but no originals, mappings or restore keys.

Mobile protected-only storage should preserve the same security property even if implemented in a different database/file layout.

## 16. Version negotiation

Pairing/sync must exchange protocol and object-schema versions before moving sensitive data.

A peer must reject or explicitly downgrade unsupported major versions rather than attempting best-effort interpretation of mapping/session data.

Initial version labels in this draft are logical names and may be replaced by compact numeric versions during implementation, provided the versioning semantics remain explicit.

## 17. Required golden compatibility tests

Minimum acceptance set:

1. same base placeholder generation for repeated and unique values;
2. Desktop-created session turn restored on Mobile;
3. Mobile-created session turn restored on Desktop;
4. turn counter continues after sync/restart;
5. multi-source namespace round trip;
6. protected-only copy cannot restore;
7. full offline session restores;
8. missing mapping fails safely;
9. ambiguous 8-char session prefix is not guessed;
10. same token/different original produces conflict;
11. interrupted sync retried without duplicate identities;
12. tombstone prevents offline resurrection;
13. English and Italian profile/entity fixtures remain compatible.

## Draft decision

This draft is sufficiently concrete to bootstrap the shared Android/iOS application and Mobile Vault object layer without copying Desktop SQLite or OS-specific crypto. It remains a draft until the first cross-platform fixture suite and pairing implementation validate the serialization choices.
