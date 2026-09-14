# Kiểm tra Workout Rewards — 14/09/2026

Màn hình ban đầu chưa hoàn chỉnh về đồng bộ dữ liệu và trạng thái tương tác. Bản sửa đã xử lý các lỗi luồng hiển thị/lưu PR–XP xác định được và thiết kế lại UI. Tầng ghi thưởng bền vững vẫn cần cải thiện trước khi có thể cam kết chống cộng thiếu/lặp qua crash hoặc nhiều thiết bị.

## Thiết kế theo phác thảo mới

Thiết kế này thay thế phần header, danh sách dài và animation fade chung trong các phiên bản trước.

- Thứ tự: chuỗi tuần vừa tăng (nếu có) → lưới 6 quest → rương tuần → XP → RP.
- Timeline bắt đầu sau khi route đã hiển thị. Mỗi phần có 240 ms xuất hiện, tiếp theo là 560 ms cập nhật progress; các phần đi lần lượt.
- Quest lấy tiến độ trước khi lưu buổi tập; XP nội suy theo tổng điểm để đi qua mốc lên cấp; RP lấy số set hợp lệ của buổi tập trong mùa.
- Chạm màn hình hoàn tất hiệu ứng; lần chạm này không đồng thời nhận thưởng hoặc điều hướng. Bỏ nút skip riêng.
- Badge rank dùng asset hiện có. Thanh RP có các vùng theo ngưỡng thật: dưới maintain → rớt, maintain đến promote → giữ, từ promote → thăng. Đồng I không rớt; Diamond không thăng thêm.
- Bình thường các phần nằm trong một màn hình. Chỉ chữ trợ năng lớn hoặc cửa sổ thấp dưới 500 px mới cho cuộn để tránh cắt nội dung.
- Phần breakdown XP dài được bỏ khỏi giao diện để ưu tiên độ gọn theo phác thảo mới.

## Cập nhật tiếp theo — phạm vi gọn

- Đã thêm XP breakdown (hoàn thành/PR) khi khớp số XP đã lưu; không suy đoán breakdown cho dữ liệu cũ lệch công thức.
- Đã thêm rương tuần ngay trên reward: tiến độ 5 quest, nhận 1500 XP, đang nhận/đã nhận; dùng chung khóa thao tác với quest.
- Gom mức thưởng và điều kiện rương thành hằng số dùng chung với repository.
- Thanh tiến độ cập nhật trong 260 ms, tôn trọng giảm chuyển động; hiện tổng RP ở hạng cao nhất.
- Mở lại buổi tập cũ không tự báo lên cấp từ tổng XP hiện tại. Snapshot bền vững theo session vẫn là đề xuất.
- Bộ test reward: 19 passed. Các hạng mục P1 về transaction/phục hồi khi crash và chống lặp đa thiết bị chưa được triển khai trong lượt này.

## Luồng sau khi sửa

1. Khi kết thúc buổi tập, mở reward ngay với trạng thái đang lưu và truyền Future của thao tác lưu vào route.
2. Repository đánh giá PR, tính tổng và tính XP trước một lần ghi workout. Không phát ra bản ghi trung gian có XP = 0. Khi lưu lại, bỏ chính session đó và các session đã xóa khỏi tập so sánh PR.
3. ActiveSessionCubit cập nhật XP/RP/profile; sau đó ghi event thành tích. Các yêu cầu hoàn tất đồng thời cho cùng session dùng chung Future.
4. Reward chờ Future hoàn tất, nhận session cuối cùng trực tiếp, refresh quest/XP/rank rồi hiển thị. Không khóa vào history emission đầu tiên.
5. XP từ workout hiển thị riêng; thanh cấp phản ánh tổng XP hiện tại. Nhận quest sẽ cập nhật state và tiến độ cấp.
6. Quest hoàn thành có nút Nhận +XP, trạng thái đang xử lý, đã nhận và thông báo lỗi. Tiếp tục không phụ thuộc animation hoặc timer nhận thưởng. Quest chưa nhận vẫn có thể nhận ở màn gamification.
7. RP buổi tập đếm các set hoàn thành thuộc mùa hiện tại. Thanh hạng hiển thị ngưỡng thăng hạng; hạng cao nhất dùng ngưỡng giữ hạng thay cho 99999. Giải thích rõ hạng xét cuối mùa 45 ngày.

