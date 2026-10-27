from __future__ import annotations

import argparse
import re
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

try:
    from tools.usecase_common import DEFAULT_INDEX, load_usecase_index, repository_root
    from tools.validate_usecases import validate_repository
except ModuleNotFoundError:
    from usecase_common import DEFAULT_INDEX, load_usecase_index, repository_root  # type: ignore[no-redef]
    from validate_usecases import validate_repository  # type: ignore[no-redef]


DEFAULT_OUTPUT = Path("plato_docs/generated/plato_usecases.docx")
FIXED_TIMESTAMP = datetime(2026, 10, 27, tzinfo=timezone.utc)
ZIP_TIMESTAMP = (2026, 10, 27, 0, 0, 0)
HEADING_PATTERN = re.compile(r"^#\s+UC\d{2}\s+[—–-]\s+.+$", re.MULTILINE)
NUMBERED_PATTERN = re.compile(r"^(\d+\.)\s+(.+)$")
INLINE_PATTERN = re.compile(r"(\*\*.+?\*\*|`.+?`)")


def _font(run, name: str = "Aptos", size: float | None = None) -> None:
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    if size is not None:
        run.font.size = Pt(size)


def _add_inline(paragraph, text: str) -> None:
    for part in INLINE_PATTERN.split(text):
        if not part:
            continue
        if part.startswith("**") and part.endswith("**"):
            run = paragraph.add_run(part[2:-2])
            run.bold = True
        elif part.startswith("`") and part.endswith("`"):
            run = paragraph.add_run(part[1:-1])
            _font(run, "Cascadia Mono", 9.5)
        else:
            paragraph.add_run(part)


def _set_keep_with_next(paragraph) -> None:
    paragraph.paragraph_format.keep_with_next = True


def _add_page_number(paragraph) -> None:
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run("Trang ")
    _font(run, size=9)
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instruction = OxmlElement("w:instrText")
    instruction.set(qn("xml:space"), "preserve")
    instruction.text = " PAGE "
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.extend((begin, instruction, end))


def _configure_document(document: Document) -> None:
    section = document.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(0.7)
    section.left_margin = Inches(0.85)
    section.right_margin = Inches(0.85)

    styles = document.styles
    normal = styles["Normal"]
    normal.font.name = "Aptos"
    normal.font.size = Pt(10.5)
    normal.font.color.rgb = RGBColor(0, 0, 0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.12

    for name, size, before, after in (
        ("Title", 26, 0, 16),
        ("Subtitle", 12, 0, 18),
        ("Heading 1", 18, 8, 8),
        ("Heading 2", 12.5, 10, 5),
    ):
        style = styles[name]
        style.font.name = "Aptos Display" if name != "Subtitle" else "Aptos"
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True
        borders = style.element.get_or_add_pPr().find(qn("w:pBdr"))
        if borders is not None:
            style.element.get_or_add_pPr().remove(borders)

    document.core_properties.title = "Đặc tả Use Case Plato"
    document.core_properties.subject = "Đặc tả 31 Use Case của ứng dụng Plato"
    document.core_properties.author = "Plato"
    document.core_properties.last_modified_by = "Plato Docs Generator"
    document.core_properties.created = FIXED_TIMESTAMP
    document.core_properties.modified = FIXED_TIMESTAMP
    _add_page_number(section.footer.paragraphs[0])


def _add_cover(document: Document) -> None:
    document.add_paragraph("Đặc tả Use Case Plato", style="Title")
    document.add_paragraph("Phạm vi ứng dụng di động với 31 Use Case", style="Subtitle")
    document.add_paragraph(
        "Tài liệu này tổng hợp luồng nghiệp vụ, điều kiện, ngoại lệ và quy tắc của "
        "UC01 đến UC31. Nội dung được tạo từ các tệp Markdown đã kiểm tra bằng "
        "usecase-index.yaml; hãy sửa nguồn Markdown và chạy lại generator thay vì "
        "chỉnh trực tiếp tệp Word."
    )
    document.add_paragraph(
        "Các giới hạn đồng bộ, lưu cục bộ và xử lý bất đồng bộ được giữ lại để tài "
        "liệu phản ánh hành vi hiện hành của ứng dụng."
    )
    document.add_page_break()


def _add_usecase(document: Document, uc_id: str, title: str, markdown: str) -> None:
    heading = document.add_paragraph(f"{uc_id} {title}", style="Heading 1")
    _set_keep_with_next(heading)

    for raw_line in markdown.splitlines()[1:]:
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("## "):
            document.add_paragraph(line[3:].strip(), style="Heading 2")
            continue
        numbered = NUMBERED_PATTERN.match(line)
        if numbered:
            paragraph = document.add_paragraph()
            paragraph.paragraph_format.left_indent = Inches(0.24)
            paragraph.paragraph_format.first_line_indent = Inches(-0.2)
            _add_inline(paragraph, f"{numbered.group(1)} {numbered.group(2)}")
            continue
        if line.startswith("- "):
            paragraph = document.add_paragraph(style="List Bullet")
            _add_inline(paragraph, line[2:])
            continue
        paragraph = document.add_paragraph()
        _add_inline(paragraph, line)


def _normalize_docx(path: Path) -> None:
    with zipfile.ZipFile(path, "r") as source:
        entries = [(item.filename, source.read(item.filename)) for item in source.infolist()]
    with tempfile.NamedTemporaryFile(dir=path.parent, suffix=".docx", delete=False) as stream:
        normalized = Path(stream.name)
    try:
        with zipfile.ZipFile(normalized, "w", compression=zipfile.ZIP_DEFLATED) as target:
            for name, data in sorted(entries):
                info = zipfile.ZipInfo(name, ZIP_TIMESTAMP)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o600 << 16
                target.writestr(info, data)
        normalized.replace(path)
    finally:
        normalized.unlink(missing_ok=True)


def build_document(root: Path, index_path: str | Path, output: Path) -> None:
    _, usecases = load_usecase_index(root, index_path)
    document = Document()
    _configure_document(document)
    _add_cover(document)

    ordered = sorted(usecases.items())
    for position, (uc_id, entry) in enumerate(ordered):
        source = root / entry["source"]
        markdown = source.read_text(encoding="utf-8")
        if not HEADING_PATTERN.search(markdown):
            raise ValueError(f"Invalid source heading: {source}")
        if position:
            document.add_page_break()
        _add_usecase(document, uc_id, entry["title"], markdown)

    output.parent.mkdir(parents=True, exist_ok=True)
    document.save(output)
    _normalize_docx(output)


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the Plato Use Case DOCX")
    parser.add_argument("--root", help="Repository root")
    parser.add_argument("--index", default=str(DEFAULT_INDEX), help="Index path")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Output DOCX")
    parser.add_argument("--check", action="store_true", help="Fail when generated output is stale")
    args = parser.parse_args()

    root = repository_root(args.root)
    issues = validate_repository(root, args.index)
    if issues:
        for issue in issues:
            print(f"[{issue.level}] {issue.message}")
        return 1

    output = (root / args.output).resolve()
    if args.check:
        if not output.is_file():
            print(f"Generated DOCX is missing: {output.relative_to(root)}")
            return 1
        with tempfile.TemporaryDirectory(dir=root / ".tmp") as directory:
            candidate = Path(directory) / output.name
            build_document(root, args.index, candidate)
            if candidate.read_bytes() != output.read_bytes():
                print(f"Generated DOCX is stale: {output.relative_to(root)}")
                return 1
        print(f"Generated DOCX is current: {output.relative_to(root)}")
        return 0

    build_document(root, args.index, output)
    print(f"Generated DOCX: {output.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

