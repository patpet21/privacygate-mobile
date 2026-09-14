# Desktop 754f412 canonical fixture workspace

Do not hand-edit benchmark JSONL files in this directory.

The English v1 corpus is generated locally from the immutable Desktop source commit:

`patpet21/ai-pm-lab-privacy-gate@754f412596c7f32f04c3f50714dcd064704a3f13`

Run:

```text
python tool/sync_desktop_fixtures.py --desktop-repo <path-to-ai-pm-lab-privacy-gate>
```

The importer reads the benchmark objects with `git show` and does not switch or modify the Desktop working tree. It verifies that the pinned corpus still contains exactly 300 JSONL cases and writes provenance metadata beside the generated English fixture directory.

Generated JSONL files and provenance are intentionally ignored by Git. The Desktop commit remains their source of truth.