## Các vấn đề đã sửa

| Vấn đề cũ | Ảnh hưởng | Thay đổi |
|---|---|---|
| `_session` chốt từ history emission đầu tiên, trong khi workout lưu hai lần | Có thể giữ XP = 0 và dữ liệu chưa hoàn tất | Truyền completion Future, chờ kết quả cuối; một lần lưu PR/XP |
| Lần lưu thứ hai so PR với chính buổi tập vừa lưu | PR trong lịch sử có thể mất dù XP đã chứa bonus | Tính XP từ session đã đánh giá PR trước ghi; loại session hiện tại khỏi lịch sử so sánh |
| Đọc Gamification/Rank bằng `read` một lần | Điểm/hạng/quest không cập nhật sau save hoặc claim | Refresh sau completion và BlocBuilder cho state sống |
| Tự nhận tất cả quest sau 3 giây với `mounted` | Rời sớm không nhận; thao tác ẩn; có thể nhiều claim chồng nhau | Nút nhận rõ ràng, loading/error/claimed; tuần tự hóa refresh và claim trong GamificationCubit |
| RP cũ bằng RP mới; hạng cao nhất chia 99999 | Hiệu ứng không thể hiện phần tăng; thanh tiến độ gây hiểu nhầm | Hiện đóng góp RP của session và mục tiêu rank thích hợp |
| Không có trạng thái lỗi khi thiếu session hoặc save thất bại | Spinner vô hạn, người dùng không biết cách thoát | Trạng thái lỗi có đường về workout; khi đang lưu vẫn có thể rời màn hình |
| Nhiều blur, scale elastic 1–3 giây, CTA xuất hiện muộn | Nhiễu thị giác và trì hoãn thao tác | Fade/slide 420 ms, một controller; CTA dùng được ngay; hỗ trợ giảm chuyển động |
| Column cố định và list cuộn lồng | Tràn trên màn hình nhỏ/chữ lớn | Một vùng cuộn, nội dung tối đa 560 px, nút đáy SafeArea, Wrap/Expanded cho chữ |
| Nền đen và màu chữ không theo cặp theme | Chế độ sáng không nhất quán | Dùng surface/text/primary của theme Plato; dịch Việt–Anh |

## Đề xuất tiếp theo, theo ưu tiên

### P1 — Ghi thưởng bền vững và có thể phục hồi

`ClaimQuestRewardUseCase.execute` ghi claim trước, rồi mới `saveProfile`. Nếu bước thứ hai thất bại, ledger đã đánh dấu nhận nhưng profile chưa có XP. `finishWorkout` cũng ghi workout và profile theo các thao tác riêng; khóa Future chỉ chống yêu cầu đồng thời, không chống phát lại sau khi tiến trình khởi động lại.

Nên đưa operation thưởng vào SQLite transaction với khóa theo tài khoản/session/loại thưởng và trạng thái pending/applied. Tính hoặc đối soát XP profile từ workout + ledger, thay vì chỉ cộng vào giá trị cache. Có quy trình phục hồi khi khởi động. Đối với claim/revoke/reclaim, cần revision để nhận lại hợp lệ sau khi điều kiện được khôi phục.

### P1 — Chống nhận lặp giữa thiết bị

`RewardClaimEntity` hiện dùng UUID ngẫu nhiên làm khóa chính; `RewardClaimDao.insertClaim` chỉ xử lý xung đột theo UUID. Hai thiết bị có thể tạo hai UUID cho cùng quyền nhận thưởng. Hàng đợi Cubit không xử lý được trường hợp này.

