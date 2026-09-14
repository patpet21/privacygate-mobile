# Canonical parity fixture policy

Desktop source of truth: `patpet21/ai-pm-lab-privacy-gate@754f412596c7f32f04c3f50714dcd064704a3f13`.

## Rule

Mobile parity tests must prefer frozen test/benchmark material that already exists in the canonical Desktop source. Small hand-written Dart examples are allowed only as smoke/unit tests for one isolated contract (for example token formatting). They are not evidence of detector parity.

Do not create a second Mobile-only detector benchmark simply to make the Mobile implementation pass.

## English baseline

The canonical Desktop English v1 corpus lives at:

`benchmarks/english/v1/*.jsonl`

At the pinned Desktop commit the accompanying README defines a frozen synthetic baseline of 300 cases, including positive, negative/adversarial, current-coverage and roadmap cases. Mobile imports those exact JSONL files rather than rewriting their text or expected spans.

Use `tool/sync_desktop_fixtures.py` to copy the exact files from a local Desktop repository object at the pinned commit without switching the Desktop working tree.

Imported destination:

`test/fixtures/desktop_754f412/english/v1/`

The imported JSONL files are treated as generated test inputs. Their source of truth remains the pinned Desktop commit.

## Italian

At the pinned Desktop commit there is no frozen Italian JSONL corpus equivalent to English v1. Desktop currently documents synthetic Italian regression coverage in its local test suite. Mobile must not invent a competing Italian benchmark and call it parity.

Until Desktop freezes an Italian benchmark corpus, Mobile should:

- port only canonical Italian entity identifiers/language behavior already verified from Desktop;
- reuse exact Desktop regression material when it is extracted into a stable fixture;
- keep English v1 as the frozen detector-regression lock;
- clearly mark any temporary Mobile-only Italian unit example as a smoke test, not a parity benchmark.

## Data safety

Parity fixtures must never contain real customer, production, or personal data. Existing Desktop benchmark/test material is synthetic. Third-party datasets are not copied into Mobile unless licensing and redistribution have been reviewed.

## Acceptance terminology

- `SMOKE`: proves a small component runs or formats data correctly.
- `CONTRACT`: proves a deterministic shared PrivacyGate rule such as placeholder/session serialization.
- `PARITY`: compares Mobile behavior against canonical Desktop-owned fixtures/expected output.
- `E2E`: validates a real app/file/device workflow.

A green smoke test must never be reported as detector parity or end-to-end compatibility.
