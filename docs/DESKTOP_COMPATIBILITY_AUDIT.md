# PrivacyGate Desktop -> Mobile Compatibility Audit

Status: deep audit in progress  
Desktop source of truth: `patpet21/ai-pm-lab-privacy-gate`  
Next-release source under audit: `754f412596c7f32f04c3f50714dcd064704a3f13`

## Goal

Build PrivacyGate Mobile as the same PrivacyGate product on a different platform, not as a separate implementation with different behavior.

The Desktop repository remains the authoritative implementation until each shared contract has been documented and covered by compatibility tests. Mobile may use different Android-native libraries internally, but observable PrivacyGate behavior and portable data formats must remain compatible.

## Audit method

For every Desktop capability, record:

1. what the user can do today;
2. where the behavior lives in the Desktop codebase;
3. what is canonical and must match on Mobile;
4. implementation decision: reuse data/config, port logic, reimplement natively, Desktop-only, or defer;
5. compatibility test proving Desktop and Mobile agree;
6. Mobile phase in which the capability is delivered.

## Source map

The current Desktop source is separated into these relevant layers:

- `domain/` — models, profiles, policies and product rules;
- `application/` — protection orchestration and source workflows;
- `infrastructure/pii/` — Presidio engine, languages and recognizers;
- `infrastructure/documents/` — document pipelines and format-specific services;
- `infrastructure/storage/` — Personal Library, AI Library and encrypted mappings;
- `infrastructure/local_api/` — localhost/browser companion integration;
- `infrastructure/mcp/` — protected-only MCP surface;
- `ui/` — Desktop UI; not copied to Android.

## Compatibility matrix

| Capability | Desktop source area | Canonical contract for Mobile | Mobile strategy | Target |
|---|---|---|---|---|
| Text detection | `infrastructure/pii`, profiles | entity names, spans, confidence/selection behavior | reimplement Android-capable engine, verify against fixtures | MVP |
| Protection profiles | `domain/profiles.py` | profile IDs, entity sets, defaults and labels | share/export canonical config | MVP |
| Placeholder generation | `application/privacy_service.py`, session namespacing | exact syntax, counters and namespace rules | reproduce exactly | MVP |
| Reversible mapping | `domain/models.py`, storage | token/entity/original semantic mapping | portable encrypted session format | MVP |
| Review findings | domain + UI | selectable entities and manual choices | native mobile UI, same decision model | MVP |
| Restore | `PrivacyGateService.restore_text`, restore services | token resolution and fail-closed document/session checks | reproduce semantics | MVP |
| Personal Library | `library_repository.py` | document identity and protected artifact metadata | Android vault + portable layer | Offline Vault |
| Browser AI Library | `ai_library_repository.py` | AI session identity, turns, encrypted mappings/messages | map into portable session model | Pairing/Sync |
| PDF workflow | `infrastructure/documents` | extracted/protected content and output expectations | Android-native implementation where required | File phase |
| DOCX/XLSX/PPTX | `infrastructure/documents` | same-format protection expectations | evaluate per format | Later file phase |
| Image / OCR | documents + OCR areas | scan result feeding same detection contract | Android camera/OCR implementation | File phase |
| Gmail source | application integration | normalized content sent to Protect pipeline | mobile integration track | Integrations |
| Drive source | application integration | normalized content sent to Protect pipeline | mobile integration track | Integrations |
| MCP | `infrastructure/mcp` | protected-only exposure; originals/mappings never exposed | preserve boundary | Integrations |
| Local/browser API | `infrastructure/local_api` | authenticated local operations, sessions and pairing | reuse concepts, redesign for Mobile device trust | Pairing |
| Desktop UI | `ui/` | user capability, not layout | redesign mobile-first | N/A |

# Audit Pass 1 — Protect / Restore / Session Identity

Status: **verified at `754f412...`**.

## A. Base reversible placeholder contract

`PrivacyGateService.protect()` is the canonical base protection function.

For reversible protection, the base placeholder format is:

`[[PG_<ENTITY_TYPE>_<NNN>]]`

Examples:

- `[[PG_PERSON_001]]`
- `[[PG_EMAIL_ADDRESS_001]]`

Counters are maintained separately per entity type and begin at `001` within one protection operation.

