# PrivacyGate Desktop -> Mobile Compatibility Audit

Status: initial audit in progress  
Desktop source of truth: `patpet21/ai-pm-lab-privacy-gate`  
Stable baseline under review: `dc6a83b2a57af3ce6b9053ceffababe44f3cf35d`

## Goal

Build PrivacyGate Mobile as the same PrivacyGate product on a different platform, not as a separate implementation with different behavior.

The desktop repository remains the authoritative implementation until each shared contract has been documented and covered by compatibility tests. Mobile may use different Android-native libraries internally, but the observable PrivacyGate behavior and portable data format must remain compatible.

## Audit method

For every desktop capability, record:

1. **What the user can do today** on Desktop.
2. **Where the behavior lives** in the Desktop codebase.
3. **What is canonical** and therefore must match on Mobile.
4. **Implementation decision**: reuse data/config, port logic, reimplement natively, Desktop-only, or defer.
5. **Compatibility test** proving Desktop and Mobile agree.
6. **Mobile phase** in which the capability is delivered.

## Initial source map

The stable Desktop repository is already separated into useful layers:

- `domain/` — models, profiles, policies and product rules.
- `application/` — orchestration and source workflows.
- `infrastructure/pii/` — Presidio engine, languages and recognizers.
- `infrastructure/documents/` — document pipelines and format-specific services.
- `infrastructure/storage/` — protected library, metadata and repositories.
- `infrastructure/local_api/` — local/browser companion integration surface.
- `infrastructure/mcp/` — MCP transport/integration.
- `ui/` — PySide6 Desktop interface; this is not copied to Android.

Known examples already identified in the baseline include:

- `domain/profiles.py`
- `domain/models.py`
- `infrastructure/pii/presidio_engine.py`
- `infrastructure/pii/recognizers/`
- `infrastructure/documents/document_pipeline.py`
- `infrastructure/documents/pdf_service.py`
- `infrastructure/documents/office_service.py`
- `infrastructure/storage/library_repository.py`
- `infrastructure/storage/protected_library.py`
- `infrastructure/storage/document_source_metadata.py`
- `application/gmail_protect_sources.py`
- `application/google_drive_protect_sources.py`
- `application/local_protect_sources.py`
- `infrastructure/local_api/`
- `infrastructure/mcp/`

## Compatibility matrix

| Capability | Desktop source area | Canonical contract for Mobile | Mobile strategy | Target |
|---|---|---|---|---|
| Text detection | `infrastructure/pii`, profiles | entity names, spans, confidence/selection behavior | reimplement Android-capable engine, verify against fixtures | MVP |
| Protection profiles | `domain/profiles.py` | profile IDs, entity sets, defaults and labels | share/export canonical config | MVP |
| Placeholder generation | protection/domain logic | exact placeholder/session naming and ordering | reproduce exactly | MVP |
| Reversible mapping | protection/storage logic | mapping schema, entity association, restore semantics | portable encrypted session format | MVP |
| Review findings | domain + desktop UI | selectable entities and manual choices | native mobile UI, same decision model | MVP |
| Restore | protection/storage logic | placeholder resolution and round-trip rules | reproduce exactly | MVP |
| Local Library | `infrastructure/storage` | session metadata, protected file identity, labels/status | Android database/vault with shared portable schema | Offline Vault |
| PDF workflow | `infrastructure/documents` | extracted/protected content and output expectations | Android-native implementation where required | File phase |
| DOCX/XLSX/PPTX | `infrastructure/documents` | same-format protection expectations | evaluate per format; do not assume Python libraries port directly | Later file phase |
| Image / OCR | documents + OCR areas | scan result feeding same detection contract | Android camera/OCR implementation | File phase |
| Gmail source | `application/gmail_protect_sources.py` | normalized content sent to Protect pipeline | mobile integration track | Integrations |
| Drive source | `application/google_drive_protect_sources.py` | normalized content sent to Protect pipeline | mobile integration track | Integrations |
| MCP | `infrastructure/mcp` | protected-only exposure; originals/mappings never exposed | preserve Desktop MCP, add mobile-created sessions through sync | Integrations |
| Local/browser API | `infrastructure/local_api` | authenticated companion operations | evaluate as basis for pairing/sync service | Pairing |
| Desktop UI | `ui/` | user capability, not layout | redesign mobile-first | N/A |

## Canonical contracts to freeze before deep mobile implementation

### 1. Session identity

Define one portable PrivacyGate session identity that both platforms understand. The same session must remain the same session after Desktop -> Mobile -> Desktop synchronization.

### 2. Placeholder format

Freeze placeholder syntax, entity type naming, counters, token/session identifiers and deterministic ordering. Mobile must never create a second incompatible placeholder dialect.

### 3. Mapping format

Define a versioned portable mapping envelope independent of Windows DPAPI. Desktop may continue using DPAPI for local-at-rest protection, while device-to-device transfer uses an encrypted portable payload protected by pairing keys.

### 4. Library/session metadata

Freeze the fields needed to move a session safely between devices: session ID, file identity, source type, timestamps, profile, protection mode, protected artifact metadata, mapping availability, sync state, and format/schema version.

### 5. Restore behavior

Create round-trip fixtures proving that content protected by either platform can be restored by the other when the full session mapping is available.

### 6. Protection profiles and recognizers

Separate the **PrivacyGate rules/configuration** from the specific Python/Presidio implementation. Mobile should consume the same canonical entity/profile definitions even if the underlying detector is different.

## Required compatibility fixtures

Create a versioned fixture pack containing representative examples for:

- people, email, phone, addresses;
- IDs and financial entities;
- real-estate/property entities;
- organization/business identifiers;
- multiple occurrences and overlapping detections;
- manual include/exclude choices;
- reversible protect -> restore round trips;
- protected-only sessions vs full sessions;
- text plus representative PDF/Office examples.

For every fixture we should record Desktop expected output. Android is accepted only when the compatibility test passes or a documented platform exception is approved.

## Reuse vs rewrite rule

Do **not** copy all Python files into the Android app.

- Reuse/share **formats, profiles, configuration, test fixtures and protocols** wherever possible.
- Port or reimplement **business behavior** where Android requires another runtime/library.
- Replace **desktop UI and OS-specific code** with Android-native equivalents.
- Keep Desktop-only capabilities explicitly documented rather than silently dropping them.

## Audit deliverables

The audit is complete when we have:

1. A feature-by-feature inventory of Desktop.
2. A frozen v1 shared PrivacyGate session/mapping schema.
3. A profile/entity compatibility specification.
4. A Desktop <-> Mobile pairing and sync protocol.
5. Compatibility fixtures/tests.
6. A mobile parity checklist showing: `MATCH`, `REIMPLEMENT`, `DESKTOP ONLY`, or `DEFERRED` for every capability.

## Immediate next audit passes

1. Trace Protect/Restore end-to-end from Desktop UI through application/domain/storage.
2. Extract exact placeholder and reversible mapping behavior.
3. Inspect library database/session metadata and define the portable subset.
4. Inventory recognizers/profiles and decide what can become shared configuration.
5. Inspect local API/MCP boundaries for reusable authenticated device communication patterns.
6. Map document-format support and identify Android-native replacements.
7. Only after these are known, finalize the Android core implementation choices.
