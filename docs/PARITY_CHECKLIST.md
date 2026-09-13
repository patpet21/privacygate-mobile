# PrivacyGate Desktop / Mobile Parity Checklist

Use this file as the product parity tracker while the compatibility audit progresses.

Status values:
- `MATCH` — Mobile behavior is tested and compatible with Desktop.
- `REIMPLEMENT` — same product behavior, different platform implementation required.
- `DESKTOP ONLY` — intentionally not a Mobile capability.
- `DEFERRED` — planned after the initial Mobile release.
- `AUDIT` — exact Desktop behavior still being traced.

| Capability | Status | Notes |
|---|---|---|
| Paste/type text | AUDIT | Mobile MVP requirement. |
| Sensitive-data detection | REIMPLEMENT | Preserve entity/profile behavior; Android-capable engine required. |
| Review individual detections | REIMPLEMENT | Mobile-first UI, same protection choices. |
| Manual sensitive-item tagging | AUDIT | Preserve semantics if part of current canonical flow. |
| Reversible protection | AUDIT | Shared portable mapping contract required. |
| Generic/permanent protection | AUDIT | Confirm current modes and exact semantics. |
| Local restore | AUDIT | Cross-platform round-trip tests required. |
| Placeholder format | AUDIT | Must be frozen before deep Android implementation. |
| Property Management profile | REIMPLEMENT | Same canonical profile/entity definitions. |
| Realtor / Brokerage profile | REIMPLEMENT | Same canonical profile/entity definitions. |
| Projects & Renovations profile | REIMPLEMENT | Same canonical profile/entity definitions. |
| Protected Library | REIMPLEMENT | Mobile Vault + Desktop Master Vault. |
| Search/labels/library metadata | AUDIT | Determine portable metadata subset. |
| PDF import/protect/export | REIMPLEMENT | Android-native implementation as needed. |
| DOCX import/protect/export | AUDIT | Evaluate parity and Android libraries. |
| XLSX import/protect/export | AUDIT | Evaluate parity and Android libraries. |
| PPTX import/protect/export | AUDIT | Evaluate parity and Android libraries. |
| Images / camera scan | REIMPLEMENT | Mobile-specific capture is an advantage. |
| OCR | REIMPLEMENT | Android/mobile OCR path, same downstream detection contract. |
| Gmail source workflow | DEFERRED | Separate integration track; should feed same Protect pipeline. |
| Google Drive source workflow | DEFERRED | Separate integration track; should feed same Protect pipeline. |
| Android Share Target | REIMPLEMENT | Mobile-specific core feature. |
| Copy/share protected output | REIMPLEMENT | Mobile-specific UX. |
| MCP protected-file access | DEFERRED | Preserve protected-only exposure through Desktop/MCP. |
| Browser extension behavior | DESKTOP ONLY | Native Mobile response interception is not V1. |
| Custom keyboard | DEFERRED | Future mobile feature. |
| Mobile Vault | REIMPLEMENT | Encrypted offline storage with user-selected budget. |
| Protected-only offline copy | REIMPLEMENT | No local mapping. |
| Full offline session | REIMPLEMENT | Includes encrypted portable mapping. |
| Biometric restore gate | REIMPLEMENT | Mobile-specific security UX. |
| Desktop pairing by QR | REIMPLEMENT | New cross-device capability. |
| Desktop <-> Mobile sync | REIMPLEMENT | New cross-device capability. |
| Remote relay/server | DEFERRED | Add after local-first pairing protocol is stable. |