Nên kiểm tra và cấp quyền nhận ở backend bằng transaction/RPC, khóa nghiệp vụ theo account + nguồn thưởng + kỳ + revision; đồng bộ operation ID ổn định. Cần xem schema/RPC thực tế trước khi thay đổi vì review này chưa xác minh backend đang triển khai.

### P2 — Snapshot thưởng theo session

Lưu `xpBefore/xpAfter`, `levelBefore/levelAfter`, `rpBefore/rpAfter`, mùa và quest delta vào kết quả hoàn tất. Hiện màn hình dùng session cuối và tổng điểm hiện tại; suy ra lên cấp là phù hợp khi vừa hoàn tất, nhưng mở lại session cũ sau nhiều thay đổi XP không thể tái hiện chính xác khoảnh khắc đó. Snapshot cũng cho phép animate qua nhiều cấp mà không đoán lại lịch sử.

### P2 — Hoàn thiện cơ chế động lực

- Hiện breakdown “50 XP hoàn thành + 20 XP mỗi PR” và tách XP quest; tránh người dùng nghĩ toàn bộ tổng điểm là thưởng của riêng buổi này.
- Đánh dấu những quest vừa tiến triển trong buổi tập, thay vì mọi quest tuần đều có độ nổi bật như nhau.
- Thêm tiến độ mở rương tuần và lối tới gamification để nhận rương, dùng điều kiện hiện có là 5 quest hoàn thành.
- Chốt chính sách đầu tuần/múi giờ. `_getWeekKey` hiện dùng UTC và cắt tuần theo năm; nên thêm test quanh giao thừa và Chủ nhật/Thứ hai trước khi chuyển sang tuần ISO hay múi giờ địa phương.

## Kiểm chứng

- Flutter analyzer: không có issues trong 7 file production thuộc phạm vi sửa và thư mục test gamification.
- `flutter test --no-pub test/features/gamification test/features/notifications --dart-define=REWARD_PREVIEWS=true`: **51 tests passed** (16 reward và 35 notification).
- Regression: PR/XP nhất quán lần ghi đầu, lưu lại giữ PR, biên cấp 999/1000/2050/2100 XP, claim–refresh–claim chỉ cộng một lần.
- Widget: chờ completion dù history đã có bản trung gian, rời màn hình lúc đang lưu, thiếu ID có thông báo lỗi, Future thất bại trước route mount, claim/claimed, target 0, hạng cao nhất, reduced motion, CTA trong lúc entrance.
- Layout: 320 × 568 với text scale 200%, cả Việt/Anh và sáng/tối; preview 390 × 844 với theme Plato và Material Symbols.
- Đã xem ảnh render sáng/tối. Preview dùng dữ liệu mẫu và font Arial thay Roboto trong test để render offline; không phải ảnh chụp tài khoản thật hay xác nhận hiệu năng thiết bị.
- Test persistence dùng SQLite trong bộ nhớ. SyncManager ghi log vì Supabase toàn cục không khởi tạo trong test; kiểm thử không xác minh đồng bộ cloud.
- Chưa đo frame time trên Android/iOS thật, chưa thử haptic/TalkBack/VoiceOver trên thiết bị và chưa thử mất kết nối giữa các bước ghi profile/ledger.

## File chính

- `lib/features/gamification/presentation/screens/workout_rewards_screen.dart`
- `lib/features/gamification/presentation/bloc/gamification_cubit.dart`
- `lib/features/gamification/presentation/bloc/rank_cubit.dart`
- `lib/features/workout/presentation/bloc/active_session_cubit.dart`
- `lib/features/workout/data/repositories/workout_repository.dart`
- `lib/features/workout/presentation/screens/log_workout_screen.dart`
- `lib/core/navigation/app_router.dart`
- `lib/i18n/strings_{en,vi}.i18n.json` và `strings.g.dart`
- `test/features/gamification/workout_rewards_screen_test.dart`
- `test/features/gamification/workout_reward_persistence_test.dart`

Ảnh preview cùng thư mục: `workout-rewards-dark.png`, `workout-rewards-light.png`.
