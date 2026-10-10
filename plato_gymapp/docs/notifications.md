# Notifications: implementation and verification

## Delivery rules

- Workout: one reminder per timed schedule, 15/30/60 minutes before it. Date-only legacy schedules remain date-only with reminders off. Calendar supports setting a date/time, editing one occurrence, and starting its linked workout.
- No missed-workout notification.
- Water: opt-in, one candidate per day at 16:00, prepared up to 30 days ahead with each day's own logged intake and current target. No log / below 50% / below target use different Sheet copy; reaching the goal cancels the pending reminder. Conflicts are skipped, never moved later.
- Streak: prefers Sunday at 08:00 if the preceding streak is alive and the current week has no qualifying workout. It can move to Saturday at 19:00 when Sunday is crowded. A later scheduled workout that Sunday suppresses it.
- Rank: prefers three calendar days before the personal 45-day cycle ends at 10:00, once per cycle. It can move to D-4 or D-5 when D-3 is crowded, but never later than its deadline.
- Inactivity: once at 20:00 after at least 14 days since the app was last opened. It can move to day 15 or 16. Opening or resuming the app resets this reminder.
- Recovery: forecasts one logical reminder for a target day from the six major groups (chest, back, legs, shoulders, arms and core). Detailed muscles are combined by their recent effective load instead of allowing the lowest secondary muscle to dominate a major group. Recovery Bar, in-app recommendations and OS reminders share the normalized 0–100 scale and 40/80 boundaries. Below 80, the display preserves the normalized fatigue score. From 80 to 100, it advances linearly in exponential-decay time and reaches full recovery after one additional fatigue half-life; this gives the ready zone useful progression without exposing the mathematical tail toward zero fatigue. Major-group aggregation remains conservatively floored around the safety boundaries but rounds a weighted result of at least 99.5 to 100, preventing a negligible secondary component from pinning a group at 99. It normally delivers from 06:00–08:30, personalized from the median workout start time, and tells the user which groups are ready now or when another group should cross 80%. A previous-day 20:30 preview is available when the target morning is crowded and no late workout is planned. A scheduled workout receives recovery context even when the unchanged daily recovery reminder is suppressed. Once all six groups are ready, unchanged daily reminders pause until workout history changes.
- Daily ceiling: a soft ceiling of three leaves room for newly created reminders; the hard ceiling is four and is never a quota. Up to four user-authored workout reminders are kept for each delivery day. Calendar never blocks the workout itself: after confirmation, recurrence occurrences beyond that day's reminder capacity are saved with their reminder off, while occurrences on other days keep it. Automatic reminders do not consume workout-reminder capacity and move or suppress within their own delivery windows. At most 48 pending reminders are planned up to 30 days ahead.

Settings separates the Plato master switch from the device permission and exposes category switches for Water, Recovery, Streak and Rank. Turning the master off makes every category inactive while retaining the user's selections; turning it back on restores those selections. Enabling one category while the master is off enables only that category and the master after notification permission succeeds. Disabling the last category does not turn the master off because scheduled workouts and Long Inactivity still depend on it. The main Settings row shows the enabled category count out of these four switches. Its Workout reminders row counts only reminders still due on the current delivery day, so elapsed reminders and future weeks do not inflate the number. Water keeps its contextual switch and each workout keeps its own Calendar switch; both surfaces use the same stored preference. Scheduled workouts are managed from Calendar, while rare Long Inactivity reminders intentionally have no category switch. Notification authorization is the only notification-specific runtime permission. All reminders use inexact OS scheduling, so Android does not open the Alarms & reminders special-access screen. The Background Workout toggle is independent: it controls only the foreground service used while a workout is active and does not enable or disable reminder preferences. Both systems require the OS notification permission; revoking it makes the master and all four categories inactive, disables background workout at the next app reconciliation, and stops the foreground workout service when the main app is active.

## Data and in-app feedback

