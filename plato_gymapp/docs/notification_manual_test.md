# Notification manual test — Android / Pixel 6

## 1. Chuẩn bị

1. Bật USB debugging và kết nối điện thoại bằng cáp.
2. Chạy `adb devices`; thiết bị phải có trạng thái `device`.
3. Build và cài bản thường, giữ nguyên dữ liệu hiện có:

   ```powershell
   flutter build apk --debug
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

4. Mở Plato ít nhất một lần và cho phép notification. Không cấp quyền báo thức chính xác; hệ thống không cần quyền này.

## 2. Mở trang chẩn đoán ẩn

1. Mở **Profile → Settings**.
2. Chạm liên tiếp **7 lần** vào hàng **Version**. Mỗi lần chạm không cách nhau quá 5 giây.
3. Trang **Notification diagnostics** phải mở ra.
4. Xác nhận:
   - System permission là **Allowed**.
   - Last schedule refresh có thời gian gần hiện tại.
   - Last background refresh có dữ liệu sau khi worker đã chạy; `Never` vẫn hợp lệ ngay sau lần cài đầu tiên.
   - Pending OS reminders lớn hơn 0 nếu có notification đủ điều kiện.
   - Suppressed reminders giải thích các trường hợp master/category bị tắt, đạt mục tiêu nước, đang tập, bị gộp vào lịch tập hoặc chạm giới hạn ngày.

## 3. Smoke test notification

1. Trong Diagnostics, chọn **Show test now**.
2. Kỳ vọng: notification xuất hiện, rung một nhịp và không phát âm thanh.
3. Chọn **Schedule a test**, bấm Home rồi vuốt Plato khỏi Recent Apps.
4. Khóa màn hình và đợi ít nhất 2–3 phút vì Android dùng lịch inexact.
5. Kỳ vọng: notification thử vẫn xuất hiện. Chạm notification hoặc CTA phải mở Plato đúng route.

Có thể thu thập bằng chứng trước và sau khi đợi:

```powershell
powershell -ExecutionPolicy Bypass -File tool/notification_manual_test.ps1 -WaitSeconds 180
```

Để mô phỏng process bị Android thu hồi mà không dùng Force stop:

```powershell
powershell -ExecutionPolicy Bypass -File tool/notification_manual_test.ps1 -WaitSeconds 180 -KillAppProcess
```

Script lưu permission, alarm, notification, WorkManager, Doze và logcat vào `build/notification-manual-test/<timestamp>`. Không dùng `am force-stop` và không xóa dữ liệu.

## 4. Scheduled Workout Reminder

1. Trong Calendar, tạo workout cách hiện tại ít nhất 35 phút và chọn nhắc trước 30 phút.
2. Kiểm tra Diagnostics: pending count tăng sau khi rebuild.
3. Bấm Home, vuốt app khỏi Recent Apps và khóa máy.
4. Kỳ vọng: reminder xuất hiện quanh thời điểm đã chọn; Android có thể trễ vài phút. Nội dung có routine, giờ tập và recovery nếu có dữ liệu phù hợp.
5. Chạm CTA **View schedule**: Calendar phải mở đúng schedule.
6. Tạo năm lịch có reminder cùng ngày giao nhận: hộp thoại phải báo giới hạn bốn reminder. Sau khi xác nhận, cả năm lịch vẫn được lưu nhưng occurrence thứ năm có reminder tắt; các occurrence của chuỗi lặp ở ngày khác vẫn giữ reminder.
7. Sau khi một reminder trong hôm nay đã quá giờ, mở Notification Settings: số đếm chỉ gồm các reminder còn lại trong hôm nay và không cộng lịch của ngày/tuần sau.

## 5. Hydration

1. Bật Water reminder từ Water Tracker; toggle tương ứng trong Notification Settings phải đổi theo.
2. Trước 16:00, để lượng nước dưới target và chọn rebuild.
3. Kỳ vọng: có một reminder 16:00. Nội dung phải khác nhau ở mức 0%, dưới 50% và trên 50%.
4. Đạt target trước 16:00 rồi rebuild: reminder hôm nay biến mất, reminder các ngày sau vẫn còn.
5. Tắt category Water trong Settings: Water Tracker phải phản ánh cùng trạng thái.

## 6. Recovery và routine recommendation

1. Cần ít nhất một workout đã hoàn thành có dữ liệu cơ hợp lệ.
2. Mở Workout screen và kiểm tra Recovery Bar Chart, phần trăm, trạng thái và thời gian dự kiến của sáu nhóm cơ.
3. Khi cả sáu nhóm đều dưới 40% (đỏ), phần bên dưới chart phải khuyên nghỉ hôm nay và không được hiện routine hay CTA chọn buổi tập.
4. Khi không nhóm nào xanh nhưng vẫn có nhóm từ 40–79%, kỳ vọng tối đa hai routine gần sẵn sàng nhất; routine đỏ phải có cảnh báo rõ ràng.
5. Với full-body routine có một trong sáu nhóm đỏ và năm nhóm còn lại xanh, kỳ vọng card xanh có điều chỉnh và nội dung khuyên bỏ hoặc giảm các bài liên quan. Khi phần đỏ vượt adjustment budget 20%, routine phải chuyển sang vàng.
6. Khi phần Muscle Split đỏ đạt 40%, red severity đạt 30 điểm, hoặc một nhóm chiếm ít nhất 30% nhưng recovery dưới 20%, kỳ vọng routine chuyển sang đỏ. Khi recovery tăng, trạng thái chỉ được tốt dần và không xuất hiện trạng thái vàng có điều chỉnh.
7. So sánh một routine có 5% cơ phụ đỏ với routine có 20% cơ đỏ. Cơ phụ 5% không được kéo thứ hạng xuống như một nhóm chính; routine 20% phải nhận lower-tail penalty rõ ràng hơn.
8. Với routine vàng, thời gian sẵn sàng phải là lúc chính routine chuyển sang xanh/xanh có điều chỉnh, không cần chờ mọi nhóm target đạt 80%. Card phải tự cập nhật tại thời điểm này mà không cần rời màn hình.
9. Tạo hai routine có Muscle Split gần giống nhau; kỳ vọng chỉ một routine xuất hiện trong hai card. Tạo thêm một routine khác biệt để xác nhận card thứ hai trở lại.
10. Khi có routine xanh, kỳ vọng tối đa hai ô: một routine phù hợp và, nếu có, một routine nên tránh. Nếu tất cả routine đều xanh, chỉ hiện hai routine ưu tiên cao nhất.
11. Tạo lịch sử 30 ngày lệch về một nhóm cơ rồi để hai routine có recovery gần ngang nhau. Routine nhắm vào nhóm cơ được tập ít hơn phải được ưu tiên; Training Balance không được đổi thứ tự an toàn xanh/vàng/đỏ.
12. Với một routine, chỉ hiện một ô và một ghi chú khuyên bổ sung routine. Nếu routine đó không phù hợp nhưng vẫn còn nhóm cơ xanh, ghi chú phải nêu các nhóm cơ này. Xóa toàn bộ routine, phần recommendation phải biến mất hoàn toàn.
13. Mở một routine xanh và xác nhận có status cho biết routine phù hợp với recovery hiện tại.
14. Từ routine A không phù hợp, mở Alternative Routine B rồi quay lại. Màn A chỉ được hiện B như alternative; không được biến thành danh sách tổng quan chứa cả A và B. Trong trạng thái cả sáu nhóm đỏ, không được đề xuất alternative.
15. Khi cả sáu nhóm đã sẵn sàng và history không đổi, notification recovery ngày kế tiếp phải được suppress.
16. Alternative/Recovery Routine chỉ xuất hiện khi đang xem routine thuộc user. Chuyển sang Edit, mở Create Routine hoặc đang lưu/chỉnh sửa phải ẩn khối này; quay lại View mới hiện lại.
17. Routine không có exercise phải ẩn hoàn toàn Muscle Split. Thêm exercise phải làm Muscle Split xuất hiện; nếu có cả Alternative Routine, giữa hai khối phải có khoảng cách rõ ràng và không dính viền.
18. Với dữ liệu thời gian có thể kiểm soát, kiểm tra vùng xanh 80–100: thời gian 80→90 phải xấp xỉ 90→100, thời gian 95→100 bằng khoảng một nửa 90→100, và thanh phải đạt đúng 100 thay vì dừng lâu ở 97–99%.

## 7. Streak, Rank và Long Inactivity

- Streak: kiểm tra vào Chủ nhật trước 08:00 với streak đang sống nhưng tuần hiện tại chưa có qualifying workout. Kỳ vọng reminder 08:00; nếu ngày đó đông notification, reminder có thể chuyển sang thứ Bảy 19:00.
- Rank: khi cycle còn ba ngày, kỳ vọng reminder 10:00. Nếu D-3 đông, nó được chuyển sang D-4 hoặc D-5.
- Long Inactivity: sau khi mở app, ledger phải chuẩn bị reminder 20:00 của ngày thứ 14. Mở lại app trước thời điểm đó phải dời mốc 14 ngày. Loại này không có toggle riêng.

Không nên đổi ngày hệ thống trên máy đang dùng thật để ép các case này vì có thể ảnh hưởng workout history và dữ liệu đồng bộ. Các nhánh thời gian đã được kiểm tra bằng unit test; test thủ công nên thực hiện trên máy phụ hoặc emulator nếu cần time travel.

## 8. Permission, reboot và timezone

1. Tắt master switch: toàn bộ Plato OS reminder bị hủy và bốn category Water/Recovery/Streak/Rank đều hiển thị tắt. Bật lại master phải khôi phục lựa chọn category trước đó.
2. Khi master đang tắt, bật riêng một category: app yêu cầu notification permission khi cần, master tự bật và category vừa chọn giữ trạng thái bật.
3. Tắt từng category, kể cả category cuối cùng: master vẫn bật vì Scheduled Workout và Long Inactivity còn phụ thuộc vào master.
4. Bật **Chạy dưới nền**, sau đó tắt master: toggle chạy nền phải giữ nguyên. Tắt chạy nền phải dừng foreground workout service nhưng không thay đổi master/category notification.
5. Chặn permission trong Android Settings rồi quay lại Plato: master, bốn category và **Chạy dưới nền** phải tự tắt; foreground workout service phải dừng. Hàng quyền hệ thống và Diagnostics phải báo `Blocked by your device`.
6. Cho phép lại, mở app và rebuild.
7. Khởi động lại điện thoại. Không mở Plato ngay; đợi một scheduled test hoặc workout reminder.
8. Đổi timezone, mở app và rebuild. Workout giữ timezone đã chọn; Water/Streak/Rank/Inactivity dùng timezone hiện tại sau refresh.
9. Bật/tắt nhanh master và từng category: switch phải đổi trạng thái ngay, master/category liên quan đổi cùng frame và không chờ màn hình refresh lịch. Subtitle tại Settings phải hiện câu đếm đã localization, ví dụ `Đã bật 3 thông báo`.

## 9. Tiêu chí đạt

- Notification vẫn xuất hiện khi app chỉ bị đóng/vuốt khỏi Recent Apps hoặc process bị `am kill`.
- Không yêu cầu exact alarm, audio hoặc permission ngoài notification cho reminder thường.
- Không quá bốn OS notification trong một ngày.
- Rung một nhịp, không có âm thanh.
- CTA và chạm toàn notification mở đúng màn hình khi foreground, background và cold start.
- Diagnostics không có background error; suppression reason phù hợp với dữ liệu.
- Không có reminder trùng sau khi mở app, reboot hoặc rebuild nhiều lần.

Force stop từ Android Settings là trạng thái đặc biệt: Android chặn alarm và background work cho đến khi người dùng tự mở lại app. Case đó không thuộc tiêu chí closed-app delivery.
