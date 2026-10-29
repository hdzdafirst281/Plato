from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import yaml

from tools.validate_usecases import validate_repository


class ValidateUsecasesTest(unittest.TestCase):
    def setUp(self) -> None:
        temp_root = Path.cwd() / ".tmp"
        temp_root.mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=temp_root)
        self.root = Path(self.temp.name)
        (self.root / "plato_docs/usecases").mkdir(parents=True)
        (self.root / "plato_gymapp/lib/i18n").mkdir(parents=True)
        (self.root / "plato_gymapp/lib/example").mkdir(parents=True)
        (self.root / "plato_gymapp/lib/example/example.dart").write_text(
            "void main() {}\n", encoding="utf-8"
        )
        strings = {"settings": {"title": "Example"}}
        for language in ("vi", "en"):
            (self.root / f"plato_gymapp/lib/i18n/strings_{language}.i18n.json").write_text(
                json.dumps(strings), encoding="utf-8"
            )
        sections = "\n\n".join(
            f"## {heading}\nNội dung"
            for heading in (
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
        )
        (self.root / "plato_docs/usecases/UC01.md").write_text(
            f"# UC01 — Ví dụ\n\n{sections}\n", encoding="utf-8"
        )
        self.index = {
            "usecases": {
                "UC01": {
                    "title": "Ví dụ",
                    "source": "plato_docs/usecases/UC01.md",
                    "features": ["example"],
                    "code_paths": ["plato_gymapp/lib/example/example.dart"],
                    "localization_keys": ["settings.title"],
                    "related_usecases": [],
                }
            }
        }
        template = self.root / "plato_docs/templates/usecase-template.docx"
        template.parent.mkdir(parents=True)
        template.write_bytes(b"template fixture")
        self.document_spec = {
            "template": "plato_docs/templates/usecase-template.docx",
            "groups": [
                {"title": "A. Ví dụ", "usecases": ["UC01"]},
                {"title": "B. Nhóm 2", "usecases": []},
                {"title": "C. Nhóm 3", "usecases": []},
                {"title": "D. Nhóm 4", "usecases": []},
                {"title": "E. Nhóm 5", "usecases": []},
                {"title": "F. Nhóm 6", "usecases": []},
                {"title": "G. Nhóm 7", "usecases": []},
            ],
            "glossary": [{"term": "Ví dụ", "definition": "Mô tả"}],
            "usecases": {
                "UC01": {
                    "summary": "Tóm tắt",
                    "importance": "Cao",
                    "type": "essential",
                    "supporting_actor": "Không có",
                    "offstage_actor": "Không có",
                    "relationships": {
                        "entry_point": "Màn hình ví dụ",
                        "association": "Người dùng",
                        "include": "Không có",
                        "extend": "Không có",
                    },
                }
            },
        }
        self._write_index()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_index(self) -> None:
        (self.root / "plato_docs/usecase-index.yaml").write_text(
            yaml.safe_dump(self.index, allow_unicode=True, sort_keys=False),
            encoding="utf-8",
        )
        (self.root / "plato_docs/usecase-document.yaml").write_text(
            yaml.safe_dump(self.document_spec, allow_unicode=True, sort_keys=False),
            encoding="utf-8",
        )

    def test_valid_repository_has_no_issues(self) -> None:
        self.assertEqual(validate_repository(self.root), [])

    def test_missing_code_path_is_an_error(self) -> None:
        self.index["usecases"]["UC01"]["code_paths"] = ["missing.dart"]
        self._write_index()
        issues = validate_repository(self.root)
        self.assertTrue(
            any(issue.level == "ERROR" and "does not match" in issue.message for issue in issues)
        )

    def test_title_mismatch_is_an_error(self) -> None:
        self.index["usecases"]["UC01"]["title"] = "Tên khác"
        self._write_index()
        issues = validate_repository(self.root)
        self.assertTrue(any("title differs" in issue.message for issue in issues))

    def test_duplicate_use_case_id_is_an_error(self) -> None:
        index_path = self.root / "plato_docs/usecase-index.yaml"
        index_path.write_text(
            "usecases:\n  UC01:\n    title: A\n  UC01:\n    title: B\n",
            encoding="utf-8",
        )
        issues = validate_repository(self.root)
        self.assertTrue(any("Duplicate YAML key" in issue.message for issue in issues))


if __name__ == "__main__":
    unittest.main()
