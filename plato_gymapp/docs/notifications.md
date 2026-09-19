# Notifications: implementation and verification

## Delivery rules

- Workout: one reminder per timed schedule, 15/30/60 minutes before it. Date-only legacy schedules remain date-only with reminders off. Calendar supports setting a date/time, editing one occurrence, and starting its linked workout.
- No missed-workout notification.
- Water: opt-in, one candidate per day at 16:00, prepared up to 30 days ahead with each day's own logged intake and current target. No log / below 50% / below target use different Sheet copy; reaching the goal cancels the pending reminder. Conflicts are skipped, never moved later.
- Streak: Sunday 17:00 if the preceding streak is alive and this week has no qualifying workout. A scheduled Sunday-evening workout reminder replaces it.
- Rank: 48 hours before the personal 45-day cycle ends, once per cycle.
- Recovery: trained muscles crossing 80%, grouped within three hours, with an available routine; at most one per day and two per week. Skip workout days. The workout screen also recommends recovered routines and routine details show low-recovery context.
- Inactivity: experimental, disabled by default; candidates after 14 and 28 days without a qualifying workout, suppressed by upcoming schedules.
- Daily ceiling: three by default, four selectable; never a quota. Workout reminders have priority. Automatic reminders are at least three hours apart. Quiet hours default to 22:00–08:00; selected minutes are preserved. At most 48 pending reminders, planned up to 30 days ahead (nearer days first).

Only Water and an individual schedule have their own reminder switches. Enabling a workout reminder on Android can open the system Alarms & reminders permission screen for precise timing. Declining keeps an inexact fallback. The common switch in Settings governs all OS reminders; it is independent of in-app feedback and the existing ongoing-workout service notification.

## Data and in-app feedback

SQLite migration 6→7 preserves existing schedules, adds their time, timezone, reminder preference/lead time and completed workout linkage, and adds a notification ledger. The ledger records scheduling intent before contacting the OS and deduplicates events across reopening. Reset/logout cancels owned notifications and rotates the payload scope so another account cannot follow stale links.

In-app feedback reuses `GymTopNotification` with a queue. Streak/workout achievements are merged with workout feedback; the rewards screen acknowledges them inline. Hydration completion is inline on Water, otherwise queued. Rank promotion uses the banner; maintained/demoted outcomes use a dismissible Rank card. Historical milestones are baselined on adoption to avoid a burst of old celebrations.

## Local scheduling limits

The OS stores and delivers the alarms even after the app process exits. Opening Calendar or Water no longer cancels the day's future requests, and initialization/lifecycle refresh no longer depends on a 400 ms Dart timer. Notification wall-clock scheduling uses the device clock rather than a cached server/uptime offset that may be stale after reboot.

A Workmanager task (`vn.zenithas.plato.reminder_refresh`) requests a refresh every six hours, without a network constraint. It restores locale/profile/data locally and replenishes the rolling 30-day plan with at most 48 pending requests. It does not depend on an authenticated Supabase session or server availability. Android persists periodic work; iOS has BGAppRefresh registration and decides when to grant runtime. The pre-scheduled requests remain useful when a refresh is delayed. Thirty days is the planning horizon, not a promise that 30 full days fit when many workouts consume the finite OS queue.

The headless engine uses a separate SQLite connection so closing it cannot close the foreground database. A renewable SQLite lease serializes OS reconciliation across engines; a persistent reset flag prevents background scheduling during account clearing. The plugin resolves the live IANA timezone in either engine. Diagnostic preferences include `notification_last_reconciled_at`, `notification_pending_count`, `notification_last_background_refresh_at` and `notification_background_error`.

Workout reminders use `exactAllowWhileIdle` when Android grants Alarms & reminders access. Other reminders, and workouts without that access, use `inexactAllowWhileIdle` and can be delayed by Doze. The notification permission and channel must also be enabled. Force-stop, revoked permissions, a powered-off phone, or OS restrictions cannot be overridden. iOS can withhold background refresh after prolonged inactivity; indefinite remote reminders would require a separately configured APNs/FCM backend. This implementation does not claim such a backend is deployed.

