import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/utils/workout_permission_helper.dart';
import 'package:plato_gymapp/core/worker/background_workout_service.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:plato_gymapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:plato_gymapp/features/workout/data/repositories/workout_repository.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import '../data/notification_copy.dart';
import '../data/notification_preferences.dart';
import '../data/notification_store.dart';
import '../data/local_notification_gateway.dart';
import '../domain/notification_policy.dart';
import '../domain/reminder_planner.dart';

class NotificationCoordinator extends ChangeNotifier
    with WidgetsBindingObserver {
  static NotificationCoordinator? instance;
  static const _lastAppOpenedAtKey = 'notification_last_app_opened_at';
  final AppDatabase db;
  final SharedPreferences prefs;
  final WorkoutRepository workouts;
  final AuthRepository auth;
  final LocalNotificationGateway gateway;
  final Future<DateTime> Function() clock;
  final Future<bool> Function() permissionGranted;
  final int horizonDays;
  final bool backgroundRefresh;
  late final store = NotificationStore(db);
  late final preferencesStore = NotificationPreferencesStore(prefs);
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _reconcileDebounce;
  bool _initialized = false;
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
  NotificationPreferences _preferences = NotificationPreferences.defaults;
  NotificationCoordinator(
    this.db,
    this.prefs,
    this.workouts,
    this.auth, {
    this.horizonDays = 30,
    this.backgroundRefresh = false,
    LocalNotificationGateway? gateway,
    Future<DateTime> Function()? clock,
    Future<bool> Function()? permissionGranted,
  }) : gateway = gateway ?? LocalNotificationGateway(),
       clock = clock ?? (() async => DateTime.now()),
       permissionGranted =
           permissionGranted ?? (() => Permission.notification.isGranted);

  /// Serializes lifecycle reconciliation and data-change reconciliation.
  Future<void> reconcileNow() {
    final task = _work.then((_) => store.withDeliveryLock(_reconcile));
    _work = task.catchError((Object error) {
      debugPrint('Notification reconciliation failed: $error');
    });
    return task;
  }

  String get scope {
    final userId = auth.currentUserId?.trim();
    if (userId != null && userId.isNotEmpty) return 'user_$userId';
    return prefs.getString('notification_scope') ?? 'local';
  }

  NotificationPreferences get preferences => _preferences;
  bool get enabled => _preferences.masterEnabled;
  bool get waterEnabled => _preferences.hydrationEnabled;
  bool get recoveryEnabled => _preferences.recoveryEnabled;
  bool get streakEnabled => _preferences.streakEnabled;
  bool get rankEnabled => _preferences.rankEnabled;
  int get enabledCategoryCount => _preferences.enabledCategoryCount;
  double get waterTarget => prefs.getDouble('saved_water_target') ?? 2.5;
  String get timezone => gateway.zoneId;

  Future<bool> hasWorkoutReminderCapacity(
    Iterable<DateTime> dates, {
    String? excludingScheduleId,
    required int timeOfDayMinutes,
    required int leadMinutes,
  }) async {
    final requestedDays = dates.map((date) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        timeOfDayMinutes ~/ 60,
        timeOfDayMinutes % 60,
      );
      return NotificationPolicy.dayKey(
        start.subtract(Duration(minutes: leadMinutes)),
      );
    }).toSet();
    if (requestedDays.isEmpty) return true;
    final now = await clock();
    final counts = <String, int>{};
    for (final record in (await store.all('schedule:')).values) {
      final atValue = record['at'];
      if (atValue is! int ||
          (record['state'] != 'scheduled' && record['state'] != 'pending')) {
        continue;
      }
      // Workout reminders are counted from the schedule table below. Counting
      // their ledger rows here as well would reject capacity too early.
      if (record['kind'] == ReminderKind.workout.name) continue;
      final at = DateTime.fromMillisecondsSinceEpoch(atValue);
      final day = NotificationPolicy.dayKey(at);
      if (requestedDays.contains(day) && at.isAfter(now)) {
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }
    for (final schedule in await db.workoutDao.getAllScheduledWorkouts()) {
      if (schedule.id == excludingScheduleId ||
          schedule.isDeleted ||
          schedule.isCompleted ||
          !schedule.reminderEnabled ||
          schedule.timeOfDayMinutes == null) {
        continue;
      }
      final reminderAt = scheduleTime(
        schedule,
      ).subtract(Duration(minutes: schedule.reminderMinutesBefore));
      final day = NotificationPolicy.dayKey(reminderAt);
      if (requestedDays.contains(day) && reminderAt.isAfter(now)) {
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }
    return requestedDays.every(
      (day) => (counts[day] ?? 0) < NotificationPolicy.maxPerDay,
    );
  }

  Future<void> initialize() async {
    instance = this;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    if (auth.currentUserId != null && auth.currentUserId!.trim().isNotEmpty) {
      await prefs.setString('notification_scope', 'user_${auth.currentUserId}');
    } else if (!prefs.containsKey('notification_scope')) {
      await prefs.setString(
        'notification_scope',
        '${DateTime.now().microsecondsSinceEpoch}',
      );
    }
    _scope = scope;
    _preferences = await preferencesStore.load(scope);
    await _recordAppOpened();
    _subscriptions.add(
      workouts.workoutHistoryStream.listen((_) => requestReconcile()),
    );
    _subscriptions.add(
      workouts.scheduledWorkoutsStream.listen((_) => requestReconcile()),
    );
    _subscriptions.add(
      workouts.routinesStream.listen((_) => requestReconcile()),
    );
    // Persist OS requests before initialization returns, not after a Dart timer.
    try {
      await reconcileNow();
    } catch (error) {
      debugPrint('Initial reminder scheduling failed: $error');
    }
  }

  void requestReconcile() {
    if (!_initialized || _disposed || _suspended) return;
    // Database streams can emit in short bursts. Coalesce those emissions so
    // recovery history is replayed once instead of once per table mutation.
    _reconcileDebounce?.cancel();
    _reconcileDebounce = Timer(const Duration(milliseconds: 300), () {
      _reconcileDebounce = null;
      unawaited(
        reconcileNow().catchError((Object error) {
          debugPrint('Notification reconciliation failed: $error');
        }),
      );
    });
  }

  Future<bool> _ensureNotificationPermission() async {
    if (await permissionGranted()) return true;
    return (await Permission.notification.request()).isGranted;
  }

  Future<bool> setEnabled(bool value) async {
    if (value && !await _ensureNotificationPermission()) return false;
    final previous = _preferences;
    _preferences = _preferences.withMasterEnabled(value);
    notifyListeners();
    try {
      await preferencesStore.save(scope, _preferences);
    } catch (_) {
      _preferences = previous;
      notifyListeners();
      rethrow;
    }
    requestReconcile();
    return true;
  }

  Future<bool> setWaterEnabled(bool value) async {
    return setPreference(NotificationPreferenceKind.hydration, value);
  }

  Future<bool> setPreference(
    NotificationPreferenceKind kind,
    bool value,
  ) async {
    if (value && !await _ensureNotificationPermission()) return false;
    final previous = _preferences;
    _preferences = _preferences.withPreference(kind, value);
    notifyListeners();
    try {
      await preferencesStore.save(scope, _preferences);
    } catch (_) {
      _preferences = previous;
      notifyListeners();
      rethrow;
    }
    requestReconcile();
    return true;
  }

  Future<void> setWaterTarget(double value) async {
    if (!value.isFinite || value <= 0) return;
    await prefs.setDouble('saved_water_target', value);
    await reconcileNow();
    notifyListeners();
  }

  Future<int> upcomingWorkoutReminderCount() async {
    final now = await clock();
    final schedules = await db.workoutDao.getAllScheduledWorkouts();
    return schedules.where((schedule) {
      if (schedule.isDeleted ||
          schedule.isCompleted ||
          !schedule.reminderEnabled ||
          schedule.timeOfDayMinutes == null) {
        return false;
      }
      return scheduleTime(schedule)
          .subtract(Duration(minutes: schedule.reminderMinutesBefore))
          .isAfter(now);
    }).length;
  }

  Future<Map<String, dynamic>> diagnostics() async {
    await prefs.reload();
    final plan = await store.read('diagnostic:last_plan');
    List<dynamic> pending = const [];
    List<dynamic> active = const [];
    try {
      pending = await gateway.pending();
      active = await gateway.active();
    } catch (_) {
      // Some platforms do not expose active notifications.
    }
    return {
      'lastPlan': plan,
      'lastReconciledAt': prefs.getInt('notification_last_reconciled_at'),
      'lastBackgroundAt': prefs.getInt(
        'notification_last_background_refresh_at',
      ),
      'durationMs': prefs.getInt('notification_last_reconcile_duration_ms'),
      'pendingCount': pending.length,
      'activeCount': active.length,
      'backgroundError': prefs.getString('notification_background_error'),
      'timezone': timezone,
      'permissionGranted': await permissionGranted(),
    };
  }

  Future<bool> showDiagnosticTestNow() async {
    if (!await permissionGranted()) return false;
    await gateway.showTestNow();
    return true;
  }

  Future<bool> scheduleDiagnosticTest() async {
    if (!await permissionGranted()) return false;
    await gateway.updateTimezone();
    await gateway.scheduleTest(scope);
    return true;
  }

  Future<void> recordExternalInteraction(
    String notificationKey, {
    String? actionId,
  }) async {
    final key = 'schedule:$notificationKey';
    final record = await store.read(key);
    if (record == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await store.write(key, {
      ...record,
      'tappedAt': now,
      if (actionId != null && actionId.isNotEmpty) 'actionId': actionId,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) return;
    unawaited(
      _recordAppOpenedAndReconcile().catchError((Object error) {
        debugPrint('Notification lifecycle reconciliation failed: $error');
      }),
    );
  }

  Future<void> _recordAppOpened() async {
    final now = await clock();
    await prefs.setInt(_lastAppOpenedAtKey, now.millisecondsSinceEpoch);
  }

  Future<void> _recordAppOpenedAndReconcile() async {
    await _recordAppOpened();
    await reconcileNow();
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
    final stopwatch = Stopwatch()..start();
    if (_disposed || _suspended) return;
    await prefs.reload();
    if (_scope != scope) {
      _scope = scope;
      await prefs.setString('notification_scope', scope);
    }
    _preferences = await preferencesStore.load(scope);
    if (prefs.getBool('notification_resetting') == true) return;
    final capturedScope = scope;
    final now = await clock();
    final lastAppOpenedAt = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_lastAppOpenedAtKey) ?? now.millisecondsSinceEpoch,
    );
    final history = await workouts.workoutHistoryStream.first;
    if (!backgroundRefresh) await _rankEvents(history, now);
    final hasPermission = await permissionGranted();
    if (!hasPermission &&
        prefs.getBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey) ==
            true) {
      await prefs.setBool(
        WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey,
        false,
      );
      if (!backgroundRefresh) BackgroundWorkoutService().stopService();
    }
    if (!hasPermission &&
        (_preferences.masterEnabled || _preferences.hasEnabledCategory)) {
      _preferences = _preferences.withMasterEnabled(false);
      await preferencesStore.save(scope, _preferences);
      notifyListeners();
    }
    if (!enabled || !hasPermission || !NotificationCopy.available) {
      await gateway.clearOwned();
      await store.write('diagnostic:last_plan', {
        'at': now.millisecondsSinceEpoch,
        'selected': const [],
        'suppressed': [
          {
            'reason': !hasPermission
                ? 'systemPermissionDenied'
                : !enabled
                ? 'masterDisabled'
                : 'copyUnavailable',
          },
        ],
      });
      await _recordReconcileMetrics(stopwatch, 0);
      return;
    }
    await gateway.updateTimezone();
    final day = NotificationPolicy.dayKey(now);
    final schedulesFuture = db.workoutDao.getAllScheduledWorkouts();
    final routinesFuture = workouts.routinesStream.first;
    final storedFuture = store.all('schedule:');
    final nutritionFuture = db.nutritionDao.getDailyNutritionByDate(day);
    final nutritionHistoryFuture = db.nutritionDao.getAllNutritionHistory();
    final schedules = await schedulesFuture;
    final routines = await routinesFuture;
    final stored = await storedFuture;
    String? lastDeliveredRecoverySignature;
    final elapsedScheduledRecoveries =
        stored.entries.where((entry) {
          final value = entry.value;
          final metadata = value['metadata'];
          return metadata is Map &&
              metadata['recoverySignature'] is String &&
              (metadata['recoverySignature'] as String).isNotEmpty &&
              (value['at'] as int) <= now.millisecondsSinceEpoch &&
              (value['state'] == 'scheduled' || value['state'] == 'pending');
        }).toList()..sort(
          (a, b) => (b.value['at'] as int).compareTo(a.value['at'] as int),
        );
    if (elapsedScheduledRecoveries.isNotEmpty) {
      final metadata = elapsedScheduledRecoveries.first.value['metadata'];
      if (metadata is Map) {
        lastDeliveredRecoverySignature =
            metadata['recoverySignature'] as String?;
      }
    }
    final nutrition = await nutritionFuture;
    final waterByDay = {
      for (final entry in await nutritionHistoryFuture)
        entry.dateId: entry.waterConsumedLiters,
    };
    final candidates = ReminderPlanner.build(
      horizonDays: horizonDays,
      waterByDay: waterByDay,
      now: now,
      schedules: schedules.where((s) => s.id != activeScheduleId).toList(),
      history: history,
      routinesById: {for (final routine in routines) routine.id: routine},
      profile: auth.getProfile(),
      water: nutrition?.waterConsumedLiters ?? 0,
      target: waterTarget,
      waterEnabled: waterEnabled,
      recoveryEnabled: recoveryEnabled,
      streakEnabled: streakEnabled,
      rankEnabled: rankEnabled,
      scheduledTime: scheduleTime,
      routineName: (name) => t.translateDynamic(name),
      muscleName: (muscle) =>
          t.translateDynamic('muscles.${muscle.name.toLowerCase()}'),
      compactMuscleNames: (names) {
        if (names.length <= 3) return names.join(', ');
        return NotificationCopy.text('notifications.fmt_more_muscles', {
              'muscles': names.take(2).join(', '),
              'count': '${names.length - 2}',
            }) ??
            names.take(3).join(', ');
      },
      activeWorkout: activeWorkout,
      lastAppOpenedAt: lastAppOpenedAt,
      lastDeliveredRecoverySignature: lastDeliveredRecoverySignature,
    );
    final committed = <ReminderCandidate>[];
    for (final entry in stored.entries) {
      final value = entry.value;
      final at = DateTime.fromMillisecondsSinceEpoch(value['at'] as int);
      if (!at.isAfter(now) &&
          (value['state'] == 'scheduled' || value['state'] == 'pending')) {
        final matchingKinds = ReminderKind.values.where(
          (kind) => kind.name == value['kind'],
        );
        // Ignore obsolete reminder kinds left in ledgers from older builds.
        if (matchingKinds.isEmpty) continue;
        committed.add(
          ReminderCandidate(
            key: entry.key.substring(9),
            kind: matchingKinds.first,
            at: at,
            titleKey: '',
            bodyKey: '',
            route: '',
          ),
        );
      }
    }
    // Viewing a screen must not delete reminders needed after the app closes.
    // Darwin foreground presentation is suppressed by the notification gateway.
    final plan = NotificationPolicy.plan(
      _pinNearTermCandidates(candidates, stored, now),
      now: now,
      committed: committed,
    );
    final selected = plan.selected;
    final contextualSuppressions = <Map<String, dynamic>>[
      if (!waterEnabled)
        {'kind': ReminderKind.hydration.name, 'reason': 'categoryDisabled'},
      if (!recoveryEnabled)
        {'kind': ReminderKind.recovery.name, 'reason': 'categoryDisabled'},
      if (!streakEnabled)
        {'kind': ReminderKind.streak.name, 'reason': 'categoryDisabled'},
      if (!rankEnabled)
        {'kind': ReminderKind.rank.name, 'reason': 'categoryDisabled'},
      if (waterEnabled && (nutrition?.waterConsumedLiters ?? 0) >= waterTarget)
        {'kind': ReminderKind.hydration.name, 'reason': 'goalReached'},
      if (activeWorkout)
        {'kind': ReminderKind.recovery.name, 'reason': 'activeWorkout'},
      if (lastDeliveredRecoverySignature != null &&
          lastDeliveredRecoverySignature.startsWith('allReady:'))
        {'kind': ReminderKind.recovery.name, 'reason': 'recoveryUnchanged'},
      for (final workout in selected)
        if (workout.kind == ReminderKind.workout &&
            (workout.metadata['recoverySignature'] ?? '').isNotEmpty &&
            !selected.any(
              (item) =>
                  item.kind == ReminderKind.recovery &&
                  item.metadata['targetDay'] == workout.metadata['targetDay'],
            ))
          {
            'key': workout.key,
            'kind': ReminderKind.recovery.name,
            'reason': 'mergedWorkout',
          },
    ];
    await store.write('diagnostic:last_plan', {
      'at': now.millisecondsSinceEpoch,
      'selected': [
        for (final candidate in selected)
          {
            'key': candidate.key,
            'kind': candidate.kind.name,
            'at': candidate.at.millisecondsSinceEpoch,
          },
      ],
      'moved': [
        for (final decision in plan.moved)
          {
            'key': decision.original.key,
            'kind': decision.original.kind.name,
            'from': decision.original.at.millisecondsSinceEpoch,
            'to': decision.selected.at.millisecondsSinceEpoch,
          },
      ],
      'suppressed': [
        ...contextualSuppressions,
        for (final decision in plan.suppressed)
          {
            'key': decision.candidate.key,
            'kind': decision.candidate.kind.name,
            'at': decision.candidate.at.millisecondsSinceEpoch,
            'reason': decision.reason.name,
          },
      ],
    });
    final pending = await gateway.pending();
    await _observeDueAndActive(stored, now);
    final desiredKeys = selected.map((c) => 'schedule:${c.key}').toSet();
    for (final entry in stored.entries) {
      final value = entry.value;
      final at = DateTime.fromMillisecondsSinceEpoch(value['at'] as int);
      final invalidWater =
          value['kind'] == ReminderKind.hydration.name &&
          (!waterEnabled ||
              (activeWorkout && NotificationPolicy.dayKey(at) == day) ||
              NotificationPolicy.dayKey(at).compareTo(day) < 0 ||
              (waterByDay[NotificationPolicy.dayKey(at)] ?? 0) >= waterTarget);
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
      final obsoleteKind = !ReminderKind.values.any(
        (kind) => kind.name == value['kind'],
      );
      // Inexact OS delivery may still be pending after its requested time.
      // Invalidate stale content too, while retaining its consumed budget slot.
      final pendingInvalid =
          (invalidWater || invalidWorkout) &&
          pending.any((p) => p.id == value['id']);
      if (obsoleteKind ||
          (!desiredKeys.contains(entry.key) && at.isAfter(now)) ||
          pendingInvalid) {
        await store.renewDeliveryLock();
        await gateway.cancel(value['id'] as int);
        if (obsoleteKind || at.isAfter(now)) {
          await store.write(entry.key, {...value, 'state': 'cancelled'});
        }
      }
    }
    var nextId = max(
      prefs.getInt('notification_next_id') ?? 100000,
      stored.values.fold<int>(99999, (n, v) => max(n, v['id'] as int)) + 1,
    );
    for (final candidate in selected) {
      await store.renewDeliveryLock();
      await prefs.reload();
      if (_suspended ||
          capturedScope != scope ||
          !enabled ||
          prefs.getBool('notification_resetting') == true)
        return;
      final key = 'schedule:${candidate.key}';
      final previous = stored[key];
      final fingerprint = jsonEncode([
        scope,
        candidate.at.millisecondsSinceEpoch,
        LocaleSettings.currentLocale.languageCode,
        candidate.bodyKey,
        candidate.arguments,
        candidate.metadata,
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
        'metadata': candidate.metadata,
        'fingerprint': fingerprint,
        'state': 'pending',
      };
      await store.write(key, record);
      if (await gateway.schedule(id, candidate, scope)) {
        await store.write(key, {...record, 'state': 'scheduled'});
      }
    }
    await prefs.setInt('notification_next_id', nextId);
    await _recordReconcileMetrics(stopwatch, (await gateway.pending()).length);
    await _pruneLedger(now);
    notifyListeners();
  }

  Future<void> _observeDueAndActive(
    Map<String, Map<String, dynamic>> stored,
    DateTime now,
  ) async {
    final writes = <String, Map<String, dynamic>>{};
    Set<int> activeIds = const {};
    try {
      activeIds = (await gateway.active())
          .map((item) => item.id)
          .whereType<int>()
          .toSet();
    } catch (_) {
      // Best-effort metric: iOS and some Android versions may not expose it.
    }
    for (final entry in stored.entries) {
      final value = entry.value;
      final at = value['at'];
      if (at is! int || value['state'] != 'scheduled') continue;
      final next = <String, dynamic>{...value};
      var changed = false;
      if (at <= now.millisecondsSinceEpoch && value['dueAt'] == null) {
        next['dueAt'] = now.millisecondsSinceEpoch;
        changed = true;
      }
      if (activeIds.contains(value['id']) &&
          value['activeObservedAt'] == null) {
        next['activeObservedAt'] = now.millisecondsSinceEpoch;
        changed = true;
      }
      if (changed) writes[entry.key] = next;
    }
    if (writes.isNotEmpty) await store.writeBatch(writes);
  }

  Future<void> _recordReconcileMetrics(Stopwatch stopwatch, int pending) async {
    stopwatch.stop();
    await prefs.setInt(
      'notification_last_reconciled_at',
      DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setInt(
      'notification_last_reconcile_duration_ms',
      stopwatch.elapsedMilliseconds,
    );
    await prefs.setInt('notification_pending_count', pending);
  }

  Future<void> _pruneLedger(DateTime now) async {
    final scheduleCutoff = now.subtract(const Duration(days: 90));
    final expired = <String>[];
    for (final entry in (await store.all('schedule:')).entries) {
      final at = entry.value['at'];
      if (at is int &&
          DateTime.fromMillisecondsSinceEpoch(at).isBefore(scheduleCutoff)) {
        expired.add(entry.key);
      }
    }
    final eventCutoff = now.subtract(const Duration(days: 30));
    for (final entry in (await store.all('event:')).entries) {
      final at = entry.value['at'];
      if (at is int &&
          DateTime.fromMillisecondsSinceEpoch(at).isBefore(eventCutoff)) {
        expired.add(entry.key);
      }
    }
    await store.removeBatch(expired);
  }

  List<ReminderCandidate> _pinNearTermCandidates(
    List<ReminderCandidate> candidates,
    Map<String, Map<String, dynamic>> stored,
    DateTime now,
  ) {
    final freezeUntil = now.add(const Duration(hours: 24));
    return candidates.map((candidate) {
      if (candidate.kind == ReminderKind.workout) return candidate;
      final previous = stored['schedule:${candidate.key}'];
      final atValue = previous?['at'];
      if (previous?['state'] != 'scheduled' || atValue is! int) {
        return candidate;
      }
      final previousAt = DateTime.fromMillisecondsSinceEpoch(atValue);
      if (!previousAt.isAfter(now) || previousAt.isAfter(freezeUntil)) {
        return candidate;
      }
      final options = <ReminderCandidate>[
        candidate,
        ...candidate.alternatives.map(candidate.atOption),
      ];
      final match = options.indexWhere(
        (option) =>
            option.at.millisecondsSinceEpoch ==
            previousAt.millisecondsSinceEpoch,
      );
      if (match < 0) return candidate;
      final pinned = options[match];
      return pinned.copyWith(
        alternatives: [
          for (var i = 0; i < options.length; i++)
            if (i != match)
              ReminderDeliveryOption(
                at: options[i].at,
                titleKey: options[i].titleKey,
                bodyKey: options[i].bodyKey,
                arguments: options[i].arguments,
              ),
        ],
      );
    }).toList();
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
      'cardOnly': true,
      'rankId': latest.rankId,
      'route': '/social/rank_screen',
    };
    await store.writeBatch(writes);
  }

  /// Called before clearing account data. Wait for in-flight scheduling first.
  Future<void> reset() async {
    _suspended = true;
    await prefs.setBool('notification_resetting', true);
    await _work;
    await _eventWork;
    await store.withDeliveryLock(() async {
      await gateway.clearOwned();
      await db.notificationDao.clear();
    });
    await prefs.remove('saved_water_target');
    await prefs.remove('notification_water');
    await prefs.setString(
      'notification_scope',
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    _scope = scope;
    _preferences = await preferencesStore.load(scope);
    activeWorkout = false;
    activeScheduleId = null;
    levelHandledThrough = 0;
  }

  Future<void> resumeAfterReset() async {
    await prefs.remove('notification_resetting');
    _suspended = false;
    requestReconcile();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconcileDebounce?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    if (instance == this) instance = null;
    super.dispose();
  }
}
