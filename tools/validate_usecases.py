from __future__ import annotations

import argparse
import glob
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

try:
    from tools.usecase_common import (
        DEFAULT_INDEX,
        DEFAULT_DOCUMENT_SPEC,
        REQUIRED_SECTIONS,
        USECASE_HEADING_PATTERN,
        USECASE_ID_PATTERN,
        load_localization_keys,
        load_document_spec,
        load_usecase_index,
        repository_path,
        repository_root,
    )
except ModuleNotFoundError:
    from usecase_common import (  # type: ignore[no-redef]
        DEFAULT_INDEX,
        DEFAULT_DOCUMENT_SPEC,
        REQUIRED_SECTIONS,
        USECASE_HEADING_PATTERN,
        USECASE_ID_PATTERN,
        load_localization_keys,
        load_document_spec,
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


def _validate_document_spec(
    repo: Path, spec: dict[str, Any], usecases: dict[str, dict[str, Any]]
) -> list[Issue]:
    issues: list[Issue] = []
    template = spec.get("template")
    if not isinstance(template, str) or not template.strip():
        issues.append(Issue("ERROR", "document spec: template is required"))
    else:
        try:
            template_path = repository_path(repo, template)
        except ValueError as error:
            issues.append(Issue("ERROR", f"document spec: {error}"))
        else:
            if not template_path.is_file():
                issues.append(Issue("ERROR", f"document spec: template not found: {template}"))

    groups = spec.get("groups")
    grouped_ids: list[str] = []
    if not isinstance(groups, list) or not groups:
        issues.append(Issue("ERROR", "document spec: groups must be a non-empty list"))
    elif len(groups) != 7:
        issues.append(Issue("ERROR", "document spec: exactly 7 use case groups are required"))
    if isinstance(groups, list):
        for position, group in enumerate(groups, start=1):
            if not isinstance(group, dict):
                issues.append(Issue("ERROR", f"document spec: group {position} must be a mapping"))
                continue
            title = group.get("title")
            if not isinstance(title, str) or not title.strip():
                issues.append(Issue("ERROR", f"document spec: group {position} title is required"))
            ids = group.get("usecases")
            if not isinstance(ids, list) or not all(isinstance(item, str) for item in ids):
                issues.append(Issue("ERROR", f"document spec: group {position} usecases must be a list of IDs"))
            else:
                grouped_ids.extend(ids)
        for duplicate in sorted(_duplicates(grouped_ids)):
            issues.append(Issue("ERROR", f"document spec: duplicate grouped use case: {duplicate}"))
        missing = sorted(set(usecases) - set(grouped_ids))
        extra = sorted(set(grouped_ids) - set(usecases))
        if missing:
            issues.append(Issue("ERROR", f"document spec: ungrouped use cases: {', '.join(missing)}"))
        if extra:
            issues.append(Issue("ERROR", f"document spec: unknown grouped use cases: {', '.join(extra)}"))

    glossary = spec.get("glossary")
    if not isinstance(glossary, list) or not glossary:
        issues.append(Issue("ERROR", "document spec: glossary must be a non-empty list"))
    else:
        for position, item in enumerate(glossary, start=1):
            if not isinstance(item, dict) or not all(
                isinstance(item.get(field), str) and item[field].strip()
                for field in ("term", "definition")
            ):
                issues.append(Issue("ERROR", f"document spec: glossary item {position} is invalid"))

    metadata = spec.get("usecases")
    if not isinstance(metadata, dict):
        return issues + [Issue("ERROR", "document spec: usecases must be a mapping")]
    missing_metadata = sorted(set(usecases) - set(metadata))
    extra_metadata = sorted(set(metadata) - set(usecases))
    if missing_metadata:
        issues.append(Issue("ERROR", f"document spec: missing metadata: {', '.join(missing_metadata)}"))
    if extra_metadata:
        issues.append(Issue("ERROR", f"document spec: unknown metadata: {', '.join(extra_metadata)}"))
    for uc_id in sorted(set(usecases) & set(metadata)):
        entry = metadata[uc_id]
        if not isinstance(entry, dict):
            issues.append(Issue("ERROR", f"{uc_id}: document metadata must be a mapping"))
            continue
        for field in ("summary", "importance", "supporting_actor", "offstage_actor"):
            value = entry.get(field)
            if not isinstance(value, str) or not value.strip():
                issues.append(Issue("ERROR", f"{uc_id}: document field '{field}' is required"))
        if entry.get("type") not in {"essential", "temporal"}:
            issues.append(Issue("ERROR", f"{uc_id}: document type must be essential or temporal"))
        relationships = entry.get("relationships")
        if not isinstance(relationships, dict):
            issues.append(Issue("ERROR", f"{uc_id}: relationships must be a mapping"))
            continue
        for field in ("entry_point", "association", "include", "extend"):
            value = relationships.get(field)
            if not isinstance(value, str) or not value.strip():
                issues.append(Issue("ERROR", f"{uc_id}: relationship '{field}' is required"))
    return issues


def validate_repository(
    root: str | Path | None = None,
    index_path: str | Path = DEFAULT_INDEX,
    selected_uc: str | None = None,
    document_spec_path: str | Path = DEFAULT_DOCUMENT_SPEC,
) -> list[Issue]:
    repo = repository_root(root)
    issues: list[Issue] = []
    try:
        _, usecases = load_usecase_index(repo, index_path)
        _, document_spec = load_document_spec(repo, document_spec_path)
        localization = load_localization_keys(repo)
    except (OSError, ValueError) as error:
        return [Issue("ERROR", str(error))]

    issues.extend(_validate_document_spec(repo, document_spec, usecases))

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

