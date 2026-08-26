# Baseline - 2026-08-25

## Phạm vi

- Project root: `D:\Projects\Zenithas\Plato`
- Ứng dụng: `plato_gymapp`
- Tài liệu: `plato_docs`
- Git repository: Chưa khởi tạo tại thời điểm cập nhật baseline.
- Người thực hiện: Đỗ Hoàng Duy, Vòng Thế Phong

## Toolchain

| Công cụ | Phiên bản / đường dẫn | Trạng thái |
|---|---|---|
| Git | `2.45.1.windows.1` | PASS |
| Flutter | `3.41.6`, stable channel | PASS |
| Flutter framework | Revision `db50e20168` | PASS |
| Flutter engine | Hash `5cdd32777948fa7a648fac915f8da7120ac7e97a` | PASS |
| Dart SDK | `3.11.4 stable` | PASS |
| DevTools | `2.54.2` | PASS |
| Python | `3.14.7`, `D:\DevTools\Python\python.exe` | PASS |
| Python virtual environment | `D:\Projects\Zenithas\Plato\.venv` | PASS |

## Tài liệu hiện hành

- Use Case chính: `plato_docs/usecase.docx`
- Không có bản Use Case trung gian đang được duy trì.
- Kế hoạch Git-Code-Use Case: `plato_docs/ke_hoach_dong_bo_git_code_usecase_plato.docx`
- Hướng dẫn thực thi: `plato_docs/huong_dan_thuc_hien_git_code_usecase_plato.docx`

## Kiểm tra dependencies

### `flutter pub get`

- Trạng thái: PASS.
- Kết quả: Dependencies đã được resolve và tải thành công.
- Ghi chú: Có `111` package có phiên bản mới hơn nhưng không tương thích với dependency constraints hiện tại.
- Quyết định baseline: Không chạy `flutter pub upgrade` trong giai đoạn khởi tạo Git; giữ nguyên `pubspec.lock` để bảo toàn trạng thái hiện tại.

## Kiểm tra tĩnh

### `flutter analyze`

- Trạng thái: PASS.
- Kết quả: `No issues found!`
- Thời gian chạy: `42.9 giây`.

## Kiểm tra tự động

### `flutter test`

- Trạng thái: PASS.
- Kết quả: `3` test đã pass.
- Thời gian chạy: `13 giây`.

## Kiểm tra file cấu hình nhạy cảm

- `.env`: Có tại `plato_gymapp/.env`.
- Nội dung: Chứa cấu hình Supabase phía client, gồm URL và anonymous publishable key. Không ghi giá trị cấu hình vào tài liệu baseline hoặc commit.
- Trạng thái `.gitignore`: PASS. File `plato_gymapp/.gitignore` đã có quy tắc `.env` và `.env.*`.
- Xác minh bắt buộc sau khi Git được khởi tạo: chạy `git check-ignore -v plato_gymapp/.env` trước lần `git add` đầu tiên.

## Kết luận

- [x] Dependencies có thể tải thành công.
- [x] Toolchain chính đã sẵn sàng.
- [x] Python 3.14.7 và `.venv` đã sẵn sàng.
- [x] `flutter analyze` sạch.
- [x] `flutter test` pass toàn bộ 3 test hiện có.
- [x] Quy tắc ignore `.env` đã được thêm vào `.gitignore`.
- [ ] Cần xác minh `git check-ignore` trước Git baseline commit đầu tiên.
