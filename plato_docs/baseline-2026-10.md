# Baseline - 2026-10-27

## Phạm vi

- Project root: `D:\Projects\Zenithas\Plato`
- Ứng dụng chính: `plato_gymapp`
- Tài liệu nghiệp vụ: `plato_docs`
- Website giới thiệu: `plato_web`
- Git commit trước khi cập nhật baseline: `5e1974857098ba67c02013a1a19a35d050525aa5`
- Nhánh thực hiện: `codex/docs-rebaseline-uc31`

### Quyết định phạm vi tạm thời

- Bộ Use Case UC01-UC31 tiếp tục mô tả hành vi của `plato_gymapp`.
- `plato_web` chưa được đưa vào `usecase-index.yaml` vì hiện là website giới thiệu, thư viện bài tập và nội dung pháp lý, không phải một client thực hiện các luồng nghiệp vụ của ứng dụng.
- Thay đổi Điều khoản sử dụng, EULA, liên hệ hỗ trợ hoặc liên kết mạng xã hội trong `plato_web` phải được đối chiếu thủ công với UC29 cho đến khi có mapping riêng.

## Toolchain

| Công cụ | Phiên bản / đường dẫn | Trạng thái |
|---|---|---|
| Git | `2.45.1.windows.1` | PASS |
| Flutter | `3.41.6`, stable channel, revision `db50e20168` | Đọc từ Flutter cache metadata; lệnh `flutter --version` bị treo |
| Dart SDK | `3.11.4 stable` | Đọc từ Flutter cache metadata |
| DevTools | `2.54.2` | Đọc từ Flutter cache metadata |
| Python | `3.14.7`, `D:\DevTools\Python\python.exe` | PASS |

## Git và remote

- Worktree sạch trước khi tạo nhánh baseline.
- `main` trùng commit với `origin/main` tại thời điểm kiểm tra.
- Remote hiện tại: `https://github.com/hdzdafirst281/Plato.git`.
- Chưa xác minh được repository là private hay public vì GitHub CLI không có trên máy và tra cứu web công khai không cho kết quả kết luận.
- Từ `2026-09-01`, `plato_gymapp` có 21 commit và 239 đường dẫn file duy nhất xuất hiện trong lịch sử thay đổi.
- `plato_docs` không có commit nội dung sau `2026-08-31`.

## Tài liệu hiện hành

- Tài liệu Use Case dành cho người đọc hiện tại: `plato_docs/usecase.docx`.
- File Word có 31 Use Case, từ UC01 đến UC31.
- Nguồn Markdown hiện có UC06, UC15 và UC31.
- `plato_docs/usecase-index.yaml` hiện đã lập mapping cho UC06, UC15 và UC31.
- `plato_docs/templates/` và `plato_docs/generated/` đang trống.
- Đã có `tools/check_usecase_impact.py`, `tools/validate_usecases.py` và unit test cho batch pilot UC06, UC15, UC31.
- Đã có CI workflow `.github/workflows/plato-docs.yml`; chưa có `tools/build_usecase_doc.py`, Git hook hoặc CD upload/phát hành tài liệu.
- `usecase.docx` vẫn là nguồn nội dung chính cho 28 Use Case chưa migrate.
- Từ baseline này, Markdown và index là nguồn pilot hiện hành của UC06, UC15 và UC31; các phần tương ứng trong `usecase.docx` chỉ còn là snapshot tham chiếu cho tới khi có generator.
- Chỉ chuyển toàn bộ Markdown/YAML thành source of truth sau khi đủ 31 file nguồn và DOCX generated được kiểm tra tái tạo ổn định.

## Word lock

Các file lock sau đang tồn tại và được Git ignore:

- `plato_docs/~$ecase_revised_permissions.docx`
- `plato_docs/~$ong_dan_thuc_hien_git_code_usecase_plato.docx`
- `plato_docs/~$secase.docx`
- `~$ato_Cong_thuc_sau_cap_nhat_hoan_thien.docx`
- `~$ato_Cong_thuc_tinh_toan.docx`

Không xóa các file này tự động. Cần đóng Word và xác nhận file không còn được sử dụng trước khi dọn lock hoặc archive tài liệu.

## Kiểm tra file nhạy cảm

