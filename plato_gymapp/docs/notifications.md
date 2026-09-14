# Notifications: implementation and verification

## Delivery rules

- Workout: one reminder per timed schedule, 15/30/60 minutes before it. Date-only legacy schedules remain date-only with reminders off. Calendar supports setting a date/time, editing one occurrence, and starting its linked workout.
- No missed-workout notification.
- Water: opt-in, one candidate at 16:00 for today, using today's logged intake and current target. No log / below 50% / below target use different Sheet copy; reaching the goal cancels the pending reminder. Conflicts are skipped, never moved later.
- Streak: Sunday 17:00 if the preceding streak is alive and this week has no qualifying workout. A scheduled Sunday-evening workout reminder replaces it.
- Rank: 48 hours before the personal 45-day cycle ends, once per cycle.
- Recovery: trained muscles crossing 80%, grouped within three hours, with an available routine; at most one per day and two per week. Skip workout days. The workout screen also recommends recovered routines and routine details show low-recovery context.
- Inactivity: experimental, disabled by default; candidates after 14 and 28 days without a qualifying workout, suppressed by upcoming schedules.
- Daily ceiling: three by default, four selectable; never a quota. Workout reminders have priority. Automatic reminders are at least three hours apart. Quiet hours default to 22:00–08:00; selected minutes are preserved. At most 48 pending reminders, planned up to 14 days ahead.

Only Water and an individual schedule have their own reminder switches. The common switch in Settings governs all OS reminders; it is independent of in-app feedback and the existing ongoing-workout service notification.

## Data and in-app feedback

SQLite migration 6→7 preserves existing schedules, adds their time, timezone, reminder preference/lead time and completed workout linkage, and adds a notification ledger. The ledger records scheduling intent before contacting the OS and deduplicates events across reopening. Reset/logout cancels owned notifications and rotates the payload scope so another account cannot follow stale links.

In-app feedback reuses `GymTopNotification` with a queue. Streak/workout achievements are merged with workout feedback; the rewards screen acknowledges them inline. Hydration completion is inline on Water, otherwise queued. Rank promotion uses the banner; maintained/demoted outcomes use a dismissible Rank card. Historical milestones are baselined on adoption to avoid a burst of old celebrations.

## Local scheduling limits

This is local scheduling, without a server push worker. Reconciliation runs after data changes, lifecycle changes and while the app is active. Future reminders already registered with the OS can fire while the app is closed. Water is deliberately scheduled for **today only**: there is no repeating reminder with stale intake or a promise of daily reminders when the app has not been opened. The rolling 14-day horizon is replenished when the app runs. Cross-device data changes cannot change pending reminders until this device reconciles.

Android uses inexact alarms, so 16:00 is the requested delivery time; OS battery restrictions may delay actual delivery. Force-stop and device restrictions need native testing. Schedules retain their selected IANA timezone; water and quiet hours use the current device timezone. Background delivery uses the most recent reconciled snapshot.

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
- Final notification suite: 35 tests passed, including real SQLite migration/DAO tests and banner widget tests.
- Targeted Dart analysis of notifications, Calendar, the shared banner and notification tests: no issues.
- Targeted Floor/Freezed/JSON generation: succeeded after clearing the stale build cache; unrelated generated files removed by the filtered build were restored unchanged. The pinned generator still warns about its older analyzer versus the installed Dart SDK.
- Final Android debug APK build: succeeded. No device/emulator was connected, so native delivery, reboot and cold-start tap checks remain manual.

## Sheet-first localization follow-up

The 57 notification keys are present in both generated locale sources. One additional key is requested for a failed schedule save. Add it to the Sheet, then use the existing synchronization script; do not manually edit locale JSON or generated Dart.

| Key | English | Vietnamese |
| --- | --- | --- |
| `notifications.msg_schedule_save_failed` | Could not save your schedule. Please try again. | Chưa lưu được lịch tập. Vui lòng thử lại. |

Until synchronized, the error path falls back to the existing localized unsaved-changes title.
