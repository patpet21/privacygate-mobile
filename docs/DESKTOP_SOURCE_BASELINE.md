# Desktop Source Baseline for Mobile Compatibility

Verified against GitHub on 2026-09-13.

## Authoritative repository

`patpet21/ai-pm-lab-privacy-gate`

The repository default branch must not be assumed to be the authoritative Desktop baseline for Mobile compatibility work. Every audit read must pin an explicit ref.

## Next-release source of truth

Branch: `fix/browser-extension-store-hardening-20260909`

Commit: `754f412596c7f32f04c3f50714dcd064704a3f13`

Commit message: `docs(extension): add 0.0.66 Chrome and Edge release test matrix`

For Mobile architecture and compatibility work, this commit is the single source of truth for the complete next-release Desktop state.

It is a direct descendant of the Desktop 0.5.1 baseline and is 22 commits ahead and zero commits behind `dc6a83b2a57af3ce6b9053ceffababe44f3cf35d`.

Do not describe `754f412...` as already released. It is the next-release source state under audit.

## Historical released baseline

Desktop 0.5.1:

- Branch: `fix/gmail-addon-marketplace-review-20260908`
- Commit: `dc6a83b2a57af3ce6b9053ceffababe44f3cf35d`
- Commit message: `chore: bump PrivacyGate version to 0.5.1`

Use this ref only when the question is specifically what changed since Desktop 0.5.1. Do not split normal Mobile compatibility reads between `dc6a83...` and `754f412...`.

## Gmail lineage note

The earlier Gmail synchronization branch is `fix/gmail-canonical-sync-20260909` at `8dce4abcedbdb176d9df975d9e26cd074534a50d`.

`754f412...` is 19 commits ahead of that ref and has it as its merge base, so it is an evolution of that branch rather than a separate alternative source.

## Default `main` warning

At the last verification, `main` pointed to `df23551138b479141d59a90f4f7150ab9a12f2be` with commit message `release: publish PrivacyGate 0.5.1 update manifest`.

Its history diverges from the stable Desktop release lineage. Mobile compatibility work must not read Desktop behavior from `main` merely because it is the default branch.

## Audit ref policy

1. Pin `754f412596c7f32f04c3f50714dcd064704a3f13` for all Desktop source reads used to define Mobile behavior.
2. Use the same ref for core protection, restore, Library, local API, browser pairing, file workflows, integrations, MCP and extension behavior.
3. Use `dc6a83...` only for historical release comparisons.
4. Never omit `ref` in GitHub file reads for this audit.
5. Record the exact Desktop commit in every compatibility fixture or expected-output test.
6. If a later Desktop commit is explicitly promoted as the new source of truth, update this file before changing Mobile assumptions.

## Verified source areas at `754f412...`

The first deep audit has confirmed the relevant Protect/Restore/session paths, including `application/privacy_service.py`, `application/protect_session_service.py`, `domain/models.py`, `infrastructure/storage/library_repository.py`, `infrastructure/storage/ai_library_repository.py`, `infrastructure/security/local_protector.py`, and the browser/local API session, persistence, pairing, restore and file workflow modules.

The resulting verified behavior is recorded in `DESKTOP_COMPATIBILITY_AUDIT.md`.
