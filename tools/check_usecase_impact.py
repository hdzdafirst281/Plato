from __future__ import annotations

import argparse
import fnmatch
import json
import os
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable

try:
    from tools.usecase_common import (
        DEFAULT_INDEX,
        LOCALIZATION_FILES,
        flatten_mapping,
        load_usecase_index,
        normalize_repo_path,
        repository_root,
    )
except ModuleNotFoundError:
    from usecase_common import (  # type: ignore[no-redef]
        DEFAULT_INDEX,
        LOCALIZATION_FILES,
        flatten_mapping,
        load_usecase_index,
        normalize_repo_path,
        repository_root,
    )

IGNORED_GENERATED_FILES = {"plato_gymapp/lib/i18n/strings.g.dart"}


def _git(repo: Path, *args: str, allow_missing: bool = False) -> str | None:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode:
        if allow_missing:
            return None
        raise RuntimeError(result.stderr.strip() or "git command failed")
    return result.stdout


def changed_files(repo: Path, *, staged: bool, base: str | None) -> list[str]:
    args = ["diff", "--cached", "--name-only", "--diff-filter=ACMR"] if staged else [
        "diff",
        "--name-only",
        "--diff-filter=ACMR",
        f"{base}...HEAD",
    ]
    output = _git(repo, *args)
    return sorted(
        normalize_repo_path(line) for line in (output or "").splitlines() if line.strip()
    )


def _git_json(repo: Path, revision: str, path: str) -> dict[str, Any]:
    object_name = f":{path}" if revision == ":" else f"{revision}:{path}"
    content = _git(repo, "show", object_name, allow_missing=True)
    if content is None:
        return {}
    try:
        value = json.loads(content)
    except json.JSONDecodeError:
        return {}
    return flatten_mapping(value)


def changed_localization_keys(
    repo: Path, files: Iterable[str], *, staged: bool, base: str | None
) -> set[str]:
    changed: set[str] = set()
    localization_paths = {path.as_posix() for path in LOCALIZATION_FILES}
    for path in set(files) & localization_paths:
        old = _git_json(repo, "HEAD" if staged else str(base), path)
        new = _git_json(repo, ":" if staged else "HEAD", path)
        for key in old.keys() | new.keys():
            if old.get(key) != new.get(key):
                changed.add(key)
    return changed


def analyze_impact(
    usecases: dict[str, dict[str, Any]],
    files: Iterable[str],
    localization_keys: set[str] | None = None,
) -> tuple[dict[str, list[str]], list[str]]:
    changed = [normalize_repo_path(path) for path in files]
    localization_keys = localization_keys or set()
    impacts: dict[str, list[str]] = defaultdict(list)
    matched_files: set[str] = set()
    localization_paths = {item.as_posix() for item in LOCALIZATION_FILES}

    for uc_id, entry in usecases.items():
        source = normalize_repo_path(entry.get("source", ""))
        patterns = [normalize_repo_path(path) for path in entry.get("code_paths", [])]
        indexed_keys = set(entry.get("localization_keys", []))
        for path in changed:
            if path == source:
                impacts[uc_id].append(f"source changed: {path}")
                matched_files.add(path)
            for pattern in patterns:
                if fnmatch.fnmatchcase(path, pattern):
                    impacts[uc_id].append(f"code path matched {pattern}: {path}")
                    matched_files.add(path)
                    break
        for key in sorted(indexed_keys & localization_keys):
            impacts[uc_id].append(f"localization changed: {key}")
            matched_files.update(path for path in changed if path in localization_paths)

    index_path = DEFAULT_INDEX.as_posix()
    if index_path in changed:
        matched_files.add(index_path)
        for uc_id in usecases:
            impacts[uc_id].append(f"index changed: {index_path}")

    scoped = {
        path
        for path in changed
        if path not in IGNORED_GENERATED_FILES
        and (
            path.startswith("plato_gymapp/lib/")
            or (path.startswith("plato_docs/usecases/") and path.lower().endswith(".md"))
        )
    }
    return dict(impacts), sorted(scoped - matched_files)


def render_report(
    files: list[str],
    impacts: dict[str, list[str]],
    unclassified: list[str],
    localization_keys: set[str],
) -> str:
    lines = ["## Plato Use Case impact", "", f"Changed files: {len(files)}"]
    if localization_keys:
        lines.append(f"Changed localization keys: {len(localization_keys)}")
    lines.append("")
    if impacts:
        lines.append("### Use Cases to review")
        for uc_id in sorted(impacts):
            lines.append(f"- {uc_id}")
            for reason in sorted(set(impacts[uc_id])):
                lines.append(f"  - {reason}")
    else:
        lines.append("No indexed Use Case was affected.")
    if unclassified:
        lines.extend(["", "### Unclassified scoped files"])
        lines.extend(f"- {path}" for path in unclassified)
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Report Use Cases affected by a Git diff")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--staged", action="store_true", help="Inspect the staged diff")
    mode.add_argument("--base", help="Inspect BASE...HEAD")
    mode.add_argument("--files", nargs="+", help="Inspect an explicit file list")
    parser.add_argument("--root", help="Repository root")
    parser.add_argument("--index", default=str(DEFAULT_INDEX), help="Index path")
    parser.add_argument(
        "--fail-on-unclassified",
        action="store_true",
        help="Return a failure when scoped files have no mapping",
    )
    parser.add_argument(
        "--github-summary", action="store_true", help="Append the report to GITHUB_STEP_SUMMARY"
    )
    args = parser.parse_args()

    repo = repository_root(args.root)
    try:
        _, usecases = load_usecase_index(repo, args.index)
        files = (
            [normalize_repo_path(path) for path in args.files]
            if args.files
            else changed_files(repo, staged=args.staged, base=args.base)
        )
        keys = (
            set()
            if args.files
            else changed_localization_keys(repo, files, staged=args.staged, base=args.base)
        )
    except (OSError, RuntimeError, ValueError) as error:
        print(f"[ERROR] {error}")
        return 2

    impacts, unclassified = analyze_impact(usecases, files, keys)
    report = render_report(files, impacts, unclassified, keys)
    print(report)

    if args.github_summary:
        summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if summary:
            with open(summary, "a", encoding="utf-8") as stream:
                stream.write(report + "\n")

    return 1 if args.fail_on_unclassified and unclassified else 0


if __name__ == "__main__":
    raise SystemExit(main())