SQLite migration 6→7 preserves existing schedules, adds their time, timezone, reminder preference/lead time and completed workout linkage, and adds a notification ledger. The ledger records scheduling intent before contacting the OS and deduplicates events across reopening. Reset/logout cancels owned notifications and rotates the payload scope so another account cannot follow stale links.

In-app feedback reuses `GymTopNotification` with a completion-aware queue. Events are marked shown only after a banner was inserted and dismissed, then the next stored event drains automatically. An interrupted presentation can be shown again after restart. The banner has a visible close action and contextual CTA, live-region semantics, reduced motion support and non-disruptive haptics. Streak/workout achievements are merged with workout feedback; the rewards screen acknowledges them only after at least half of the inline card is visible. Hydration completion stays inline on the Water card. Rank cycle results use a dialog with the resulting badge and promotion/maintained/demotion tone. Recovery recommendations cache the forecast service by history revision, evaluate state transitions without polling, and use the same 40/80 scale as the Recovery Bar and OS reminders. Muscle Split uses completed/planned working sets with a 3:1 primary-to-secondary ratio, deduplicates secondary muscles in the same major group and never invents equal coverage for an empty routine. Routine risk combines exposure and severity: 20% is the adjustment budget, 40% red exposure is the hard routine limit, a severity equivalent to 30% fully exhausted work is also red, and a major target occupying at least 30% becomes critical below 20% recovery. A continuous wait-severity score measures every non-green target's distance from 80%, so crossing from 39% red to 40% yellow can never make a routine's state worse. There is no adjusted-yellow state. Within one safety state, ranking uses 80% weighted recovery and a 20% exposure-weighted lower-tail percentile, so a tiny secondary muscle cannot dominate the score. Recommendations show at most two structurally distinct routines: the best ready option first, followed by the most dangerous red warning, then yellow when no red warning exists. Similar six-group splits collapse to one display option. Green groups with no meaningful safe coverage receive a routine note, and a single distinct option receives the diversification note. Training balance uses 28 days of exponentially decayed completed working sets, a median baseline and a data-sufficiency gate; it remains a bounded tie breaker and cannot override recovery safety. A yellow routine's ready time is the first minute when the whole routine becomes ready or ready-with-adjustments, rather than the time every target reaches 80%. Alternative routines must be structurally different and materially safer. Opening one preserves and restores the source routine when the nested screen closes.

## Local scheduling limits

The OS stores and delivers the alarms even after the app process exits. Opening Calendar or Water no longer cancels the day's future requests, and initialization/lifecycle refresh no longer depends on a 400 ms Dart timer. Notification wall-clock scheduling uses the device clock rather than a cached server/uptime offset that may be stale after reboot.

A Workmanager task (`vn.zenithas.plato.reminder_refresh`) requests a refresh every six hours, without a network constraint. It restores locale/profile/data locally and replenishes the rolling 30-day plan with at most 48 pending requests. It does not depend on an authenticated Supabase session or server availability. Android persists periodic work; iOS has BGAppRefresh registration and decides when to grant runtime. The pre-scheduled requests remain useful when a refresh is delayed. Thirty days is the planning horizon, not a promise that 30 full days fit when many workouts consume the finite OS queue.

The headless engine uses a separate SQLite connection so closing it cannot close the foreground database. A renewable SQLite lease serializes OS reconciliation across engines; a persistent reset flag prevents background scheduling during account clearing. The plugin resolves the live IANA timezone in either engine. Settings includes a diagnostics screen with refresh time, worker time, pending OS count, reconcile duration, suppression reasons, schedule rebuild and immediate/delayed test actions. The local ledger also records due, best-effort active observation and taps; OS-level delivery confirmation is not available consistently across platforms.