- `plato_gymapp/.env`: có trên máy, được ignore bởi `plato_gymapp/.gitignore`, không bị Git track.
- `plato_gymapp/android/app/upload-keystore.jks`: có trên máy, được ignore, không bị Git track.
- `plato_gymapp/android/key.properties`: có trên máy, được ignore, không bị Git track.
- Các bản sao `.env` trong `plato_gymapp/build/` nằm trong thư mục build đã được ignore.
- Không ghi giá trị secret, khóa ký hoặc mật khẩu vào baseline.

## Kiểm tra chất lượng hiện tại

### Plato Docs tooling

- Trạng thái: PASS.
- Kết quả: `8` unit test pass.
- Validator hiện có `0` lỗi và `6` cảnh báo dự kiến vì các UC liên quan chưa được migrate.
- Impact scanner nhận đúng các code path của UC06, UC15, UC31 và liệt kê file ứng dụng chưa được phân loại.

### `flutter test`

- Trạng thái: PASS.
- Kết quả: `108` test pass.
- Thời gian hiển thị bởi test runner: khoảng `1 phút 40 giây`.
- Phạm vi hiện có gồm design system, localization spacing, gamification, notification, recovery, profile và workout settings.

### `flutter analyze --no-pub`

- Trạng thái: INCOMPLETE.
- Flutter wrapper không in output và không hoàn tất trong 60 giây nên được dừng thủ công.
- Dart runtime hoạt động bình thường; phân tích một file hoàn tất và không có lỗi.
- Chạy trực tiếp Dart analyzer cho toàn bộ project hoàn tất sau khoảng 2 phút 20 giây với `18` vấn đề: `1` warning `dead_code` và `17` info về `use_build_context_synchronously` hoặc API `scale` đã deprecated.
- Source hiện không đạt analyzer sạch. Cần xử lý 18 diagnostic và chẩn đoán riêng vì sao Flutter wrapper dừng trước khi in `Analyzing plato_gymapp...`.

## Drift cần xử lý ở UC31

- Cài đặt chạy nền đã chuyển vào màn hình `Thông báo`; toggle hiện hiển thị là `Thông báo buổi tập`.
- Mapping cũ chưa bao phủ notification settings, notification coordinator, background service và lifecycle của active workout.
- Hai localization key cũ `desc_permission_denied` và `btn_open_settings` không tồn tại trong source hiện tại; ứng dụng dùng `settings.msg_permission_permanently_denied` và `common.open_settings`.
- Toggle trong màn hình Thông báo chưa ghi cờ `hasAskedPrePermission`. Vì vậy, nếu người dùng tắt toggle trước buổi tập đầu và quyền chưa được cấp, pre-permission dialog vẫn có thể xuất hiện khi bắt đầu buổi tập. Cần quyết định đây là hành vi mong muốn hay lỗi implementation trước khi sửa code hoặc Use Case theo hướng khác.
- Hệ thống notification mới còn có nhắc lịch tập, nước, recovery, streak và Rank. Các hành vi này cần được phân loại vào UC14, UC18, UC23, UC25, UC27 hoặc một Use Case mới trong giai đoạn migration; không mặc định gộp toàn bộ vào UC31.

## Cổng tiếp theo

- [x] Baseline Git và secret được kiểm tra lại.
- [x] Test suite hiện tại pass.
- [x] Drift chính của UC31 được nhận diện.
- [x] UC31 Markdown và index được cập nhật theo UI/code hiện tại.
- [x] UC06 và UC15 được migrate sang Markdown/index để hoàn chỉnh batch liên quan trực tiếp tới UC31.
- [ ] Quyết định hành vi của cờ `hasAskedPrePermission` khi người dùng thao tác trong Settings.
- [x] Xác nhận Dart analyzer toàn project có thể hoàn tất và ghi nhận 18 diagnostic hiện tại.
- [ ] Chẩn đoán Flutter wrapper và xử lý các diagnostic để `flutter analyze --no-pub` pass.
- [x] Viết validator và impact scanner tối thiểu cho batch pilot UC06, UC15, UC31.
- [x] Thêm CI workflow và Pull Request template cho Plato Docs.
- [x] Xác nhận repository hiện là public.
- [ ] CD upload/phát hành được chủ động hoãn; xác nhận lại phạm vi và đích lưu trữ khi phát sinh nhu cầu.

