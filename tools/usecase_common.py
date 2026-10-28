from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

import yaml


DEFAULT_INDEX = Path("plato_docs/usecase-index.yaml")
DEFAULT_DOCUMENT_SPEC = Path("plato_docs/usecase-document.yaml")
LOCALIZATION_FILES = (
    Path("plato_gymapp/lib/i18n/strings_vi.i18n.json"),
    Path("plato_gymapp/lib/i18n/strings_en.i18n.json"),
)
REQUIRED_SECTIONS = (
    "Mục tiêu",
    "Tác nhân",
    "Tiền điều kiện",
    "Kích hoạt",
    "Luồng chính",
    "Luồng thay thế và ngoại lệ",
    "Hậu điều kiện",
    "Quy tắc nghiệp vụ",
    "Use Case liên quan",
    "Thuật ngữ",
)
USECASE_ID_PATTERN = re.compile(r"^UC\d{2}$")
USECASE_HEADING_PATTERN = re.compile(
    r"^#\s+(UC\d{2})\s+[—–-]\s+(.+?)\s*$", re.MULTILINE
)


class UniqueKeyLoader(yaml.SafeLoader):
    """Safe YAML loader that rejects duplicate mapping keys."""


def _construct_unique_mapping(
    loader: UniqueKeyLoader, node: yaml.MappingNode, deep: bool = False
) -> dict[Any, Any]:
    mapping: dict[Any, Any] = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise ValueError(f"Duplicate YAML key: {key}")
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _construct_unique_mapping
)


def repository_root(root: str | Path | None = None) -> Path:
    return Path(root).resolve() if root else Path(__file__).resolve().parents[1]


def repository_path(root: Path, relative: str | Path) -> Path:
    candidate = (root / relative).resolve()
    if not candidate.is_relative_to(root):
        raise ValueError(f"Path escapes repository root: {relative}")
    return candidate


def load_usecase_index(
    root: Path, index_path: str | Path = DEFAULT_INDEX
) -> tuple[Path, dict[str, dict[str, Any]]]:
    path = repository_path(root, index_path)
    try:
        with path.open("r", encoding="utf-8") as stream:
            data = yaml.load(stream, Loader=UniqueKeyLoader) or {}
    except yaml.YAMLError as error:
        raise ValueError(f"Invalid YAML in {index_path}: {error}") from error
    usecases = data.get("usecases")
    if not isinstance(usecases, dict):
        raise ValueError(f"{index_path} must contain a 'usecases' mapping")
    return path, usecases


def load_document_spec(
    root: Path, spec_path: str | Path = DEFAULT_DOCUMENT_SPEC
) -> tuple[Path, dict[str, Any]]:
    path = repository_path(root, spec_path)
    try:
        with path.open("r", encoding="utf-8") as stream:
            data = yaml.load(stream, Loader=UniqueKeyLoader) or {}
    except yaml.YAMLError as error:
        raise ValueError(f"Invalid YAML in {spec_path}: {error}") from error
    if not isinstance(data, dict):
        raise ValueError(f"{spec_path} must contain a mapping")
    return path, data


def load_localization_keys(root: Path) -> dict[Path, set[str]]:
    result: dict[Path, set[str]] = {}
    for relative in LOCALIZATION_FILES:
        path = repository_path(root, relative)
        with path.open("r", encoding="utf-8") as stream:
            result[relative] = set(flatten_mapping(json.load(stream)))
    return result


def flatten_mapping(data: Any, prefix: str = "") -> dict[str, Any]:
    if not isinstance(data, dict):
        return {prefix: data} if prefix else {}
    flattened: dict[str, Any] = {}
    for key, value in data.items():
        path = f"{prefix}.{key}" if prefix else str(key)
        if isinstance(value, dict):
            flattened.update(flatten_mapping(value, path))
        else:
            flattened[path] = value
    return flattened


def normalize_repo_path(path: str | Path) -> str:
    return Path(path).as_posix().lstrip("./")

