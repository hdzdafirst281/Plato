# Quy trình CI CD cho Plato Docs

## Mục tiêu

Quy trình kiểm tra nguồn Use Case trên mỗi pull request và chuẩn bị cho việc phát hành tài liệu sau khi thay đổi được hợp nhất vào `main`. Migration đã hoàn tất: UC01-UC31 đều có nguồn Markdown và mapping trong index; metadata trình bày nằm trong `usecase-document.yaml`, còn cấu trúc Word chuẩn nằm trong `templates/usecase-template.docx`.

## Kiểm tra cục bộ

Cài dependency cho tooling:

```powershell
python -m pip install --requirement tools/requirements.txt
```

Chạy test và validator:

```powershell
python -m unittest discover --start-directory tools/tests --pattern "test_*.py"
python tools/validate_usecases.py --strict
python tools/build_usecase_doc.py --check
```

Xem tác động của phần đã stage hoặc của branch hiện tại:

```powershell
python tools/check_usecase_impact.py --staged --fail-on-unclassified
python tools/check_usecase_impact.py --base main --fail-on-unclassified
```

## CI trên pull request

Workflow `.github/workflows/plato-docs.yml` chạy trên mọi pull request để status check luôn được tạo ổn định, kể cả khi sau này job được đặt làm required check. Job quality thực hiện:

1. Cài dependency Python đã pin.
2. Chạy unit test của tooling.
3. Validate strict cấu trúc, title, section, code path, localization key và quan hệ UC.
4. Tạo lại DOCX từ Markdown, index, document metadata và template; kiểm tra byte-for-byte với file generated đã commit.
5. So sánh branch với base commit, ghi danh sách UC cần review vào GitHub Step Summary và chặn file nghiệp vụ chưa có mapping.

Pull request vẫn phải dùng template để ghi rõ UC đã cập nhật hoặc lý do `reviewed-no-change`. File dưới `plato_gymapp/lib/` và `plato_docs/usecases/*.md` không khớp mapping sẽ làm CI thất bại.

## Trạng thái CD

Repository hiện là public, nhưng CD artifact chưa cần bật ở giai đoạn này. Workflow chỉ kiểm tra tài liệu và không upload hoặc phát hành tài liệu sang GitHub Actions Artifact, GitHub Release hay dịch vụ ngoài.

Khi có nhu cầu phát hành, cần xác nhận lại phạm vi công khai và đích lưu trữ trước khi đóng gói baseline, `usecase-index.yaml`, `usecase-document.yaml`, nguồn Markdown và DOCX generated đã kiểm chứng. Không phát hành Word lock, ảnh render, file tạm, template nội bộ hoặc secret nếu chưa có quyết định riêng.

## Gate đang bật

Các gate sau đang chạy trong job `Validate documentation`:

- `python tools/validate_usecases.py --strict`.
- `python tools/check_usecase_impact.py --fail-on-unclassified`.
- `python tools/build_usecase_doc.py --check`.
- `plato_docs/generated/plato_usecases.docx` là bản Word đầu ra chính thức, được tạo từ Markdown/index/document metadata và template.
- Bản Word gốc chỉ dùng làm tham chiếu lịch sử tại `plato_docs/archive/usecase-reference-2026-08.docx`.

Sau khi các gate pass trên ít nhất hai pull request thực tế, branch protection có thể yêu cầu job `Validate documentation` trước khi merge. CD artifact vẫn chủ động tắt.
