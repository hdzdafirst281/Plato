# Quy trình CI CD cho Plato Docs

## Mục tiêu

Quy trình kiểm tra nguồn Use Case trên mỗi pull request và chuẩn bị cho việc phát hành tài liệu sau khi thay đổi được hợp nhất vào `main`. Pipeline phản ánh đúng trạng thái migration hiện tại: UC06, UC15 và UC31 là batch pilot Markdown; 28 Use Case còn lại vẫn lấy nội dung từ `usecase.docx`.

## Kiểm tra cục bộ

Cài dependency cho tooling:

```powershell
python -m pip install --requirement tools/requirements.txt
```

Chạy test và validator:

```powershell
python -m unittest discover --start-directory tools/tests --pattern "test_*.py"
python tools/validate_usecases.py
```

Xem tác động của phần đã stage hoặc của branch hiện tại:

```powershell
python tools/check_usecase_impact.py --staged
python tools/check_usecase_impact.py --base main
```

## CI trên pull request

Workflow `.github/workflows/plato-docs.yml` chạy trên mọi pull request để status check luôn được tạo ổn định, kể cả khi sau này job được đặt làm required check. Job quality thực hiện:

1. Cài dependency Python đã pin.
2. Chạy unit test của tooling.
3. Validate cấu trúc, title, section, code path, localization key và quan hệ UC.
4. So sánh branch với base commit và ghi danh sách UC cần review vào GitHub Step Summary.

Impact report chưa chặn file `unclassified` vì index hiện mới có UC06, UC15 và UC31. Pull request phải dùng template để ghi rõ UC đã cập nhật hoặc lý do `reviewed-no-change`.

## Trạng thái CD

Repository hiện là public, nhưng CD artifact chưa cần bật ở giai đoạn này. Workflow chỉ kiểm tra tài liệu và không upload hoặc phát hành tài liệu sang GitHub Actions Artifact, GitHub Release hay dịch vụ ngoài.

Khi có nhu cầu phát hành, cần xác nhận lại phạm vi công khai và đích lưu trữ trước khi đóng gói baseline, `usecase-index.yaml`, nguồn Markdown và DOCX generated đã kiểm chứng. Không phát hành Word lock, ảnh render, file tạm hoặc secret.

## Gate chưa bật

Các gate sau chỉ được bật sau khi đủ UC01-UC31 ở dạng Markdown và generator đã được kiểm chứng:

- `python tools/validate_usecases.py --strict`.
- `python tools/check_usecase_impact.py --fail-on-unclassified`.
- `python tools/build_usecase_doc.py --check`.
- Phát hành `plato_docs/generated/plato_usecases.docx` thay cho `usecase.docx` thủ công.

Khi các gate này pass trên ít nhất hai pull request thực tế, branch protection có thể yêu cầu job `Validate documentation` trước khi merge.

