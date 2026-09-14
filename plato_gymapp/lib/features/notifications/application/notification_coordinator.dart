import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/utils/time_manager.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:plato_gymapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:plato_gymapp/features/workout/data/repositories/workout_repository.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_recovery_calculator.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import '../data/notification_copy.dart';
import '../data/notification_store.dart';
import '../data/local_notification_gateway.dart';
import '../domain/notification_policy.dart';
import '../domain/reminder_planner.dart';

class NotificationCoordinator extends ChangeNotifier
    with WidgetsBindingObserver {
  static NotificationCoordinator? instance;
  final AppDatabase db;
  final SharedPreferences prefs;
  final WorkoutRepository workouts;
  final AuthRepository auth;
  final LocalNotificationGateway gateway;
  final Future<DateTime> Function() clock;
  final Future<bool> Function() permissionGranted;
  late final store = NotificationStore(db);
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _timer;
  Timer? _debounce;
  Future<void> _work = Future.value();
  bool _disposed = false;
  bool _suspended = false;
  String? activeScheduleId;
  bool activeWorkout = false;
  int levelHandledThrough = 0;
  Future<void> _eventWork = Future.value();
  String visibleRoute = '';
  bool foreground = false;
  String? _scope;
  NotificationCoordinator(
    this.db,
    this.prefs,
    this.workouts,
    this.auth, {
    LocalNotificationGateway? gateway,
    Future<DateTime> Function()? clock,
    Future<bool> Function()? permissionGranted,
  }) : gateway = gateway ?? LocalNotificationGateway(),
       clock =
           clock ??
           (() async => DateTime.fromMillisecondsSinceEpoch(
             await TimeManager.getTrueTimeMillis(),
           )),
       permissionGranted =
           permissionGranted ?? (() => Permission.notification.isGranted);

  /// Serializes lifecycle reconciliation and data-change reconciliation.
  Future<void> reconcileNow() {
    final task = _work.then((_) => _reconcile());
    _work = task.catchError((Object error) {
      debugPrint('Notification reconciliation failed: $error');
    });
    return task;
  }

  String get scope => prefs.getString('notification_scope') ?? 'local';
  bool get enabled => prefs.getBool('notification_enabled') ?? true;
  bool get waterEnabled => prefs.getBool('notification_water') ?? false;
  double get waterTarget => prefs.getDouble('saved_water_target') ?? 2.5;
  int get dailyLimit => (prefs.getInt('notification_limit') ?? 3).clamp(1, 4);
  String get timezone => gateway.zoneId;

  Future<void> initialize() async {
    instance = this;
    WidgetsBinding.instance.addObserver(this);
    if (!prefs.containsKey('notification_scope')) {
      await prefs.setString(
        'notification_scope',
        '${DateTime.now().microsecondsSinceEpoch}',
      );
    }
    _scope = scope;
    _subscriptions.add(
      workouts.workoutHistoryStream.listen((_) => requestReconcile()),
    );
    _subscriptions.add(
      workouts.scheduledWorkoutsStream.listen((_) => requestReconcile()),
    );
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => requestReconcile(),
    );
    requestReconcile();
  }

  void requestReconcile() {
    if (_disposed || _suspended) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      reconcileNow().catchError((Object error) {
        debugPrint('Notification reconciliation failed: $error');
      });
    });
  }

  Future<bool> setEnabled(bool value) async {
    if (value && !(await Permission.notification.request()).isGranted)
      return false;
    await prefs.setBool('notification_enabled', value);
    if (!value) {
      await _work;
      await gateway.clearOwned();
    }
    requestReconcile();
    notifyListeners();
    return true;
  }

  Future<bool> setWaterEnabled(bool value) async {
    if (value && !await setEnabled(true)) return false;
    await prefs.setBool('notification_water', value);
    requestReconcile();
    notifyListeners();
    return true;
  }

  Future<void> setWaterTarget(double value) async {
    if (!value.isFinite || value <= 0) return;
    await prefs.setDouble('saved_water_target', value);
    requestReconcile();
    notifyListeners();
  }

  Future<void> setLimit(int value) async {
    await prefs.setInt('notification_limit', value.clamp(1, 4));
    requestReconcile();
    notifyListeners();
  }

  Future<void> setQuietHours(
    int start,
    int end, {
    int startMinute = 0,
    int endMinute = 0,
  }) async {
    await prefs.setInt('notification_quiet_start', start);
    await prefs.setInt('notification_quiet_end', end);
    await prefs.setInt('notification_quiet_start_minute', startMinute);
    await prefs.setInt('notification_quiet_end_minute', endMinute);
    requestReconcile();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    requestReconcile();
  }

  DateTime scheduleTime(ScheduledWorkoutEntity s) {
    final location = tz.getLocation(s.timeZoneId ?? gateway.zoneId);
    final day = tz.TZDateTime.fromMillisecondsSinceEpoch(
      location,
      s.targetDateMillis,
    );
    final minutes = s.timeOfDayMinutes ?? 8 * 60;
    return tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      minutes ~/ 60,
      minutes % 60,
    ).toLocal();
  }

  Future<void> _reconcile() async {
    if (_disposed || _suspended) return;
    if (_scope != null && _scope != scope) return;
    final capturedScope = scope;
    final now = await clock();
    final history = await workouts.workoutHistoryStream.first;
    await _rankEvents(history, now);
    if (!enabled || !await permissionGranted() || !NotificationCopy.available) {
      await gateway.clearOwned();
      return;
    }
    await gateway.updateTimezone();
    final schedules = await db.workoutDao.getAllScheduledWorkouts();
    final day = NotificationPolicy.dayKey(now);
    final nutrition = await db.nutritionDao.getDailyNutritionByDate(day);
    final candidates = ReminderPlanner.build(
      now: now,
      schedules: schedules.where((s) => s.id != activeScheduleId).toList(),
      history: history,
      profile: auth.getProfile(),
      water: nutrition?.waterConsumedLiters ?? 0,
      target: waterTarget,
      waterEnabled: waterEnabled,
      scheduledTime: scheduleTime,
      routineName: (name) => t.translateDynamic(name),
      activeWorkout: activeWorkout,
      inactivityEnabled:
          prefs.getBool('notification_inactivity_experiment') ?? false,
    );
    if (!activeWorkout)
      candidates.addAll(await _recoveryCandidates(history, schedules, now));
    final stored = await store.all('schedule:');
    final committed = <ReminderCandidate>[];
    for (final entry in stored.entries) {
      final value = entry.value;
      final at = DateTime.fromMillisecondsSinceEpoch(value['at'] as int);
      if (!at.isAfter(now) &&
          (value['state'] == 'scheduled' || value['state'] == 'pending')) {
        committed.add(
          ReminderCandidate(
            key: entry.key.substring(9),
            kind: ReminderKind.values.byName(value['kind'] as String),
            at: at,
            titleKey: '',
            bodyKey: '',
            route: '',
          ),
        );
      }
    }
    final visibleCandidates = candidates
        .where(
          (c) =>
              !(foreground &&
                  visibleRoute.split('?').first == c.route.split('?').first &&
                  NotificationPolicy.dayKey(c.at) == day),
        )
        .toList();
    final selected = NotificationPolicy.select(
      visibleCandidates,
      now: now,
      committed: committed,
      dailyLimit: dailyLimit,
      quietStart: prefs.getInt('notification_quiet_start') ?? 22,
      quietEnd: prefs.getInt('notification_quiet_end') ?? 8,
      quietStartMinute: prefs.getInt('notification_quiet_start_minute') ?? 0,
      quietEndMinute: prefs.getInt('notification_quiet_end_minute') ?? 0,
    );
    final pending = await gateway.pending();
    final desiredKeys = selected.map((c) => 'schedule:${c.key}').toSet();
    for (final entry in stored.entries) {
      final value = entry.value;
      final at = DateTime.fromMillisecondsSinceEpoch(value['at'] as int);
      final invalidWater =
          value['kind'] == ReminderKind.hydration.name &&
          (!waterEnabled ||
              activeWorkout ||
              NotificationPolicy.dayKey(at) != day ||
              (nutrition?.waterConsumedLiters ?? 0) >= waterTarget);
      final invalidWorkout =
          value['kind'] == ReminderKind.workout.name &&
          !schedules.any(
            (s) =>
                entry.key == 'schedule:workout:${s.id}' &&
                !s.isDeleted &&
                !s.isCompleted &&
                s.reminderEnabled &&
                s.id != activeScheduleId,
          );
      // Inexact OS delivery may still be pending after its requested time.
      // Invalidate stale content too, while retaining its consumed budget slot.
      final pendingInvalid =
          (invalidWater || invalidWorkout) &&
          pending.any((p) => p.id == value['id']);
      if ((!desiredKeys.contains(entry.key) && at.isAfter(now)) ||
          pendingInvalid) {
        await gateway.cancel(value['id'] as int);
        if (at.isAfter(now)) {
          await store.write(entry.key, {...value, 'state': 'cancelled'});
        }
      }
    }
    var nextId = max(
      prefs.getInt('notification_next_id') ?? 100000,
      stored.values.fold<int>(99999, (n, v) => max(n, v['id'] as int)) + 1,
    );
    for (final candidate in selected) {
      if (_suspended || capturedScope != scope || !enabled) {
        await gateway.clearOwned();
        return;
      }
      final key = 'schedule:${candidate.key}';
      final previous = stored[key];
      final fingerprint = jsonEncode([
        scope,
        candidate.at.millisecondsSinceEpoch,
        LocaleSettings.currentLocale.languageCode,
        candidate.bodyKey,
        candidate.arguments,
      ]);
      final id = previous?['id'] as int? ?? nextId++;
      if (previous?['fingerprint'] == fingerprint &&
          previous?['state'] == 'scheduled' &&
          pending.any((p) => p.id == id))
        continue;
      // Persist intent before OS work, so a retry reuses the same id after a crash.
      final record = {
        'id': id,
        'at': candidate.at.millisecondsSinceEpoch,
        'kind': candidate.kind.name,
        'fingerprint': fingerprint,
        'state': 'pending',
      };
      await store.write(key, record);
      if (await gateway.schedule(id, candidate, scope)) {
        await store.write(key, {...record, 'state': 'scheduled'});
      }
    }
    await prefs.setInt('notification_next_id', nextId);
    notifyListeners();
  }

  Future<List<ReminderCandidate>> _recoveryCandidates(
    List<WorkoutSession> history,
    List<ScheduledWorkoutEntity> schedules,
    DateTime now,
  ) async {
    final valid = history.where(StreakCalculator.qualifies).toList();
    if (valid.isEmpty) return [];
    final crossing = <(MuscleGroup, DateTime)>[];
    for (final muscle in MuscleGroup.values) {
      final status = MuscleRecoveryCalculator.getRecoveryStatus(
        muscle,
        valid,
        at: now,
      );
      if (status.lastTrainedDate == 0 ||
          status.initialFatigue <= 20 ||
          status.recoveryRate <= 0)
        continue;
      final hours = log(status.initialFatigue / 20) / status.recoveryRate;
      final at = DateTime.fromMillisecondsSinceEpoch(
        status.lastTrainedDate + (hours * 3600000).ceil(),
      );
      if (at.isAfter(now) && at.isBefore(now.add(const Duration(days: 14))))
        crossing.add((muscle, at));
    }
    crossing.sort((a, b) => a.$2.compareTo(b.$2));
    final routines = await workouts.routinesStream.first;
    final result = <ReminderCandidate>[];
    while (crossing.isNotEmpty) {
      final first = crossing.removeAt(0);
      final group = [
        first,
        ...crossing.where(
          (e) => e.$2.difference(first.$2) <= const Duration(hours: 3),
        ),
      ];
      crossing.removeWhere((e) => group.contains(e));
      final at = group.last.$2;
      if (!routines.any(
        (r) => r.exercises.any(
          (e) => group.any((g) => g.$1 == e.exercise.primaryMuscle),
        ),
      ))
        continue;
      if (schedules.any(
        (s) =>
            !s.isCompleted &&
            NotificationPolicy.dayKey(scheduleTime(s)) ==
                NotificationPolicy.dayKey(at),
      ))
        continue;
      final names = group
          .map((g) => t.translateDynamic('muscles.${g.$1.name.toLowerCase()}'))
          .join(', ');
      final last = valid.map((w) => w.startTime).reduce(max);
      result.add(
        ReminderCandidate(
          key: 'recovery:$last:${group.map((g) => g.$1.name).join(',')}',
          kind: ReminderKind.recovery,
          at: at,
          titleKey: 'notifications.title_recovery_ready',
          bodyKey: 'notifications.body_recovery_ready',
          arguments: {'muscles': names},
          route: '/workout?recovery=1',
        ),
      );
    }
    return result;
  }

  Future<void> recordWorkout(
    WorkoutSession session, {
    int? previousLevel,
    int? newLevel,
  }) {
    if (newLevel != null)
      levelHandledThrough = max(levelHandledThrough, newLevel);
    final capturedScope = scope;
    final task = _eventWork.then((_) async {
      if (_suspended || capturedScope != scope) return;
      await _recordWorkout(
        session,
        previousLevel: previousLevel,
        newLevel: newLevel,
      );
    });
    _eventWork = task.catchError((Object error) {
      debugPrint('Workout notification event failed: $error');
    });
    return task;
  }

  Future<void> _recordWorkout(
    WorkoutSession session, {
    int? previousLevel,
    int? newLevel,
  }) async {
    if (!StreakCalculator.qualifies(session)) return;
    final scheduleId = session.sessionPayload.scheduledWorkoutId;
    if (scheduleId != null)
      await db.workoutDao.completeSchedule(
        scheduleId,
        session.id,
        DateTime.now().millisecondsSinceEpoch,
      );
    final marker = 'completed:${session.id}';
    if (await store.read(marker) != null) return;
    final now = await clock();
    final history = await workouts.workoutHistoryStream.first;
    final before = history.where((s) => s.id != session.id).toList();
    final writes = <String, Map<String, dynamic>>{};
    final parts = <Map<String, dynamic>>[];
    if (previousLevel != null && newLevel != null && newLevel > previousLevel) {
      parts.add({
        'title': 'gamification.msg_level_up_base',
        'literalBody': '$previousLevel ➔ $newLevel',
        'args': <String, String>{},
      });
    }
    final streak = StreakCalculator.count(history, now);
    final week = StreakCalculator.weekStart(now);
    if (StreakCalculator.weekStart(
              DateTime.fromMillisecondsSinceEpoch(session.startTime),
            ) ==
            week &&
        !StreakCalculator.weeks(before, now).contains(week)) {
      final milestone = [4, 8, 12, 26, 52].contains(streak);
      final key = milestone
          ? 'streak_milestone:$streak'
          : 'streak:${NotificationPolicy.dayKey(week)}';
      if (await store.read(key) == null) {
        parts.add({
          'title':
              'notifications.title_${milestone
                  ? 'streak_milestone'
                  : streak == 1
                  ? 'streak_started'
                  : 'streak_extended'}',
          'body':
              'notifications.body_${milestone
                  ? 'streak_milestone'
                  : streak == 1
                  ? 'streak_started'
                  : 'streak_extended'}',
          'args': streak == 1 ? <String, String>{} : {'weeks': '$streak'},
        });
        writes[key] = {'at': now.millisecondsSinceEpoch};
      }
    }
    final count = history.where(StreakCalculator.qualifies).length;
    if ([10, 25, 50, 100, 250, 500].contains(count) &&
        await store.read('workout_milestone:$count') == null) {
      parts.add({
        'title': 'notifications.title_workout_milestone',
        'body': 'notifications.body_workout_milestone',
        'args': {'count': '$count'},
      });
      writes['workout_milestone:$count'] = {'at': now.millisecondsSinceEpoch};
    }
    writes[marker] = {'at': now.millisecondsSinceEpoch};
    if (parts.isNotEmpty)
      writes['event:$marker'] = {
        'parts': parts,
        'at': now.millisecondsSinceEpoch,
        'shown': false,
        'route': '/profile/calendar',
      };
    await store.writeBatch(writes);
    requestReconcile();
    notifyListeners();
  }

  Future<void> waterChanged(String date, double before, double after) {
    final capturedScope = scope;
    final task = _eventWork.then((_) async {
      if (_suspended || capturedScope != scope) return;
      await _waterChanged(date, before, after);
    });
    _eventWork = task.catchError((Object error) {
      debugPrint('Water notification event failed: $error');
    });
    return task;
  }

  Future<void> _waterChanged(String date, double before, double after) async {
    final key = 'hydration_completed:$date';
    final now = await clock();
    if (date == NotificationPolicy.dayKey(now) &&
        before < waterTarget &&
        after >= waterTarget &&
        await store.read(key) == null) {
      await store.writeBatch({
        key: {'at': DateTime.now().millisecondsSinceEpoch},
        'event:$key': {
          'parts': [
            {
              'title': 'notifications.title_hydration_completed',
              'body': 'notifications.body_hydration_completed',
              'args': {'target': waterTarget.toStringAsFixed(2)},
            },
          ],
          'at': DateTime.now().millisecondsSinceEpoch,
          'shown': false,
          'route': '/nutrition?water=1',
        },
      });
    }
    requestReconcile();
    notifyListeners();
  }

  Future<void> _rankEvents(List<WorkoutSession> history, DateTime now) async {
    final active = history
        .where((w) => !w.isDeleted && w.startTime <= now.millisecondsSinceEpoch)
        .toList();
    final anchor = active
        .map((w) => w.startTime)
        .fold<int?>(null, (a, b) => a == null ? b : min(a, b));
    final baseline = await store.read('baseline');
    if (baseline == null || baseline['anchor'] != anchor) {
      final writes = <String, Map<String, dynamic>>{
        'baseline': {'at': now.millisecondsSinceEpoch, 'anchor': anchor},
      };
      final count = active.where(StreakCalculator.qualifies).length;
      for (final threshold in [10, 25, 50, 100, 250, 500]) {
        if (count >= threshold)
          writes['workout_milestone:$threshold'] = {'baseline': true};
      }
      final maxStreak = StreakCalculator.longest(active, now);
      for (final threshold in [4, 8, 12, 26, 52]) {
        if (maxStreak >= threshold)
          writes['streak_milestone:$threshold'] = {'baseline': true};
      }
      // A history correction invalidates queued results from the previous anchor.
      for (final entry in (await store.all('event:rank_result:')).entries) {
        writes[entry.key] = {...entry.value, 'shown': true};
      }
      await store.writeBatch(writes);
      return;
    }
    final result = RankCalculator.calculateTrueRankAndSeasons(
      active,
      auth.getProfile(),
      now.millisecondsSinceEpoch,
    );
    final latest = result.generatedHistory.lastOrNull;
    if (latest == null || latest.achievedAtMillis <= (baseline['at'] as int))
      return;
    final key = 'rank_result:${latest.achievedAtMillis}';
    if (await store.read(key) != null) return;
    final promoted = latest.unlockReasonDescription == 'REASON_PROMOTED';
    final suffix = latest.unlockReasonDescription == 'REASON_DEMOTED'
        ? 'rank_demoted'
        : 'rank_maintained';
    final writes = <String, Map<String, dynamic>>{};
    for (final entry in (await store.all('event:rank_result:')).entries) {
      writes[entry.key] = {...entry.value, 'shown': true};
    }
    writes[key] = {'at': now.millisecondsSinceEpoch};
    writes['event:$key'] = {
      'parts': [
        {
          'title': promoted
              ? 'gamification.msg_rank_up'
              : 'notifications.title_$suffix',
          'body': promoted
              ? RankConfig.getRankById(latest.rankId).nameKey
              : 'notifications.body_$suffix',
          'args': <String, String>{},
          if (!promoted)
            'rankNameKey': RankConfig.getRankById(latest.rankId).nameKey,
        },
      ],
      'at': now.millisecondsSinceEpoch,
      'shown': false,
      'cardOnly': !promoted,
      'rankId': latest.rankId,
      'route': '/social/rank_screen',
    };
    await store.writeBatch(writes);
  }

  /// Called before clearing account data. Wait for in-flight scheduling first.
  Future<void> reset() async {
    _suspended = true;
    _debounce?.cancel();
    await _work;
    await _eventWork;
    await gateway.clearOwned();
    await db.notificationDao.clear();
    await prefs.remove('saved_water_target');
    await prefs.remove('notification_water');
    await prefs.setString(
      'notification_scope',
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    _scope = scope;
    activeWorkout = false;
    activeScheduleId = null;
    levelHandledThrough = 0;
  }

  void resumeAfterReset() {
    _suspended = false;
    requestReconcile();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _debounce?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    if (instance == this) instance = null;
    super.dispose();
  }
}
