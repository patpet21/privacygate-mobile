# Mobile detector port status

Source of truth: Desktop commit `754f412596c7f32f04c3f50714dcd064704a3f13`.

## Implemented in Mobile

`DesktopRuleDetector` is now the detector used by the Flutter app instead of the former two-pattern bootstrap detector.

The current mobile-local layer ports deterministic Desktop behavior and contracts:

- `DetectionRequest` uses the per-document `scanLanguage`, canonical profile/scope entities and confidence threshold.
- Protected PrivacyGate placeholders / `[REDACTED]` spans are excluded from rescanning.
- Candidate arbitration is precision-first: higher score, then longer span, then earlier start, followed by deterministic non-overlap selection.
- English deterministic coverage currently includes email, phone, IPv4, Luhn-valid card numbers, SSN/ITIN, contextual bank/routing/SWIFT/card-last-four/DOB, selected business IDs, access codes, amounts, ZIP and street-address rules.
- Italian deterministic coverage currently includes email/PEC, phones, checksum-valid codice fiscale, contextual structurally plausible CF, checksum-valid partita IVA, checksum-valid Italian IBAN, contextual CAP/DOB and Italian street-address rules.
- As on Desktop, Italian-specific entity types are requested in addition to the current product profile/scope.
- Tests reuse exact frozen Desktop benchmark strings for `EN-FINANCIAL-001` and `EN-FINANCIAL-008`; they are not newly invented parity fixtures.

## Still missing before detector parity can be claimed

Desktop does not rely on regex alone. Its production service uses Presidio + local spaCy models plus PrivacyGate recognizers and guardrails. English uses `en_core_web_sm`; Italian uses the distributable `xx_ent_wiki_sm` semantic baseline. The Mobile app therefore does **not** claim detector parity yet.

The largest remaining gap is the semantic NER layer for PERSON / ORGANIZATION / LOCATION and the associated English/Italian propagation and guardrails. That must be implemented with a genuinely on-device mobile-capable model/runtime or another audited local implementation; it must not be replaced with broad guessed regexes.

After the native Flutter toolchain is available, the next gate is to run `flutter analyze` and `flutter test`, then synchronize the pinned 300-case English Desktop corpus and measure exact-span/category parity. Failures must drive the next recognizer/guardrail ports rather than changing expected labels to suit Mobile.