Repeated values use a key of `(entity_type, case-folded original value)`. The same value with the same entity type therefore reuses the same token rather than consuming another counter.

The current base mapping model is exactly:

- `token`
- `entity_type`
- `original_text`

The `ProtectionResult` contains protected pages, applied findings, mappings, protected spans and replacement mode. It is a runtime protection result, not by itself a portable cross-device session object.

## B. Protection modes

Current core replacement modes are:

- `reversible` -> PrivacyGate token and mapping;
- `redact` -> `[REDACTED]`;
- `generic` -> `[[ENTITY_TYPE]]`;
- `mask` -> masked original value with the final four alphanumeric characters left visible.

Only reversible protection creates restore mappings.

## C. Multi-source application namespacing

`ProtectSessionService` supports N independent sources in one Protect package.

When there is only one source, historical base placeholder shape is preserved.

When there are multiple sources, each result is namespaced with:

`S<source-index>_<source-key>`

The namespace is inserted after `PG_`.

Example shape:

`[[PG_S1_GMAIL_BODY_PERSON_001]]`

This prevents collisions between independent sources in the same package.

## D. Local/browser AI session identity

The localhost/browser bridge has a distinct session system.

`LocalProtectionSessionStore.create()` generates a 32-hex-character session ID using `secrets.token_hex(16)`.

The hot session contains:

- `session_id`;
- creation and last-access timestamps;
- `turn` counter;
- mappings keyed by token.

Default hot-session behavior:

- TTL: 8 hours;
- maximum hot sessions: 100;
- store is cleared when the Local API server closes unless browser persistence later rehydrates the session from the encrypted AI Library.

A token collision for the same token with a different original value raises an error instead of silently overwriting the mapping.

## E. Browser turn namespace

For browser/local AI protection, each reversible protection turn calls `next_namespace(session_id)`.

The exact namespace is:

`B<first-8-hex-of-session-id-uppercase>_T<4-digit-turn>`

Example namespace:

`B57F4839_T0001`

When applied to a normal token, the effective browser token shape becomes:

`[[PG_B57F4839_T0001_PERSON_001]]`

This is a different concern from `ProtectSessionService` multi-source `S1_...` namespacing. Both use the same generic `namespace_protection_result()` mechanism, but they identify different scopes.

## F. Browser Protect and Restore

For `/v1/browser/protect`:

1. analyze text locally;
2. select findings;
3. run canonical `PrivacyGateService.protect()`;
4. if reversible mappings exist, create or touch the browser session;
5. increment turn namespace;
6. namespace the result;
7. add mappings to the session;
8. return protected text and the opaque `session_id`.

For `/v1/browser/restore`:

1. a valid session ID is required;
2. mappings are loaded from the hot session;
3. `PrivacyGateService.restore_text()` performs literal token -> original replacement.

The Local API contract deliberately does **not** return raw restore mappings, source files or Library records to clients.

## G. Durable browser AI persistence

Browser AI persistence is separate from the hot session store.

`AiLibraryRepository` stores AI sessions in dedicated tables inside the existing `library.db`:

- `ai_conversations` keyed by `session_id`;
- `ai_mappings` keyed by `(session_id, token)`;
- `ai_messages` keyed by `(session_id, turn, role)`.

It stores provider, opaque session ID, turn counters and timestamps as metadata. Mapping original values and stored protected conversation text are encrypted at rest with the local OS protection adapter.

When a browser session is missing from RAM, the browser persistence adapter can load the same `session_id`, restore its mappings and turn counter, and rehydrate the hot session. Therefore the browser `session_id` is already a durable logical conversation identity, not merely an in-memory request ID.

## H. Automatic browser restore from token namespace

`browser_restore_auto.py` can inspect protected AI text for tokens shaped like:

`[[PG_B<8-hex-prefix>_T....]]`

It uses the eight-character session prefix only as a **lookup hint**.

If exactly one stored AI conversation matches the prefix, its mappings may be loaded. If the prefix is ambiguous, the code intentionally does not guess.

This behavior must remain fail-closed in a Mobile-compatible design.

## I. Browser file protection uses the same AI session identity

The v2 browser file pipeline supports protected file workflows while reusing the same AI `session_id` and turn namespace system used for protected text.

A file analyze operation has a separate temporary `analysis_id`. That `analysis_id` is not a durable protection/session identity.

