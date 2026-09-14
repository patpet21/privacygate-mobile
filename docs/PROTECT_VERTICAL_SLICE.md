# Protect vertical slice — Desktop to Mobile

Desktop source of truth for this slice: `patpet21/ai-pm-lab-privacy-gate` at commit `754f412596c7f32f04c3f50714dcd074534a3f13`.

## Product rule clarified

`scan_language` is the language used by the detector for the current text/document. It is not the language of the PrivacyGate user interface and it is not part of the industry profile.

The Desktop application core already keeps document language separate from the profile when calling `PrivacyGateService.analyze(...)`. Mobile therefore models this as a per-document `ProtectionPolicy.scanLanguage` control in the Protect workspace.

A future `app_language` preference, if added, will only localize menus, labels and messages and will remain independent from scan language.

## Desktop behavior represented in the Mobile slice

The Mobile Protect workspace now carries the Desktop concepts that can be implemented truthfully before native file/Vault work:

- Industry profile.
- Protection scope.
- Protection mode: reversible, generic, mask and redact.
- Detection confidence, range `0.10..0.95`, default `0.35`.
- Paste text input.
- Scan language next to the Scan action.
- Scan and Clear.
- Findings/category metrics.
- Filter findings.
- Protect all / Keep all / Invert.
- Category-level selection.
- Add missed item by exact text value and category.
- Protect selected items.
- Second local scan of the protected result before copy/export is enabled.
- Copy protected text only after the second scan passes.
- Local restore only when reversible mappings exist.

## State separation

Document protection state is no longer stored in general app Settings.

`ProtectionPolicy` owns:

- `profileKey`
- `scopeKey`
- `scanLanguage`
- `replacementMode`
- `confidenceThreshold`

`PrivacyGateSettings` owns Mobile Vault/application preferences only.

Changing any ProtectionPolicy field invalidates existing findings/results and requires a fresh scan. This prevents a result created with one language/profile/scope from being silently reused under another policy.

## Still intentionally incomplete

- `BootstrapPatternDetector` is still temporary and is not detector parity evidence.
- File import/export is not enabled by fake buttons; it will be added as its own vertical slice.
- Mobile Library/Vault persistence is not faked. The next storage slice must use encrypted persistence.
- Share-sheet integration requires Android/iOS host integration and comes after the real Flutter toolchain pass.
- Production detector parity remains gated by the canonical Desktop-owned benchmark corpus.

The purpose of this slice is functional parity, not pixel-for-pixel duplication of the Windows UI.
