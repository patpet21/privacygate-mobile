# PrivacyGate Desktop / Mobile Parity Checklist

Use this file as the product parity tracker while the compatibility audit progresses.

Status values:
- `MATCH` — Android/iOS behavior is implemented, tested and compatible with Desktop.
- `REIMPLEMENT` — Desktop contract is understood; same product behavior requires a mobile/cross-platform implementation.
- `DESKTOP ONLY` — intentionally not a native Mobile capability.
- `DEFERRED` — planned after the initial Mobile release.
- `AUDIT` — exact Desktop behavior still needs deeper tracing.

| Capability | Status | Notes |
|---|---|---|
| Paste/type text | REIMPLEMENT | Canonical text -> AnalysisDocument -> Protect contract verified. |
| Sensitive-data detection | REIMPLEMENT | Preserve profile/entity/language behavior through golden fixtures; do not require Python/Presidio on Mobile. |
| Review individual detections | REIMPLEMENT | Mobile-first UI, same finding IDs/entity choices. |
| Manual sensitive-item tagging | AUDIT | UI/domain semantics still need dedicated trace. |
| Reversible protection | REIMPLEMENT | Base token and mapping semantics verified. |
| Redact mode | REIMPLEMENT | Desktop output `[REDACTED]`. |
| Generic mode | REIMPLEMENT | Desktop output `[[ENTITY_TYPE]]`. |
| Mask mode | REIMPLEMENT | Desktop keeps final four alphanumeric characters visible. |
| Local restore | REIMPLEMENT | Literal token -> original semantics verified; session/artifact layers remain fail-closed. |
| Placeholder format | REIMPLEMENT | Base, multi-source and session-turn namespace formats verified. |
| Session identity / turns | REIMPLEMENT | 32-hex session ID; durable turn counter; keep distinct from document/artifact ID. |
| General Business profile | REIMPLEMENT | Canonical profile key/entity contract verified. |
| Property Management profile | REIMPLEMENT | Canonical profile key/entity contract verified. |
| Realtor / Brokerage profile | REIMPLEMENT | Canonical profile key/entity contract verified. |
| Projects & Renovations profile | REIMPLEMENT | Canonical profile key/entity contract verified. |
| Construction profile | REIMPLEMENT | Canonical profile key/entity contract verified. |
| Legal profile | REIMPLEMENT | Canonical profile key/entity contract verified. |
| Healthcare General profile | REIMPLEMENT | General privacy only; not specialized clinical/HIPAA detector coverage. |
| English detector behavior | REIMPLEMENT | `en` canonical; compatibility via fixtures. |
| Italian detector behavior | REIMPLEMENT | `it` canonical; compatibility via fixtures. |
| Personal Library | REIMPLEMENT | Desktop Master Vault + portable object adapter. |
| Protected Library boundary | REIMPLEMENT | Protected-only projection must contain no mappings/originals/restore keys. |
| Browser AI Library session persistence | REIMPLEMENT | Map durable session/turn/mapping semantics into portable session model. |
| Search/labels/favorites/library metadata | REIMPLEMENT | Portable safe subset identified; do not sync raw DB rows. |
| Trash/deletion | REIMPLEMENT | Portable sync needs explicit tombstones/revisions. |
| Desktop backup `.pgbackup` | DESKTOP ONLY | Not a cross-device sync format. Mobile needs its own local backup/recovery policy later. |
| PDF selectable-text import/protect/export | REIMPLEMENT | Secure output must not leave recoverable source text under cosmetic overlays. |
| Scanned/image-only PDF OCR | DEFERRED | Current Desktop PDF path does not support it; do not claim V1 parity until dedicated OCR pipeline exists. |
| DOCX import/protect/export | REIMPLEMENT | Deterministic traversal + source-change fail-closed behavior verified. |
| XLSX import/protect/export | REIMPLEMENT | Values/comments/formula privacy behavior requires mobile implementation/tests. |
| PPTX import/protect/export | REIMPLEMENT | Shapes/tables/notes + source-change checks require mobile implementation/tests. |
| TXT import/protect/export | REIMPLEMENT | Good early file target. |
| CSV import/protect/export | REIMPLEMENT | Good early file target; preserve line/content semantics. |
| PNG/JPG/JPEG OCR | REIMPLEMENT | Geometry-based true pixel protection + metadata stripping required. |
| Camera scan | REIMPLEMENT | Mobile-specific capture feeds same image/OCR contract. |
| Gmail source workflow | DEFERRED | Normalize local body/attachments into generic ProtectPackage. |
| Google Drive source workflow | DEFERRED | Normalize local Drive working copy into generic ProtectPackage. |
| Android Share Target | REIMPLEMENT | Mobile source-acquisition feature. |
| iOS Share Extension | REIMPLEMENT | Mobile source-acquisition feature. |
| Copy/share protected output | REIMPLEMENT | Platform UX around same protected artifact contract. |
| MCP protected-file access | DEFERRED | Desktop MCP remains protected-only; Mobile-created artifacts can enter it after sync. |
| Browser extension behavior | DESKTOP ONLY | Native Mobile response interception is not V1. |
| Custom keyboard | DEFERRED | Future optional mobile feature. |
| Mobile Vault | REIMPLEMENT | Encrypted offline storage with user-selected budget. |
| Protected-only offline copy | REIMPLEMENT | Protected artifact + safe metadata, no RestoreBundle. |
| Full offline session | REIMPLEMENT | Includes encrypted RestoreBundle and session state. |
| Biometric/device-auth restore gate | REIMPLEMENT | Android/iOS platform-specific adapter. |
| Desktop pairing by QR | REIMPLEMENT | Dedicated device-key pairing; browser bearer mechanism is not copied as-is. |
| Trusted device identity | REIMPLEMENT | Desktop already has P-256 signing precedent; Mobile gets its own secure identity. |
| Dedicated Desktop Mobile Companion service | REIMPLEMENT | New narrow sync service; do not expose localhost browser/MCP API to LAN. |
| Desktop <-> Mobile sync | REIMPLEMENT | Versioned SessionManifest/ProtectedArtifact/RestoreBundle objects. |
| Sync idempotency/conflicts/tombstones | REIMPLEMENT | Hard conflict on same token/different original; no silent last-write-wins. |
| Remote relay/server | DEFERRED | Add only after direct paired-device protocol is stable. Firebase/Supabase not required for V1. |
| Android secure key/vault adapter | REIMPLEMENT | Platform-backed storage required. |
| iOS Keychain/Secure Enclave adapter | REIMPLEMENT | Platform-backed storage required. |
