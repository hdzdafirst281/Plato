from __future__ import annotations

import argparse
import glob
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

try:
    from tools.usecase_common import (
        DEFAULT_INDEX,
        REQUIRED_SECTIONS,
        USECASE_HEADING_PATTERN,
        USECASE_ID_PATTERN,
        load_localization_keys,
        load_usecase_index,
        repository_path,
        repository_root,
    )
except ModuleNotFoundError:
    from usecase_common import (  # type: ignore[no-redef]
        DEFAULT_INDEX,
        REQUIRED_SECTIONS,
        USECASE_HEADING_PATTERN,
        USECASE_ID_PATTERN,
        load_localization_keys,
        load_usecase_index,
        repository_path,
        repository_root,
    )


@dataclass(frozen=True)
class Issue:
    level: str
    message: str


def _duplicates(values: Iterable[str]) -> set[str]:
    seen: set[str] = set()
    duplicates: set[str] = set()
    for value in values:
        if value in seen:
            duplicates.add(value)
        seen.add(value)
    return duplicates


def _validate_string_list(
    uc_id: str, field: str, value: Any, *, required: bool = False
) -> tuple[list[str], list[Issue]]:
    if value is None and not required:
        return [], []
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item.strip() for item in value
    ):
        return [], [Issue("ERROR", f"{uc_id}: {field} must be a list of strings")]
    issues: list[Issue] = []
    if required and not value:
        issues.append(Issue("ERROR", f"{uc_id}: {field} must not be empty"))
    for duplicate in sorted(_duplicates(value)):
        issues.append(Issue("ERROR", f"{uc_id}: duplicate {field} value: {duplicate}"))
    return value, issues


def validate_repository(
    root: str | Path | None = None,
    index_path: str | Path = DEFAULT_INDEX,
    selected_uc: str | None = None,
) -> list[Issue]:
    repo = repository_root(root)
    issues: list[Issue] = []
    try:
        _, usecases = load_usecase_index(repo, index_path)
        localization = load_localization_keys(repo)
    except (OSError, ValueError) as error:
        return [Issue("ERROR", str(error))]

    if selected_uc:
        if selected_uc not in usecases:
            return [Issue("ERROR", f"Unknown use case: {selected_uc}")]
        entries = [(selected_uc, usecases[selected_uc])]
    else:
        entries = list(usecases.items())

    for uc_id, entry in entries:
        if not USECASE_ID_PATTERN.fullmatch(str(uc_id)):
            issues.append(Issue("ERROR", f"Invalid use case ID: {uc_id}"))
            continue
        if not isinstance(entry, dict):
            issues.append(Issue("ERROR", f"{uc_id}: entry must be a mapping"))
            continue

        title = entry.get("title")
        if not isinstance(title, str) or not title.strip():
            issues.append(Issue("ERROR", f"{uc_id}: title is required"))

        source = entry.get("source")
        if not isinstance(source, str) or not source.strip():
            issues.append(Issue("ERROR", f"{uc_id}: source is required"))
        else:
            try:
                source_path = repository_path(repo, source)
            except ValueError as error:
                issues.append(Issue("ERROR", f"{uc_id}: {error}"))
            else:
                if not source_path.is_file():
                    issues.append(Issue("ERROR", f"{uc_id}: source not found: {source}"))
                else:
                    content = source_path.read_text(encoding="utf-8")
                    heading = USECASE_HEADING_PATTERN.search(content)
                    if not heading:
                        issues.append(Issue("ERROR", f"{uc_id}: invalid H1 heading"))
                    else:
                        heading_id, heading_title = heading.groups()
                        if heading_id != uc_id:
                            issues.append(Issue("ERROR", f"{uc_id}: source heading uses ID {heading_id}"))
                        if isinstance(title, str) and heading_title != title:
                            issues.append(Issue("ERROR", f"{uc_id}: title differs between index and source"))
                    sections = {
                        line.removeprefix("## ").strip()
                        for line in content.splitlines()
                        if line.startswith("## ")
                    }
                    for section in REQUIRED_SECTIONS:
                        if section not in sections:
                            issues.append(Issue("ERROR", f"{uc_id}: missing section '{section}'"))

        features, field_issues = _validate_string_list(
            uc_id, "features", entry.get("features"), required=True
        )
        issues.extend(field_issues)
        if not features:
            issues.append(Issue("WARNING", f"{uc_id}: no feature tag is available"))

        code_paths, field_issues = _validate_string_list(
            uc_id, "code_paths", entry.get("code_paths"), required=True
        )
        issues.extend(field_issues)
        for pattern in code_paths:
            posix = PurePosixPath(pattern)
            if posix.is_absolute() or ".." in posix.parts:
                issues.append(Issue("ERROR", f"{uc_id}: unsafe code path: {pattern}"))
                continue
            matches = [
                Path(match)
                for match in glob.glob(str(repo / pattern), recursive=True)
                if Path(match).is_file()
            ]
            if not matches:
                issues.append(Issue("ERROR", f"{uc_id}: code path does not match a file: {pattern}"))

        localization_keys, field_issues = _validate_string_list(
            uc_id, "localization_keys", entry.get("localization_keys")
        )
        issues.extend(field_issues)
        for key in localization_keys:
            for relative, available in localization.items():
                if key not in available:
                    issues.append(
                        Issue(
                            "ERROR",
                            f"{uc_id}: localization key '{key}' missing from {relative.as_posix()}",
                        )
                    )

        related, field_issues = _validate_string_list(
            uc_id, "related_usecases", entry.get("related_usecases")
        )
        issues.extend(field_issues)
        for related_id in related:
            if not USECASE_ID_PATTERN.fullmatch(related_id):
                issues.append(Issue("ERROR", f"{uc_id}: invalid related use case: {related_id}"))
            elif related_id == uc_id:
                issues.append(Issue("ERROR", f"{uc_id}: cannot reference itself"))
            elif related_id not in usecases:
                issues.append(Issue("WARNING", f"{uc_id}: related {related_id} is not indexed yet"))

    indexed_sources = {
        entry.get("source") for entry in usecases.values() if isinstance(entry, dict)
    }
    for source_path in sorted((repo / "plato_docs/usecases").glob("UC[0-9][0-9].md")):
        relative = source_path.relative_to(repo).as_posix()
        if relative not in indexed_sources:
            issues.append(Issue("ERROR", f"Unindexed use case source: {relative}"))

    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Plato Use Case sources")
    parser.add_argument("--root", help="Repository root; defaults to the script parent")
    parser.add_argument("--index", default=str(DEFAULT_INDEX), help="Index path")
    parser.add_argument("--uc", help="Validate one UC ID")
    parser.add_argument("--strict", action="store_true", help="Treat warnings as failures")
    args = parser.parse_args()

    issues = validate_repository(args.root, args.index, args.uc)
    for issue in issues:
        print(f"[{issue.level}] {issue.message}")

    errors = sum(issue.level == "ERROR" for issue in issues)
    warnings = sum(issue.level == "WARNING" for issue in issues)
    print(f"Validated Use Cases: {errors} error(s), {warnings} warning(s)")
    return 1 if errors or (args.strict and warnings) else 0


if __name__ == "__main__":
    raise SystemExit(main())

