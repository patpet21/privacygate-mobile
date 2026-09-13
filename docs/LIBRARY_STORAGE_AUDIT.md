# Desktop Library and Storage Audit

Audit source: `patpet21/ai-pm-lab-privacy-gate` at `754f412596c7f32f04c3f50714dcd064704a3f13`.

Status: verified read-only audit. This document records current Desktop behavior and the resulting Mobile compatibility requirements. It does not change Desktop code.

## 1. Personal Library is document-centric

`LibraryRepository` uses SQLite `library.db` with schema version 4. A saved protected item receives `document_id = uuid.uuid4().hex`.

The `documents` table stores protected-facing metadata and content:

- `document_id`
- title
- source kind and source name
- profile key
- protected text
- findings count
- entity types
- labels
- replacement mode
- created/updated timestamps
- `has_mapping`
- favorite state
- MCP-share state
- soft-delete timestamp

Reversible mappings live in a separate `mappings` table keyed by `(document_id, token)` and contain token, entity type, and an OS-protected original value.

Conclusion: `document_id` is an artifact/library identity. It must not be substituted for the AI/browser `session_id` audited separately.

## 2. Mapping values are sensitive vault data

The original mapping value is passed through Desktop `LocalProtector` before persistence. Unit tests verify that an original email can be restored through the repository while the plaintext email is absent from raw `library.db` bytes.

Mobile must preserve the logical mapping fields but use mobile-native secure storage. The current Desktop `LocalProtector` implementation is not a portable serialization format.

## 3. Protected Library is a physically separate safe projection

`ProtectedLibraryRepository` maintains a separate `protected_library.db`. Its contract explicitly excludes originals, restore mappings, and restore keys.

The protected projection contains only:

- `document_id`
- safe title
- profile key
- protected text
- findings count
- entity types
- updated timestamp
- favorite state

Source file names and local paths are not copied into this store. When the normal Library title contains a value present in the reversible mapping, Desktop tokenizes that value before publishing the title to the protected store.

Tests verify that original names, emails, and sensitive source filenames do not appear in the protected-store database.

### Mobile consequence

This is the closest existing Desktop analogue for **Protected copy only**:

- protected artifact/content;
- safe non-restoring metadata;
- no original values;
- no reversible mapping;
- no restore key.

A Mobile protected-only object should follow the same privacy boundary, even if its on-device file/database representation differs.

## 4. Full offline session requires more than the Protected Library projection

A restore-capable Mobile object needs the protected artifact plus the reversible mapping and stable session/artifact metadata, encrypted under the Mobile Vault.

Conceptually:

```text
Full offline session
  session identity
  artifact/document identity
  protected content or protected file
  protection/profile metadata
  encrypted reversible mappings
  revision/sync metadata
```

The Protected Library projection alone is intentionally insufficient for restore.

## 5. Browser AI Library is session-centric

`AiLibraryRepository` persists browser AI history inside the same `library.db` but in separate tables:

- `ai_conversations` keyed by `session_id`;
- `ai_mappings` keyed by `(session_id, token)`;
- `ai_messages` keyed by `(session_id, turn, role)`.

Mapping originals and stored protected conversation text are encrypted at rest. The session `turn` counter is durable, allowing a browser session to be rehydrated after the local bridge restarts without reusing an old token namespace.

This confirms that a cross-device Mobile design needs both session-level and artifact-level identity.

## 6. Source provenance metadata is separate from content

`DocumentSourceMetadataRepository` stores connector provenance such as provider, account, source item ID/title/kind and timestamps. It deliberately stores no document contents, OAuth tokens, restore mappings, or MCP state.

For Mobile sync, provenance should therefore be treated as optional metadata, not part of the cryptographic mapping payload.

Provider/account labels and source item titles may themselves reveal user information, so a portable protocol must classify which metadata is safe to sync or display rather than assuming all provenance metadata is non-sensitive.

## 7. Workspace metadata is local context

`DocumentWorkspaceMetadataRepository` stores document-to-workspace context using local workspace key/name and personal flag. It deliberately excludes document text, restore values, credentials, user email, membership rosters and external cloud identity data.

Portable sync should not blindly replicate Desktop database rows. Workspace association needs an explicit portable meaning or should remain device-local until workspace synchronization is designed.

## 8. Trash, deletion and revisions

Desktop Personal Library currently supports:

- soft delete via `deleted_at`;
- restore from trash;
- permanent delete;
- favorites;
- metadata updates;
- MCP-share enable/disable.

For Mobile sync, deletion cannot be represented only as "row missing" because offline peers may resurrect deleted data. The portable sync layer therefore needs explicit deletion/tombstone state and revision/version metadata.

## 9. Backup format is not the Mobile sync format

Desktop creates encrypted `.pgbackup` files containing a SQLite snapshot and manifest. The entire archive is protected through the local OS protection adapter.

This is useful for Desktop backup/restore but should not be reused as the Desktop-Mobile protocol because:

- it is database-centric rather than object-centric;
- encryption is tied to the local operating-system user;
- it contains more Desktop state than a Mobile peer should require;
- cross-device conflict/idempotency semantics are absent.

## 10. Portable object split required by the audit

The Mobile compatibility layer should define at least two portable object families rather than serializing Desktop SQLite rows:

```text
ProtectedArtifact
  artifact_id / document_id
  session_id if associated
  protected payload or file
  safe title / type
  profile + replacement metadata
  hashes / version
  timestamps

RestoreBundle (sensitive)
  session_id
  mapping schema version
  token -> entity type -> original value
  turn / namespace state when applicable
  encrypted for the destination trusted device
```

A protected-only download transfers the first object but not the second. A full offline session transfers both through the trusted encrypted channel.

## 11. Master Vault rule

Desktop remains the long-term Master Vault. Mobile-created sessions may remain authoritative for their own immutable session identity until Desktop acknowledges ingestion. Desktop ingestion must preserve the Mobile-created session identity rather than generating a new incompatible identity.

## 12. Required compatibility tests

Before implementing sync, fixtures must prove:

- Desktop protected-only export contains no original values or mappings;
- full session transfer restores correctly on the destination device;
- `document_id` and `session_id` retain separate semantics;
- repeated sync is idempotent;
- interrupted transfer resumes without regenerating mappings;
- delete/tombstone state does not resurrect removed data;
- conflicting mappings for the same session/token fail closed;
- source/workspace metadata cannot accidentally leak plaintext sensitive values;
- protected-only Mobile storage cannot restore while Desktop is unavailable.

## Decision

The current Desktop storage design strongly supports the planned two-level Mobile Vault model. We should reuse its privacy boundaries and identities, not its SQLite schema or OS-specific encryption implementation.
