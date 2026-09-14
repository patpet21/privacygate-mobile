from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

DESKTOP_COMMIT = "754f412596c7f32f04c3f50714dcd064704a3f13"
SOURCE_PREFIX = "benchmarks/english/v1/"
DESTINATION = Path("test/fixtures/desktop_754f412/english/v1")
EXPECTED_CASES = 300


def git(repo: Path, *args: str, text: bool = True):
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        capture_output=True,
        text=text,
    ).stdout


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Import the exact frozen PrivacyGate Desktop English v1 benchmark "
            "from the pinned compatibility commit without switching branches."
        )
    )
    parser.add_argument(
        "--desktop-repo",
        required=True,
        type=Path,
        help="Path to a local clone of patpet21/ai-pm-lab-privacy-gate",
    )
    parser.add_argument(
        "--destination",
        type=Path,
        default=DESTINATION,
        help="Fixture output directory",
    )
    args = parser.parse_args()

    repo = args.desktop_repo.resolve()
    if not (repo / ".git").exists():
        raise SystemExit(f"Not a Git repository: {repo}")

    # Prove the immutable Desktop object exists locally. We deliberately do not
    # checkout or modify the Desktop working tree.
    git(repo, "cat-file", "-e", f"{DESKTOP_COMMIT}^{{commit}}")

    paths = git(
        repo,
        "ls-tree",
        "-r",
        "--name-only",
        DESKTOP_COMMIT,
        SOURCE_PREFIX.rstrip("/"),
    ).splitlines()
    jsonl_paths = sorted(
        path for path in paths if path.startswith(SOURCE_PREFIX) and path.endswith(".jsonl")
    )
    if not jsonl_paths:
        raise SystemExit("Pinned Desktop commit contains no English v1 JSONL fixtures.")

    destination = args.destination.resolve()
    destination.mkdir(parents=True, exist_ok=True)

    expected_names = {Path(path).name for path in jsonl_paths}
    for existing in destination.glob("*.jsonl"):
        if existing.name not in expected_names:
            existing.unlink()

    total_cases = 0
    imported: list[dict[str, object]] = []
    for source_path in jsonl_paths:
        payload = git(
            repo,
            "show",
            f"{DESKTOP_COMMIT}:{source_path}",
            text=False,
        )
        target = destination / Path(source_path).name
        target.write_bytes(payload)

        rows = [line for line in payload.decode("utf-8").splitlines() if line.strip()]
        for line_number, line in enumerate(rows, start=1):
            try:
                json.loads(line)
            except json.JSONDecodeError as exc:
                raise SystemExit(
                    f"Invalid JSONL imported from {source_path}:{line_number}: {exc}"
                ) from exc
        total_cases += len(rows)
        blob_sha = git(repo, "rev-parse", f"{DESKTOP_COMMIT}:{source_path}").strip()
        imported.append(
            {
                "source_path": source_path,
                "git_blob_sha": blob_sha,
                "cases": len(rows),
            }
        )

    if total_cases != EXPECTED_CASES:
        raise SystemExit(
            f"Expected {EXPECTED_CASES} canonical cases, imported {total_cases}. "
            "Do not silently accept a changed corpus under the same fixture version."
        )

    provenance = {
        "desktop_repository": "patpet21/ai-pm-lab-privacy-gate",
        "desktop_commit": DESKTOP_COMMIT,
        "source_prefix": SOURCE_PREFIX,
        "total_cases": total_cases,
        "files": imported,
    }
    (destination.parent / "PROVENANCE.json").write_text(
        json.dumps(provenance, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print(
        f"Imported {total_cases} exact Desktop benchmark cases from {DESKTOP_COMMIT} "
        f"into {destination}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
