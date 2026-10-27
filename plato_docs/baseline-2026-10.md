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
- Repository được chủ sở hữu xác nhận là public.
- Từ `2026-09-01`, `plato_gymapp` có 21 commit và 239 đường dẫn file duy nhất xuất hiện trong lịch sử thay đổi.
- `plato_docs` không có commit nội dung sau `2026-08-31`.

## Tài liệu hiện hành

- Tài liệu Word ban đầu `plato_docs/usecase.docx` có 31 Use Case, từ UC01 đến UC31, và hiện được giữ làm snapshot tham chiếu.
- Nguồn Markdown có đủ 31 Use Case và `plato_docs/usecase-index.yaml` đã lập mapping cho toàn bộ UC01-UC31.
- Markdown và index hiện là source of truth; `tools/build_usecase_doc.py` tạo lại `plato_docs/generated/plato_usecases.docx` theo cách ổn định.
- DOCX generated đã được kiểm tra tái tạo byte-for-byte và kiểm tra trực quan đủ 67 trang.
- Đã có `tools/check_usecase_impact.py`, `tools/validate_usecases.py`, generator DOCX và unit test cho tooling.
- CI workflow `.github/workflows/plato-docs.yml` đã bật strict validator, kiểm tra DOCX không stale và chặn file nghiệp vụ chưa được phân loại.
- Chưa bật Git hook hoặc CD upload/phát hành tài liệu.

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
- Kết quả: `9` unit test pass.
- Validator strict có `0` lỗi và `0` cảnh báo.
- Impact scanner nhận mapping của đủ 31 Use Case và CI chặn file `plato_gymapp/lib/` hoặc nguồn Use Case chưa được phân loại.
- Generator tạo DOCX ổn định; `--check` xác nhận file generated đang đồng bộ với Markdown/index.
- DOCX được xuất PDF bằng Microsoft Word và render bằng Poppler để kiểm tra trực quan đủ 67/67 trang; không phát hiện chữ bị cắt, chồng lấn hoặc lỗi dấu tiếng Việt.

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
- [x] UC01, UC05, UC16, UC17 và UC30 được migrate theo cụm tài khoản và vòng đời buổi tập.
- [x] UC18 và UC19 được migrate theo cụm phục hồi và thống kê tập luyện.
- [x] UC02, UC07-UC09, UC11, UC12, UC14, UC20, UC23-UC25, UC27 và UC29 được migrate theo nhóm có nhiều dependency nhất.
- [x] Migrate 8 Use Case còn lại: UC03, UC04, UC10, UC13, UC21, UC22, UC26 và UC28.
- [x] Xây generator DOCX, kiểm chứng output và bật strict gate sau khi đủ 31/31 Use Case.
- [ ] Quyết định hành vi của cờ `hasAskedPrePermission` khi người dùng thao tác trong Settings.
- [x] Xác nhận Dart analyzer toàn project có thể hoàn tất và ghi nhận 18 diagnostic hiện tại.
- [ ] Chẩn đoán Flutter wrapper và xử lý các diagnostic để `flutter analyze --no-pub` pass.
- [x] Viết validator và impact scanner tối thiểu cho các Use Case đã migrate.
- [x] Thêm CI workflow và Pull Request template cho Plato Docs.
- [x] Xác nhận repository hiện là public.
- [ ] CD upload/phát hành được chủ động hoãn; xác nhận lại phạm vi và đích lưu trữ khi phát sinh nhu cầu.