On file protection:

- an existing AI session may be supplied;
- otherwise a new AI session is created if mappings are produced;
- a new turn namespace is allocated;
- mappings are added to the same session;
- mappings are persisted to the AI Library under the same `session_id`;
- the response returns the protected file plus `session_id`.

This means text turns and file turns can belong to one browser AI privacy session.

## J. Personal Library document identity is separate

The Personal Library uses a different identity model.

`LibraryRepository.save()` generates:

`document_id = uuid.uuid4().hex`

and stores Personal Library documents in `documents` plus reversible mappings in `mappings`, keyed by `(document_id, token)`.

This `document_id` represents one saved protected Library artifact. It is not the current browser AI session ID.

The AI Library uses `session_id`; the Personal Library uses `document_id`. They are both 32-hex values today, but they have different semantics and must not be collapsed merely because their string shape is similar.

## K. Decision for Mobile architecture

**Do not make `document_id` and portable `session_id` the same concept.**

The portable model should keep a stable session identity that may own or reference one or more artifacts.

Target conceptual relationship:

```text
portable_session_id
    |
    +-- protected text turn 1
    +-- protected text turn 2
    +-- protected file artifact A
    +-- protected file artifact B
    +-- mapping set / revisions
```

A Personal Library artifact keeps its own artifact/document identity.

This matches current Desktop behavior better than forcing one session to equal one document.

## L. Encryption boundary

Desktop local storage encryption is platform-specific:

- Windows: current-user DPAPI;
- macOS: key stored in macOS Keychain and AES-GCM payload encryption;
- other platforms currently fall back to raw bytes and are not acceptable as the Mobile vault design.

Therefore Mobile must preserve the logical mapping/session contract while using platform-appropriate secure storage rather than copying `LocalProtector` literally.

The portable sync envelope must be independent of DPAPI/Keychain and encrypted for the paired-device transport separately.

## M. Point 1 conclusion

The first deep audit pass resolves the earlier identity question:

- the existing Desktop already has a real durable **AI privacy session** identity;
- it is `session_id`, not `document_id`;
- browser tokens partially encode that session identity plus turn number;
- the Personal Library document ID is a different artifact identity;
- multi-source package namespacing and browser-turn namespacing are separate layers;
- Mobile should preserve these semantics rather than flattening them into one ID.

Point 1 is therefore considered **closed for architecture purposes**. Implementation fixtures still need to be added later.

# Remaining canonical contracts to freeze

## 2. Protection profiles and entity rules

Inventory profile IDs, entity sets, labels, defaults and recognizers. Separate canonical PrivacyGate rules/configuration from the Python/Presidio runtime.

## 3. Portable session/mapping envelope

Define a versioned cross-device serialization around the verified semantics above. It must not expose plaintext mappings in normal exports and must not depend on Windows DPAPI.

## 4. Library/session metadata

Define the portable fields needed to move a session safely between devices: stable session ID, artifact IDs, source type, timestamps, profile, protection mode, protected artifact metadata, mapping availability, revision/sync state and format/schema version.

## 5. Restore compatibility fixtures

Create Desktop -> Mobile and Mobile -> Desktop round-trip fixtures including repeated values, multi-source namespacing, browser turn namespacing, files, missing mappings, ambiguous prefix lookup and conflicting mappings.

## 6. Document formats and integrations

Audit PDF/Office/OCR behavior, Gmail/Drive normalization, MCP exposure and pairing/transport separately after the core contract is frozen.

## Reuse vs rewrite rule

Do not copy all Python files into the Android app.

Reuse or share formats, profiles, configuration, fixtures and protocols where possible. Reimplement platform-specific business execution and UI where Android requires a different runtime. Keep Desktop-only behavior explicitly documented rather than silently dropping it.

## Audit deliverables

The overall audit is complete when we have:

1. a feature-by-feature inventory of Desktop;
2. a frozen v1 shared PrivacyGate session/mapping schema;
3. a profile/entity compatibility specification;
4. a Desktop <-> Mobile pairing and sync protocol;
5. compatibility fixtures/tests;
6. a parity checklist showing `MATCH`, `REIMPLEMENT`, `DESKTOP ONLY`, `DEFERRED`, or `AUDIT` for every capability.
