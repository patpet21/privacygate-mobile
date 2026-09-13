# Desktop Source Baseline for Mobile Compatibility

Verified against GitHub on 2026-09-12.

## Authoritative repository

`patpet21/ai-pm-lab-privacy-gate`

The repository default branch is `main`, but **default branch must not be assumed to be the authoritative Desktop application baseline for this compatibility work**.

## Stable Desktop 0.5.1 baseline

Branch:

`fix/gmail-addon-marketplace-review-20260908`

Commit:

`dc6a83b2a57af3ce6b9053ceffababe44f3cf35d`

Commit message:

`chore: bump PrivacyGate version to 0.5.1`

This commit is the stable Desktop release baseline to use when freezing protection/session/library behavior for Mobile compatibility unless a later Desktop release is explicitly promoted.

## Current integration / browser-extension hardening head

Branch:

`fix/browser-extension-store-hardening-20260909`

HEAD:

`754f412596c7f32f04c3f50714dcd064704a3f13`

Commit message:

`docs(extension): add 0.0.66 Chrome and Edge release test matrix`

This branch is **22 commits ahead of the 0.5.1 baseline and zero commits behind it**, so it is a direct descendant of `dc6a83...`.

The verified diff from `dc6a83...` to `754f412...` is concentrated in browser-extension, Gmail add-on, privacy documentation, and browser-extension build/security scripts. No core Desktop `src/ai_pm_lab_privacy_gate/...` application files appear in that compare result.

Therefore:

- use `dc6a83...` as the frozen stable Desktop runtime baseline;
- use `754f412...` when auditing the latest extension/Gmail integration surface;
- do not casually treat extension hardening as a new Desktop-core behavioral baseline.

## Gmail canonical synchronization branch

Branch:

`fix/gmail-canonical-sync-20260909`

HEAD:

`8dce4abcedbdb176d9df975d9e26cd074534a50d`

Commit message:

`fix(gmail): sync canonical reviewer and relay script`

This branch is relevant when auditing Gmail integration behavior but is not the Desktop-core baseline by itself.

## Default `main` branch warning

At verification time, `main` points to:

`df23551138b479141d59a90f4f7150ab9a12f2be`

Commit message:

`release: publish PrivacyGate 0.5.1 update manifest`

A GitHub compare between the stable Desktop baseline `dc6a83...` and `main` reports the histories as **diverged**. The compare reports `main` five commits ahead but the stable baseline 1187 commits ahead of the merge base. The visible changed files on the `main` side are web-demo/release/legal files.

For that reason, Mobile compatibility work must **not fetch Desktop behavior from the repository default branch merely because it is named `main`**.

Every audit read should pin an explicit ref.

## Audit ref policy

When reading Desktop code for Mobile compatibility:

1. Core protect/detect/restore/session/library/document behavior: pin `dc6a83b2a57af3ce6b9053ceffababe44f3cf35d`.
2. Browser extension and current Gmail integration behavior: pin `754f412596c7f32f04c3f50714dcd064704a3f13` unless a newer approved integration head is recorded here.
3. Never omit `ref` in GitHub file reads for the audit.
4. Record any future promoted Desktop baseline in this file before changing Mobile compatibility assumptions.
5. Compatibility fixtures should record the Desktop commit that produced the expected output.

## Next verification before implementation

Before implementing the shared session/mapping contract, inspect the stable baseline at `dc6a83...` for:

- domain models and profiles;
- Presidio/detection pipeline;
- placeholder generation;
- protection modes;
- reversible mapping representation;
- restore path;
- library/storage schema;
- document metadata and file export pipeline;
- local API boundaries;
- MCP exposure rules.

Only after those behaviors are documented should Mobile freeze its own serialized compatibility format.
