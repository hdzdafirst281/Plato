from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import yaml
from docx import Document

from tools.build_usecase_doc import build_document


class BuildUsecaseDocTest(unittest.TestCase):
    def test_build_is_deterministic_and_contains_sources(self) -> None:
        temp_root = Path.cwd() / ".tmp"
        temp_root.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=temp_root) as directory:
            root = Path(directory)
            sources = root / "plato_docs/usecases"
            sources.mkdir(parents=True)
            sections = (
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
            body = "\n\n".join(f"## {section}\nNội dung {section}" for section in sections)
            (sources / "UC01.md").write_text(
                f"# UC01 — Ví dụ\n\n{body}\n", encoding="utf-8"
            )
            index = root / "plato_docs/usecase-index.yaml"
            index.write_text(
                yaml.safe_dump(
                    {
                        "usecases": {
                            "UC01": {
                                "title": "Ví dụ",
                                "source": "plato_docs/usecases/UC01.md",
                            }
                        }
                    },
                    allow_unicode=True,
                    sort_keys=False,
                ),
                encoding="utf-8",
            )
            first = root / "first.docx"
            second = root / "second.docx"
            build_document(root, "plato_docs/usecase-index.yaml", first)
            build_document(root, "plato_docs/usecase-index.yaml", second)

            self.assertEqual(first.read_bytes(), second.read_bytes())
            text = "\n".join(p.text for p in Document(first).paragraphs)
            self.assertIn("Đặc tả Use Case Plato", text)
            self.assertIn("UC01 Ví dụ", text)
            self.assertIn("Nội dung Mục tiêu", text)


if __name__ == "__main__":
    unittest.main()