All reminders use `inexactAllowWhileIdle` and can be delayed by Doze. The single `plato_reminders_v2` channel disables sound and requests one short vibration; changing to a new channel ID is required because Android channel behavior is immutable after creation. The notification permission and channel must be enabled. Force-stop, revoked permissions, a powered-off phone, or OS restrictions cannot be overridden. iOS can withhold background refresh after prolonged inactivity; indefinite remote reminders would require a separately configured APNs/FCM backend. This implementation does not claim such a backend is deployed.

Workouts retain their selected IANA timezone. Streak, water, rank and inactivity reminders use the device timezone at the last refresh. Cross-device changes only affect this device after the existing data sync downloads them; the reminder worker itself does not fetch server data.

## Regression checks for closed-app delivery

- Schedule tomorrow's 10:00 workout with 30-minute lead time, leave Calendar open, press Home and swipe away normally: the OS request for 09:30 must remain.
- On Pixel, allow notifications, leave the phone locked and account for Android's inexact timing window.
- Reach today's water target: today's pending request disappears, tomorrow's 16:00 request remains. Start the app after 16:00: no replay for today, future dates remain scheduled.
- Run `tool/notification_device_probe.dart` explicitly on a development device. It schedules only ID 99999 (outside production IDs). Press Home and use `adb shell am kill vn.zenithas.plato`, not force-stop; verify the OS notification arrives after process exit. Re-run with `--dart-define=PROBE_CLEANUP=true` to cancel the probe, then restore the normal app entry point.
- Use `adb shell dumpsys jobscheduler` to find the reminder worker, trigger its job with `cmd jobscheduler run -f`, and check the reminder diagnostic preferences. Do not clear app data to test this.

## Manual device checks before release

1. Upgrade a database with old schedules: no invented time or enabled reminders; dates and recurrence groups remain intact.
2. Create/edit a timed occurrence; verify 15/30/60-minute lead time, cancellation, and that editing/deleting one recurrence group leaves another group of the same routine intact.
3. Tap a workout notification from background and cold start: open the correct calendar date; start and finish its workout, then verify schedule completion and no duplicate reminder.
4. Before 16:00, test water at 0%, 25%, 75%, 100%; check content/cancellation. Tap opens the water section. After 16:00, reopening must not replay today's reminder.
5. Disable the common switch, revoke OS permission, re-enable, reboot, and change timezone. Confirm owned reminders reconcile without affecting ongoing-workout notification 8888.
6. Exercise the fixed four-per-day ceiling, competing workout/water/recovery times, and active-workout suppression. Verify late user-selected workout reminders are not filtered.
7. Finish multiple workouts in one week, reach a milestone, complete water twice after an undo, and reopen: no duplicate celebrations. Hidden tabs must not consume visible feedback.
8. Advance a personal rank cycle; verify promotion versus maintained/demoted rendering. Sign out while work is queued; no previous-account notification should remain.

Android/iOS delivery and tap behavior require physical devices or emulators. Windows cannot build the iOS target.

## Verification performed

### Current workspace, 2026-10-10

- The full 60-test suite covers personalized forecast-at-start-of-day recovery, previous-evening delivery, stable all-ready suppression, recovery/workout merging, adjusted-ready scheduled workouts, rank movement across days, per-occurrence four-workout reminder allocation, localization cleanup, hydration, streak/rank/inactivity, 39/40/79/80 recovery boundaries, finite 80–100 recovery progression, 20/30/40 routine-risk boundaries, red/wait severity, dominant critical muscles, exposure-weighted lower-tail ranking, routine-level ready time, Muscle Split deduplication, both locales, OS actions, preference isolation and sequential in-app banner delivery at large text scale.
- Android API 34 emulator: probe ID 99999 scheduled for 14:37:13 device local time, `exact=true`, `pending=true`; `dumpsys alarm` confirmed `window=0`, `exactAllowReason=permission`.
- Returned Home and killed only the probe/worker Linux process (no force-stop). `pidof` confirmed no Plato process before delivery.
- Forced deep Doze. At 14:37:32, `dumpsys notification` contained Plato notification ID 99999 while `mForceIdle=true` and `mState=IDLE`. This confirms delivery with the app process absent in Doze; the observation does not measure exact sub-second delivery latency.
- A due one-off Workmanager request invoking the production reminder handler finished without opening app UI. `notification_last_background_refresh_at=1790235379459`; no background-error preference. This run had zero eligible production requests according to its local preferences/data; it verifies headless execution, not a new 30-request native batch. The earlier September 16 run recorded 30 pending requests.
- Fixed the account-scope check to run after preference reload and removed a stale `await` for the current generated locale API. Probe cleanup now also cancels only its own one-off work request.
- Normal app (`lib/main.dart`) debug APK build succeeded after the probe run.
- Targeted Dart analysis: no issues. The Android debug APK builds successfully. Probe notification and one-off work were removed; `mForceIdle=false`, exact-alarm app-op restored to default (including UID override).
- Physical Pixel 6 overnight delivery, reboot rescheduling, and notification tap navigation still require device validation. iOS delivery has not been tested from this Windows workspace.

