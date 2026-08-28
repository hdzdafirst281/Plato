import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';

import '../../../../core/worker/background_workout_service.dart';
import '../../../../core/utils/workout_permission_helper.dart';
import '../../data/models/workout_models.dart';
import 'active_session_cubit.dart';

class NextWorkoutTarget {
  final WorkoutExercise exercise;
  final int setIndex;
  NextWorkoutTarget({required this.exercise, required this.setIndex});
}

mixin SessionEffectMixin on Cubit<ActiveSessionState> {
  SharedPreferences get prefs;

  Timer? workoutTimerJob;
  Timer? restTimerJob;
  StreamSubscription? serviceReadySub;

  WorkoutSession? originalRoutine;
  DateTime? workoutStartTimeOffset;
  DateTime? restEndTime;
  String? lastInteractedExerciseId;

  static const String draftKey = 'DRAFT_WORKOUT_STATE';

  int? autoFinishDeadlineMillis;
  final ValueNotifier<bool> triggerAutoFinishDialog = ValueNotifier(false);
  final ValueNotifier<WorkoutSession?> autoFinishedSessionNotifier = ValueNotifier(null);

  bool checkAllSetsCompleted() {
    final session = state.activeWorkout;
    if (session == null || session.exercises.isEmpty) return false;
    bool hasAtLeastOneTargetSet = false;
    for (var ex in session.exercises) {
      if (ex.sets.isNotEmpty) hasAtLeastOneTargetSet = true;
      if (ex.sets.any((s) => !s.isCompleted)) return false;
    }
    return hasAtLeastOneTargetSet;
  }

  void evaluateAutoFinish() {
    if (checkAllSetsCompleted()) {
      if (autoFinishDeadlineMillis == null) {
        autoFinishDeadlineMillis = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
        triggerAutoFinishDialog.value = true;
        saveDraftToDisk();
      }
    } else {
      if (autoFinishDeadlineMillis != null) {
        autoFinishDeadlineMillis = null;
        saveDraftToDisk();
      }
    }
  }

  void minimizeMiniplayer() {
    emit(state.copyWith(isMiniplayerMinimized: true));
    saveDraftToDisk();
  }

  void maximizeMiniplayer() {
    emit(state.copyWith(isMiniplayerMinimized: false));
    saveDraftToDisk();
  }

  NextWorkoutTarget? getNextTarget() {
    final session = state.activeWorkout;
    if (session == null || session.exercises.isEmpty) return null;

    if (lastInteractedExerciseId != null) {
      final lastEx = session.exercises.where((e) => e.id == lastInteractedExerciseId).firstOrNull;
      if (lastEx != null) {
        final incompleteIndex = lastEx.sets.indexWhere((s) => !s.isCompleted);
        if (incompleteIndex != -1) {
          return NextWorkoutTarget(exercise: lastEx, setIndex: incompleteIndex + 1);
        }
      }
    }

    for (var ex in session.exercises) {
      final incompleteIndex = ex.sets.indexWhere((s) => !s.isCompleted);
      if (incompleteIndex != -1) {
        return NextWorkoutTarget(exercise: ex, setIndex: incompleteIndex + 1);
      }
    }
    return null;
  }

  Future<void> syncBackgroundNotification() async {
    final session = state.activeWorkout;
    if (session == null) return;

    final isEnabled = prefs.getBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey) ?? true;
    if (!isEnabled) {
      return; 
    }

    final isRunning = await FlutterBackgroundService().isRunning();

    if (!isRunning) {
      await BackgroundWorkoutService().safeStartService();
      return; 
    }

    _performNotificationUpdate(session);
  }

  void _performNotificationUpdate(WorkoutSession session) {
    final String rawRoutineName = session.name;
    final String routineName = t.translateDynamic(rawRoutineName);
    final int? startTimeMillis = workoutStartTimeOffset?.millisecondsSinceEpoch;

    if (session.exercises.isEmpty) {
      BackgroundWorkoutService().updateState(
        routineName,
        t.workout.status_working,
        startTimeMillis: startTimeMillis,
      );
      return;
    }

    final targetData = getNextTarget();
    final bool isAllDone = targetData == null;
    final bool isResting = state.restTimerSeconds > 0;

    if (isAllDone) {
      if (isResting) {
        BackgroundWorkoutService().startRestTimer(
          duration: state.restTimerSeconds,
          restTitle: '$routineName - ${t.workout.status_last_set_done}',
          nextBody: t.workout.msg_finish_prompt,
          postRestTitle: '$routineName - ${t.workout.status_workout_done}',
        );
      } else {
        BackgroundWorkoutService().updateState(
          '$routineName - ${t.workout.status_workout_done}',
          t.workout.msg_finish_prompt,
        );
      }
    } else {
      String rawName = targetData.exercise.exercise.name;
      String translatedName = t.translateDynamic(rawName);
      String setLabel = t.common.set;
      String setProgressStr = '$setLabel ${targetData.setIndex}/${targetData.exercise.sets.length}';
      String bodyContent = '$translatedName - $setProgressStr';

      if (isResting) {
        BackgroundWorkoutService().startRestTimer(
          duration: state.restTimerSeconds,
          restTitle: '$routineName - ${t.workout.status_resting}',
          nextBody: '${t.workout.lbl_next}: $bodyContent',
          postRestTitle: routineName,
        );
      } else {
        BackgroundWorkoutService().updateState(
          routineName, 
          '${t.workout.status_working}: $bodyContent',
          startTimeMillis: startTimeMillis, 
        );
      }
    }
  }
  
  Future<void> saveDraftToDisk() async {
    if (state.activeWorkout == null) {
      await prefs.remove(draftKey);
      return;
    }
    try {
      final draftData = {
        'activeWorkout': state.activeWorkout!.toJson(),
        'workoutTimerSeconds': state.workoutTimerSeconds,
        'restTimerSeconds': state.restTimerSeconds,
        'originalRoutine': originalRoutine?.toJson(), 
        'workoutStartTimeOffset': workoutStartTimeOffset?.millisecondsSinceEpoch,
        'restEndTime': restEndTime?.millisecondsSinceEpoch,
        'lastInteractedExerciseId': lastInteractedExerciseId,
        'isMiniplayerMinimized': state.isMiniplayerMinimized, 
        'autoFinishDeadlineMillis': autoFinishDeadlineMillis,
      };
      await prefs.setString(draftKey, jsonEncode(draftData));
    } catch (e) {
      debugPrint("Lỗi lưu nháp buổi tập: $e");
    }
  }

  void loadDraftFromDisk() async {
    try {
      final draftString = prefs.getString(draftKey);
      if (draftString != null && draftString.isNotEmpty) {
        final draftData = jsonDecode(draftString) as Map<String, dynamic>;
        
        final workout = WorkoutSession.fromJson(draftData['activeWorkout']);
        if (draftData['originalRoutine'] != null) {
          originalRoutine = WorkoutSession.fromJson(draftData['originalRoutine']);
        }
        final offsetMillis = draftData['workoutStartTimeOffset'] as int?;
        if (offsetMillis != null) {
          workoutStartTimeOffset = DateTime.fromMillisecondsSinceEpoch(offsetMillis);
        }
        final restEndMillis = draftData['restEndTime'] as int?;
        if (restEndMillis != null) {
          restEndTime = DateTime.fromMillisecondsSinceEpoch(restEndMillis);
        }
        
        lastInteractedExerciseId = draftData['lastInteractedExerciseId'] as String?;
        final isMinimized = draftData['isMiniplayerMinimized'] as bool? ?? false; 

        autoFinishDeadlineMillis = draftData['autoFinishDeadlineMillis'] as int?;

        int timer = draftData['workoutTimerSeconds'] as int? ?? 0;
        if (workoutStartTimeOffset != null) {
          timer = DateTime.now().difference(workoutStartTimeOffset!).inSeconds;
          if (timer < 0) timer = 0;
        }

        bool isExpired10h = timer >= 36000;
        bool isExpired5m = autoFinishDeadlineMillis != null && DateTime.now().millisecondsSinceEpoch >= autoFinishDeadlineMillis!;

        if (isExpired10h || isExpired5m) {
          (this as ActiveSessionCubit).finishWorkout(
             isAutoFinish: true, 
             targetSession: workout, 
             targetDuration: timer
          );
          BackgroundWorkoutService().stopService();
          return; 
        }

        int restTimer = draftData['restTimerSeconds'] as int? ?? 0;
        if (restEndTime != null) {
          restTimer = restEndTime!.difference(DateTime.now()).inSeconds;
          if (restTimer < 0) restTimer = 0;
        }
        if (restTimer <= 0) restEndTime = null;

        emit(state.copyWith(
          activeWorkout: workout,
          workoutTimerSeconds: timer,
          restTimerSeconds: restTimer,
          isMiniplayerMinimized: isMinimized, 
        ));

        resumeWorkoutTimer();
        
        if (restTimer > 0) {
          startLocalRestTimer();
        } 
        
        syncBackgroundNotification();
      } else {
        BackgroundWorkoutService().stopService();
      }
    } catch (e) {
      prefs.remove(draftKey); 
      BackgroundWorkoutService().stopService();
    }
  }

  void resumeWorkoutTimer() {
    if (workoutTimerJob == null || !workoutTimerJob!.isActive) startTimer();
  }

  void pauseWorkoutTimer() {
    workoutTimerJob?.cancel();
  }

  void syncCardioCountdownNotification(int durationSeconds, String title, String body) {
    FlutterBackgroundService().invoke('START_CARDIO_COUNTDOWN', {
      'duration': durationSeconds,
      'cardioTitle': title,
      'bodyContent': body,
    });
  }

  void startTimer() {
    workoutTimerJob?.cancel();
    workoutStartTimeOffset ??= DateTime.now().subtract(Duration(seconds: state.workoutTimerSeconds));
    
    workoutTimerJob = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (workoutStartTimeOffset != null) {
        final newSeconds = DateTime.now().difference(workoutStartTimeOffset!).inSeconds;
        
        if (newSeconds >= 36000) {
           (this as ActiveSessionCubit).finishWorkout(isAutoFinish: true); 
           return;
        }

        if (autoFinishDeadlineMillis != null) {
           if (DateTime.now().millisecondsSinceEpoch >= autoFinishDeadlineMillis!) {
              (this as ActiveSessionCubit).finishWorkout(isAutoFinish: true); 
              return;
           }
        }

        emit(state.copyWith(workoutTimerSeconds: newSeconds));
      }
    });
  }

  void startRestTimer(int durationInSeconds) {
    if (durationInSeconds <= 0) {
      skipRestTimer(); 
      return;
    }
    restTimerJob?.cancel();
    
    restEndTime = DateTime.now().add(Duration(seconds: durationInSeconds));
    emit(state.copyWith(restTimerSeconds: durationInSeconds));
    
    syncBackgroundNotification(); 
    startLocalRestTimer();
  }

  void startLocalRestTimer() {
    restTimerJob?.cancel();
    restTimerJob = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restEndTime != null) {
        final remaining = restEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          emit(state.copyWith(restTimerSeconds: remaining));
        } else {
          timer.cancel();
          restEndTime = null; 
          emit(state.copyWith(restTimerSeconds: 0));
        }
      }
    });
  }

  void skipRestTimer() {
    restTimerJob?.cancel();
    restEndTime = null;
    emit(state.copyWith(restTimerSeconds: 0));
    syncBackgroundNotification(); 
  }

  void adjustRestTimer(int deltaSeconds) {
    if (state.restTimerSeconds <= 0 && deltaSeconds < 0) return;
    final newTime = state.restTimerSeconds + deltaSeconds;
    
    if (newTime <= 0) {
      skipRestTimer();
    } else {
      if (restEndTime != null) {
        restEndTime = restEndTime!.add(Duration(seconds: deltaSeconds));
      } else {
        restEndTime = DateTime.now().add(Duration(seconds: newTime));
      }
      
      emit(state.copyWith(restTimerSeconds: newTime));
      
      syncBackgroundNotification();
      
      if (restTimerJob == null || !restTimerJob!.isActive) {
         startLocalRestTimer();
      }
    }
  }
}