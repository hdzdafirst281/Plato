# Baseline - 2026-10-28

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

- Tài liệu Word ban đầu có 31 Use Case, từ UC01 đến UC31; sau khi bản generated vượt qua đối chiếu nội dung và render, file gốc được lưu tại `plato_docs/archive/usecase-reference-2026-08.docx`.
- Nguồn Markdown có đủ 31 Use Case và `plato_docs/usecase-index.yaml` đã lập mapping cho toàn bộ UC01-UC31.
- Markdown, index và `plato_docs/usecase-document.yaml` hiện là source of truth; `plato_docs/templates/usecase-template.docx` giữ cấu trúc/định dạng Word chuẩn.
- `tools/build_usecase_doc.py` tạo lại `plato_docs/generated/plato_usecases.docx` theo cách ổn định: 7 nhóm, bảng thuật ngữ và 31 bảng chi tiết.
- DOCX generated đã được kiểm tra tái tạo byte-for-byte và kiểm tra trực quan toàn bộ 88 trang, gồm 39 bảng; mỗi bảng Use Case có 14 hàng sau khi bổ sung Business Rules và Terminology.
- Bản Use Case gốc được giữ tại `plato_docs/archive/usecase-reference-2026-08.docx`; bản tài liệu công thức duy nhất còn sót trong vùng tạm được bảo toàn tại `plato_docs/archive/plato-calculation-reference-2026-10.docx` để truy vết.
- Baseline 2026-08 cùng kế hoạch/hướng dẫn migration cũ đã được loại khỏi worktree sau khi hoàn tất; khi cần vẫn có thể khôi phục từ Git history.
- Đã có `tools/check_usecase_impact.py`, `tools/validate_usecases.py`, generator DOCX và unit test cho tooling.
- CI workflow `.github/workflows/plato-docs.yml` đã bật strict validator, kiểm tra DOCX không stale và chặn file nghiệp vụ chưa được phân loại.
- Chưa bật Git hook hoặc CD upload/phát hành tài liệu.

## Word lock

- Các Word lock cũ đã được dọn sau khi xác nhận không có tiến trình Word và các tài liệu không bị giữ mở.
- Word lock mới vẫn được Git ignore; chỉ xóa sau khi xác nhận tài liệu tương ứng đã đóng.

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
- DOCX được xuất PDF bằng Microsoft Word và render bằng Poppler để kiểm tra trực quan toàn bộ 88 trang; không phát hiện trang trắng, chữ bị cắt, chồng lấn, mất viền bảng hoặc lỗi dấu tiếng Việt.

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

## Kết quả đối chiếu code và Use Case ngày 2026-10-28

- Notification đã được phân loại theo nghiệp vụ: lịch tập ở UC14, recovery ở UC18, nước ở UC23, streak/quest ở UC25, Rank ở UC27; chính sách điều phối, quyền OS, notification preference và chạy nền workout nằm ở UC31.
- Năm nhóm đơn vị đo độc lập và phạm vi đồng bộ `measurement_units` được bổ sung vào UC28.
- Workout settings, Workout Rewards, tự nhận quest/mở rương và thứ tự mở Session Summary được cập nhật ở UC15, UC16 và UC25.
- Diet, allergen, ingredients và cảnh báo an toàn dinh dưỡng được cập nhật ở UC01 và UC20-UC22.
- Avatar Supabase Storage, ảnh leaderboard, đồng bộ Routine và giới hạn 10 Routine được cập nhật ở UC07, UC12 và UC26 cùng các luồng tài khoản liên quan.
- Công thức BMI/BMR/TDEE/macro và phục hồi nhóm cơ được đối chiếu code và cập nhật ở UC08, UC18; heatmap theo giới tính được cập nhật ở UC16 và UC19.
- Đợt rà soát cuối đã bổ sung điều kiện streak theo tuần ở UC14; ngưỡng cảnh báo tạ, volume, PR và XP workout ở UC15/UC17/UC25; cửa sổ tải 28 ngày với bán rã 14 ngày ở UC18; mốc chuẩn hóa cân bằng/heatmap ở UC19; giới hạn 40 RP/ngày và ngưỡng từng Rank ở UC27.
- Không tìm thấy backend artifact trong repository chứng minh việc tự dọn email ở trạng thái chờ xác thực sau hai giờ, nên hành vi này chưa được ghi là đã triển khai.
- I04 chưa có code tương ứng; U01 và U04 chỉ thay đổi trình bày/icon, không làm thay đổi mục tiêu hay luồng nghiệp vụ của Use Case.
- Lựa chọn “Thông báo buổi tập” trong Settings đã được xác định là quyết định ưu tiên: mọi thao tác bật/tắt ghi nhận `hasAskedPrePermission`, lần bắt đầu workout không tự hỏi hoặc tự bật lại tính năng, và nhãn từ chối được đổi thành “Không bật”.

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
- [x] Quyết định và triển khai hành vi của cờ `hasAskedPrePermission` khi người dùng thao tác trong Settings.
- [x] Xác nhận Dart analyzer toàn project có thể hoàn tất và ghi nhận 18 diagnostic hiện tại.
- [ ] Chẩn đoán Flutter wrapper và xử lý các diagnostic để `flutter analyze --no-pub` pass.
- [x] Viết validator và impact scanner tối thiểu cho các Use Case đã migrate.
- [x] Thêm CI workflow và Pull Request template cho Plato Docs.
- [x] Xác nhận repository hiện là public.
- [ ] CD upload/phát hành được chủ động hoãn; xác nhận lại phạm vi và đích lưu trữ khi phát sinh nhu cầu.