### Pixel 6 retest

Install the normal app build and open it once so existing schedules reconcile. Allow notifications and verify the new silent/vibration reminder channel is enabled. A 10:00 workout with 30-minute lead time should request an approximately 09:30 reminder. Close normally and leave the phone locked overnight. Record the requested time, lead time and actual delivery time if it still fails; do not use Force stop for this test.

## Sheet-first localization status

The recovery-forecast, workout-limit and Notification Settings keys below are synchronized from the Sheet into both generated locale sources. Do not manually edit locale JSON or generated Dart.

| Key | English | Vietnamese |
| --- | --- | --- |
| `notifications.msg_schedule_save_failed` | Could not save your schedule. Please try again. | Chưa lưu được lịch tập. Vui lòng thử lại. |
| `notifications.msg_add_routine_variety` | Add another routine to give yourself more variety and more suitable workout options. | Hãy tạo hoặc thêm một routine khác để đa dạng buổi tập và có thêm lựa chọn phù hợp. |
| `notifications.msg_add_routine_for_ready_muscles` | {muscles} are ready to train. Add a routine for these muscle groups so you have a suitable option today. | {muscles} đang sẵn sàng tập. Hãy tạo hoặc thêm routine cho các nhóm cơ này để có lựa chọn phù hợp hôm nay. |
| `settings.fmt_notifications_enabled` | {count} notifications enabled | Đã bật {count} thông báo |
| `notifications.lbl_workout_reminders` | Workout reminders | Nhắc lịch tập |
| `notifications.lbl_recovery_reminders` | Recovery reminder | Nhắc phục hồi |
| `notifications.lbl_streak_reminders` | Streak reminder | Nhắc streak |
| `notifications.lbl_rank_reminders` | Rank cycle reminder | Nhắc chu kỳ xếp hạng |

### Notification Settings copy refresh

These existing Sheet rows are synchronized with concise copy that makes each control's effect clear.

| Key | English | Vietnamese |
| --- | --- | --- |
| `settings.lbl_item_notification` | Notifications | Thông báo |
| `settings.title_bg_workout` | Workout notifications | Thông báo buổi tập |
| `settings.desc_bg_workout` | Show workout progress while Plato runs in the background. | Hiển thị tiến trình buổi tập khi Plato chạy nền. |
| `notifications.section_health_schedule` | Training & health | Tập luyện & sức khỏe |
| `notifications.lbl_master` | Plato notifications | Thông báo Plato |
| `notifications.desc_master` | Turn all Plato reminders on or off. | Bật hoặc tắt toàn bộ lời nhắc từ Plato. |
| `notifications.lbl_system_permission` | Device permission | Quyền thông báo thiết bị |
| `notifications.btn_open_system_settings` | Open device settings | Mở cài đặt thiết bị |
| `notifications.fmt_workout_reminders_active` | {count} workout notifications today | {count} thông báo tập hôm nay |
| `notifications.msg_workout_reminders_none` | No workout notifications left today | Không còn thông báo tập hôm nay |
| `notifications.lbl_hydration_at_16` | Hydration reminder | Nhắc uống nước |
| `notifications.desc_hydration_reminder` | At 4 PM when you are below your daily water goal. | Lúc 16:00 khi chưa đạt mục tiêu nước trong ngày. |
| `notifications.desc_recovery_reminders` | A daily training suggestion based on muscle recovery. | Gợi ý tập mỗi ngày dựa trên mức phục hồi cơ. |
| `notifications.desc_streak_reminders` | When your weekly streak is at risk. | Khi streak tuần có nguy cơ bị mất. |
| `notifications.desc_rank_reminders` | Before your current rank cycle ends. | Trước khi chu kỳ xếp hạng hiện tại kết thúc. |