Workouts retain their selected IANA timezone; water and quiet hours use the device timezone at the last refresh. Cross-device changes only affect this device after the existing data sync downloads them; the reminder worker itself does not fetch server data.

## Regression checks for closed-app delivery

- Schedule tomorrow's 10:00 workout with 30-minute lead time, leave Calendar open, press Home and swipe away normally: the OS request for 09:30 must remain.
- On Pixel, allow Alarms & reminders when enabling the workout reminder. Repeat with the permission declined and account for Android's inexact timing window.
- Reach today's water target: today's pending request disappears, tomorrow's 16:00 request remains. Start the app after 16:00: no replay for today, future dates remain scheduled.
- Run `tool/notification_device_probe.dart` explicitly on a development device. It schedules only ID 99999 (outside production IDs). Press Home and use `adb shell am kill vn.zenithas.plato`, not force-stop; verify the OS notification arrives after process exit. Re-run with `--dart-define=PROBE_CLEANUP=true` to cancel the probe, then restore the normal app entry point.
- Use `adb shell dumpsys jobscheduler` to find the reminder worker, trigger its job with `cmd jobscheduler run -f`, and check the reminder diagnostic preferences. Do not clear app data to test this.

## Manual device checks before release

1. Upgrade a database with old schedules: no invented time or enabled reminders; dates and recurrence groups remain intact.
2. Create/edit a timed occurrence; verify 15/30/60-minute lead time, cancellation, and that editing/deleting one recurrence group leaves another group of the same routine intact.
3. Tap a workout notification from background and cold start: open the correct calendar date; start and finish its workout, then verify schedule completion and no duplicate reminder.
4. Before 16:00, test water at 0%, 25%, 75%, 100%; check content/cancellation. Tap opens the water section. After 16:00, reopening must not replay today's reminder.
5. Disable the common switch, revoke OS permission, re-enable, reboot, and change timezone. Confirm owned reminders reconcile without affecting ongoing-workout notification 8888.
6. Exercise three/four daily ceiling, quiet-hour minute boundaries, competing workout/water times, and active-workout suppression.
7. Finish multiple workouts in one week, reach a milestone, complete water twice after an undo, and reopen: no duplicate celebrations. Hidden tabs must not consume visible feedback.
8. Advance a personal rank cycle; verify promotion versus maintained/demoted rendering. Sign out while work is queued; no previous-account notification should remain.

Android/iOS delivery and tap behavior require physical devices or emulators. Windows cannot build the iOS target.

## Verification performed

- Full existing Flutter suite: 65 tests passed before the final regression cases were added.
- Closed-app regression notification suite: 43 tests passed, including SQLite serialization, 30-day hydration planning, foreground route retention and finite OS queue ordering.
- Targeted Dart analysis of notifications, Calendar, the shared banner and notification tests: no issues.
- Targeted Floor/Freezed/JSON generation: succeeded after clearing the stale build cache; unrelated generated files removed by the filtered build were restored unchanged. The pinned generator still warns about its older analyzer versus the installed Dart SDK.
- Final Android debug APK build: succeeded. No device/emulator was connected, so native delivery, reboot and cold-start tap checks remain manual.

## Sheet-first localization follow-up

The 57 notification keys are present in both generated locale sources. One additional key is requested for a failed schedule save. Add it to the Sheet, then use the existing synchronization script; do not manually edit locale JSON or generated Dart.

| Key | English | Vietnamese |
| --- | --- | --- |
| `notifications.msg_schedule_save_failed` | Could not save your schedule. Please try again. | Chưa lưu được lịch tập. Vui lòng thử lại. |

Until synchronized, the error path falls back to the existing localized unsaved-changes title.