The redundant rows `settings.title_notification_screen`, `settings.desc_item_notification`, and `notifications.desc_workout_reminders_manage` have been removed from both generated locales and no application source references them.

### Recovery recommendation details dialog

These rows are synchronized from the Sheet. The dialog keeps the existing Recovery Bar Chart explanation as a fallback if localized notification copy is unavailable during startup.

| Key | English | Vietnamese |
| --- | --- | --- |
| `notifications.desc_recovery_routine_details` | Plato compares each routine's target muscles with your current recovery and recent training history. It shows up to two useful options. | Plato đối chiếu các nhóm cơ của từng lịch tập với mức phục hồi hiện tại và lịch sử tập gần đây. Tối đa hai gợi ý hữu ích sẽ được hiển thị. |
| `notifications.title_recovery_routine_ready_detail` | Ready to train | Sẵn sàng tập |
| `notifications.desc_recovery_routine_ready_detail` | This routine is a good match for today's recovery. Plato also favors muscle groups you have trained less recently. | Lịch tập này phù hợp với mức phục hồi hôm nay. Plato cũng ưu tiên các nhóm cơ gần đây bạn tập ít hơn. |
| `notifications.title_recovery_routine_recovering_detail` | Better later today | Phù hợp hơn khi tập muộn |
| `notifications.desc_recovery_routine_recovering_detail` | A large part of this routine targets muscles that are still recovering. Wait a little longer before training. | Phần lớn lịch tập này tác động vào các nhóm cơ vẫn đang hồi phục. Hãy đợi thêm một chút trước khi tập. |
| `notifications.title_recovery_routine_rest_detail` | More recovery needed | Cần phục hồi thêm |
| `notifications.desc_recovery_routine_rest_detail` | Much of this routine targets muscles that need more recovery. Choose another workout or give your body more time to rest. | Phần lớn lịch tập này tác động vào các nhóm cơ cần hồi phục thêm. Hãy chọn buổi tập khác hoặc cho cơ thể thêm thời gian nghỉ ngơi. |
| `notifications.msg_recovery_adjust_exercises` | Skip or reduce exercises targeting {muscles}. | Hãy bỏ hoặc giảm các bài tập tác động vào {muscles}. |
| `notifications.title_recovery_routine_adjusted_detail` | Ready with adjustments | Phù hợp khi điều chỉnh |
| `notifications.desc_recovery_routine_adjusted_detail` | This routine is still suitable for today. Skip or reduce exercises that target muscles needing more time to recover. | Lịch tập này vẫn phù hợp để tập hôm nay. Hãy bỏ qua hoặc giảm các bài tập tác động vào những nhóm cơ cần thêm thời gian hồi phục. |

The dialog header now uses `common.info`. `notifications.title_recovery_routine_details` is no longer referenced by application code and can be removed from the Sheet during the next localization cleanup/sync.

### Sheet sync audit for the reminder-capacity update

The timed recovery-adjusted workout copy, daily-limit confirmation, today's reminder count, recovery copy and obsolete-key removals are synchronized from the Sheet. Generated locale files must not be edited by hand.
