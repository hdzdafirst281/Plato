import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:plato_gymapp/core/worker/sync_manager.dart';
import 'package:plato_gymapp/features/workout/data/repositories/exercise_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/i18n/strings.g.dart'; 

import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';
import '../../../../core/worker/background_workout_service.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../gamification/data/repositories/gamification_repository.dart';

import 'session_effect_mixin.dart'; // <-- IMPORT MIXIN MỚI

part 'active_session_cubit.freezed.dart';

@freezed
class ActiveSessionState with _$ActiveSessionState {
  const factory ActiveSessionState({
    WorkoutSession? activeWorkout,
    @Default(0) int workoutTimerSeconds,
    @Default(0) int restTimerSeconds,
    @Default(false) bool isLoading,
    @Default(false) bool isMiniplayerMinimized, 
  }) = _ActiveSessionState;
}

@injectable
class ActiveSessionCubit extends Cubit<ActiveSessionState> with WidgetsBindingObserver, SessionEffectMixin {
  final WorkoutRepository _workoutRepo;
  final GamificationRepository _gamificationRepo;
  final AuthRepository _authRepo;
  final SharedPreferences _prefs; 
  final ExerciseRepository _exerciseRepo;

  static const _uuid = Uuid();

  // Bắt buộc khai báo để Mixin có thể sử dụng
  @override
  SharedPreferences get prefs => _prefs;

  ActiveSessionCubit(
    this._workoutRepo, 
    this._gamificationRepo, 
    this._authRepo, 
    this._prefs,
    this._exerciseRepo,
  ) : super(const ActiveSessionState()) {
    WidgetsBinding.instance.addObserver(this);
    
    serviceReadySub = BackgroundWorkoutService().onServiceReady.listen((_) {
      if (state.activeWorkout != null) {
        syncBackgroundNotification();
      } else {
        BackgroundWorkoutService().stopService();
      }
    });

    loadDraftFromDisk();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    workoutTimerJob?.cancel();
    restTimerJob?.cancel();
    serviceReadySub?.cancel();
    BackgroundWorkoutService().stopService(); 
    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      saveDraftToDisk();
    } else if (state == AppLifecycleState.resumed) {
      if (this.state.activeWorkout != null) {
         if (workoutStartTimeOffset != null) {
            final syncedWorkoutTime = DateTime.now().difference(workoutStartTimeOffset!).inSeconds;
            emit(this.state.copyWith(workoutTimerSeconds: syncedWorkoutTime));
         }

         int syncedRestTime = this.state.restTimerSeconds;
         if (restEndTime != null) {
            syncedRestTime = restEndTime!.difference(DateTime.now()).inSeconds;
            if (syncedRestTime < 0) syncedRestTime = 0;
            
            emit(this.state.copyWith(
               restTimerSeconds: syncedRestTime
            ));
            if (syncedRestTime <= 0) {
               restTimerJob?.cancel();
               restEndTime = null;
               syncBackgroundNotification(); 
            }
         }

         resumeWorkoutTimer();
         if (syncedRestTime > 0) {
           startLocalRestTimer(); 
         }
      }
    }
  }

  void startNewEmptyWorkout() async {
    autoFinishDeadlineMillis = null;
    triggerAutoFinishDialog.value = false;
    originalRoutine = null; 
    lastInteractedExerciseId = null;
    final newSession = WorkoutSession(
      id: _uuid.v4(), name: t.workout.title_new_workout, startTime: DateTime.now().millisecondsSinceEpoch,
      sessionPayload: const WorkoutSessionPayload(), updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    workoutStartTimeOffset = DateTime.now(); 
    emit(state.copyWith(activeWorkout: newSession, workoutTimerSeconds: 0, isMiniplayerMinimized: false)); 
    startTimer();
    
    syncBackgroundNotification(); 
    saveDraftToDisk(); 
  }

  List<ExerciseSet> _generateGhostSets(List<ExerciseSet> routineSets, List<ExerciseSet> historySets) {
    final int maxLen = max(routineSets.length, historySets.length);
    final List<ExerciseSet> ghostSets = [];

    for (int i = 0; i < maxLen; i++) {
      final rSet = i < routineSets.length ? routineSets[i] : null;
      final hSet = i < historySets.length ? historySets[i] : null;

      bool routineHasTarget = rSet != null && (
        rSet.weight > 0 || rSet.reps > 0 || rSet.durationTimeSeconds > 0 || 
        rSet.distanceInKm > 0 || rSet.steps > 0
      );

      if (routineHasTarget) {
        ghostSets.add(rSet);
      } else if (hSet != null) {
        ghostSets.add(hSet);
      } else {
        ghostSets.add(ExerciseSet(id: const Uuid().v4())); 
      }
    }
    return ghostSets;
  }

  Future<void> startRoutine(WorkoutSession routine) async {
    autoFinishDeadlineMillis = null;
    triggerAutoFinishDialog.value = false;
    final hydratedRoutine = await _workoutRepo.hydrateRoutine(routine);

    originalRoutine = hydratedRoutine; 
    lastInteractedExerciseId = null;

    final historyRecord = await _workoutRepo.workoutHistoryStream.first;
    final sortedHistory = historyRecord.toList()..sort((a, b) => b.startTime.compareTo(a.startTime));

    final preparedExercises = hydratedRoutine.exercises.map((templateEx) {
      final lastMatchedSession = sortedHistory.where((session) => 
          session.exercises.any((e) => e.exercise.id == templateEx.exercise.id)).firstOrNull;
      
      final historySetsList = lastMatchedSession?.exercises.firstWhere((e) => 
          e.exercise.id == templateEx.exercise.id).sets ?? [];

      final List<ExerciseSet> finalGhostSets = _generateGhostSets(templateEx.sets, historySetsList);

      return templateEx.copyWith(
        id: _uuid.v4(),
        previousSets: finalGhostSets, 
        sets: templateEx.sets.map((templateSet) {
          return templateSet.copyWith(
            id: _uuid.v4(), isCompleted: false, rpe: null, isPersonalRecord: false,
            weight: 0.0, reps: 0, durationTimeSeconds: 0, distanceInKm: 0.0, steps: 0,
          );
        }).toList(),
      );
    }).toList();

    final activeSession = hydratedRoutine.copyWith(
      id: _uuid.v4(), routineId: hydratedRoutine.id, startTime: DateTime.now().millisecondsSinceEpoch,
      sessionPayload: hydratedRoutine.sessionPayload.copyWith(exercises: preparedExercises),
    );

    workoutStartTimeOffset = DateTime.now(); 
    emit(state.copyWith(activeWorkout: activeSession, workoutTimerSeconds: 0, isMiniplayerMinimized: false));
    startTimer();
    
    syncBackgroundNotification(); 
    saveDraftToDisk(); 
  }

  Future<void> addExercisesToActiveWorkout(List<Exercise> exercises) async {
    final currentSession = state.activeWorkout;
    if (currentSession == null || exercises.isEmpty) return;
    
    final historyRecord = await _workoutRepo.workoutHistoryStream.first;
    final sortedHistory = historyRecord.toList()..sort((a, b) => b.startTime.compareTo(a.startTime));

    List<WorkoutExercise> newExercises = [];
    for (var exerciseItem in exercises) {
      final lastMatchedSession = sortedHistory.where((session) => session.exercises.any((e) => e.exercise.id == exerciseItem.id)).firstOrNull;
      final historySetsList = lastMatchedSession?.exercises.firstWhere((e) => e.exercise.id == exerciseItem.id).sets ?? [];
      
      final inheritedRest = historySetsList.lastOrNull?.restTimeSeconds ?? 90;
      
      List<ExerciseSet> initialSets = [];
      if (historySetsList.isNotEmpty) {
        initialSets = historySetsList.map((s) => _createInitialSet(exerciseItem.type).copyWith(restTimeSeconds: inheritedRest)).toList();
      } else {
        initialSets = [_createInitialSet(exerciseItem.type).copyWith(restTimeSeconds: inheritedRest)];
      }
      
      newExercises.add(WorkoutExercise(
        id: _uuid.v4(), 
        exercise: exerciseItem, 
        restTimeSeconds: inheritedRest, 
        note: exerciseItem.userNote,
        previousSets: historySetsList,
        sets: initialSets 
      ));
    }
    final updatedPayload = currentSession.sessionPayload.copyWith(exercises: [...currentSession.sessionPayload.exercises, ...newExercises]);
    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: updatedPayload)));
    saveDraftToDisk();
    syncBackgroundNotification(); 
  }

  Future<void> replaceExercise(int indexToReplace, Exercise newExercise) async {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;
    final currentExercises = List<WorkoutExercise>.from(currentSession.exercises);
    
    if (indexToReplace >= 0 && indexToReplace < currentExercises.length) {
      final oldExercise = currentExercises[indexToReplace];
      final oldSets = oldExercise.sets;

      final historyRecord = await _workoutRepo.workoutHistoryStream.first;
      final sortedHistory = historyRecord.toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
      
      final lastMatchedSession = sortedHistory.where((session) => 
          session.exercises.any((e) => e.exercise.id == newExercise.id)).firstOrNull;
      final historySetsList = lastMatchedSession?.exercises.firstWhere((e) => 
          e.exercise.id == newExercise.id).sets ?? [];

      List<ExerciseSet> newSetsToInherit = [];
      if (oldSets.isEmpty) {
        newSetsToInherit.add(_createInitialSet(newExercise.type));
      } else {
        for (var oldSet in oldSets) {
          final newBaseSet = _createInitialSet(newExercise.type);
          newSetsToInherit.add(newBaseSet.copyWith(restTimeSeconds: oldSet.restTimeSeconds));
        }
      }
      
      currentExercises[indexToReplace] = WorkoutExercise(
        id: _uuid.v4(), 
        exercise: newExercise, 
        restTimeSeconds: oldExercise.restTimeSeconds, 
        previousSets: historySetsList, 
        sets: newSetsToInherit, 
        supersetId: oldExercise.supersetId,
      );
      
      if (lastInteractedExerciseId == oldExercise.id) {
        lastInteractedExerciseId = currentExercises[indexToReplace].id;
      }

      emit(state.copyWith(activeWorkout: currentSession.copyWith(
        sessionPayload: currentSession.sessionPayload.copyWith(exercises: currentExercises)
      )));
      saveDraftToDisk();
      syncBackgroundNotification(); 
    }
  }

  void cancelWorkout() {
    autoFinishDeadlineMillis = null;
    triggerAutoFinishDialog.value = false;
    workoutTimerJob?.cancel();
    restTimerJob?.cancel();
    BackgroundWorkoutService().stopService(); 
    originalRoutine = null;
    workoutStartTimeOffset = null;
    restEndTime = null;
    lastInteractedExerciseId = null;
    emit(state.copyWith(activeWorkout: null, workoutTimerSeconds: 0, restTimerSeconds: 0, isMiniplayerMinimized: false));
    _prefs.remove(SessionEffectMixin.draftKey); 
  }

  Map<String, dynamic> checkStructuralChanges() {
    if (originalRoutine == null || state.activeWorkout == null) {
      return {'hasChanges': false, 'added': 0, 'removed': 0, 'replaced': 0, 'reordered': false};
    }
    
    final origIds = originalRoutine!.exercises.map((e) => e.exercise.id).toList();
    final currIds = state.activeWorkout!.exercises.map((e) => e.exercise.id).toList();

    int rawAdded = currIds.where((id) => !origIds.contains(id)).length;
    int rawRemoved = origIds.where((id) => !currIds.contains(id)).length;

    int replaced = min(rawAdded, rawRemoved);
    int added = rawAdded - replaced;
    int removed = rawRemoved - replaced;

    final retainedOrig = origIds.where((id) => currIds.contains(id)).toList();
    final retainedCurr = currIds.where((id) => origIds.contains(id)).toList();

    bool isReordered = false;
    for (int i = 0; i < retainedOrig.length; i++) {
      if (retainedOrig[i] != retainedCurr[i]) {
        isReordered = true;
        break;
      }
    }

    return {
      'hasChanges': rawAdded > 0 || rawRemoved > 0 || isReordered,
      'added': added, 'removed': removed, 'replaced': replaced, 'reordered': isReordered,
    };
  }

  void cleanupActiveWorkout() {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;
    final cleanedExercises = currentSession.exercises.map((ex) {
      final completedSets = ex.sets.where((s) => s.isCompleted).toList();
      return ex.copyWith(sets: completedSets);
    }).where((ex) => ex.sets.isNotEmpty).toList();

    emit(state.copyWith(
      activeWorkout: currentSession.copyWith(
        sessionPayload: currentSession.sessionPayload.copyWith(exercises: cleanedExercises)
      )
    ));
    saveDraftToDisk();
    syncBackgroundNotification(); 
  }

  Future<void> finishWorkout({
    bool saveStructure = false, 
    bool saveAsNewRoutine = false, 
    bool isAutoFinish = false,
    WorkoutSession? targetSession,
    int? targetDuration,
  }) async {
    final session = targetSession ?? state.activeWorkout;
    if (session == null) return;

    if (targetSession == null) {
      autoFinishDeadlineMillis = null;
      triggerAutoFinishDialog.value = false;

      workoutTimerJob?.cancel();
      restTimerJob?.cancel();
      BackgroundWorkoutService().stopService(); 
      workoutStartTimeOffset = null;
      restEndTime = null;
    }

    final cleanedExercises = session.exercises.map((ex) {
      final completedSets = ex.sets.where((s) => s.isCompleted).toList();
      return ex.copyWith(sets: completedSets);
    }).where((ex) => ex.sets.isNotEmpty).toList();

    // LOGIC CHUẨN HÓA TEMPLATE THEO TIMER MODE
    final structureToSave = cleanedExercises.map((e) => e.copyWith(
      sets: e.sets.map((s) {
        // Nếu là Stopwatch, template lưu thành 00:00. Nếu Countdown, giữ nguyên mục tiêu.
        int templateTime = s.timerMode == TimerMode.STOPWATCH ? 0 : s.durationTimeSeconds;
        
        return s.copyWith(
          isCompleted: false, 
          durationTimeSeconds: templateTime, 
          // BẢO TOÀN TRẠNG THÁI: Không dùng NONE, giữ nguyên MODE đã được xác định của Set
          timerMode: s.timerMode, 
        );
      }).toList()
    )).toList();

    final finalDuration = targetDuration ?? state.workoutTimerSeconds;

    final temporarySession = session.copyWith(
      sessionPayload: session.sessionPayload.copyWith(exercises: cleanedExercises),
      totalDurationSeconds: finalDuration,
      endTime: DateTime.now().millisecondsSinceEpoch,
      rpe: isAutoFinish ? (session.rpe ?? 5) : session.rpe,
    );

    final savedSessionWithRealPR = await _workoutRepo.saveFinishedWorkout(temporarySession);
    final int calculatedXp = _gamificationRepo.calculateXpForSession(savedSessionWithRealPR);

    final finalSession = savedSessionWithRealPR.copyWith(xpEarned: calculatedXp);
    await _workoutRepo.saveFinishedWorkout(finalSession);

    final currentUserProfile = _authRepo.getProfile();
    final updatedHistory = await _workoutRepo.workoutHistoryStream.first;

    await _gamificationRepo.evaluateAndLogRankChange(
      workoutsHistoryList: updatedHistory,
      userProfileData: currentUserProfile,
      onRankChangedAction: (history, rankId, rp) async {
        await _authRepo.saveProfile(currentUserProfile.copyWith(
          experiencePoints: currentUserProfile.experiencePoints + calculatedXp,
          currentRp: rp,
          activeRankId: rankId,
          rankAdvancementHistory: history,
        ));
      },
    );

    if (finalSession.routineId != null && originalRoutine != null) {
      if (saveStructure) {
        await _workoutRepo.updateRoutine(finalSession.routineId!, finalSession.name, structureToSave);
      } else {
        final updatedTemplateExercises = originalRoutine!.exercises.map((origEx) {
           final performedEx = structureToSave.firstWhere((e) => e.exercise.id == origEx.exercise.id, orElse: () => origEx);
           if (performedEx == origEx) return origEx; 
           return performedEx;
        }).toList();
        await _workoutRepo.updateRoutine(finalSession.routineId!, finalSession.name, updatedTemplateExercises);
      }
    } else if (saveAsNewRoutine) {
      await _workoutRepo.createRoutine(finalSession.name, finalSession.programName ?? "Routine của tôi", structureToSave);
    }

    if (isAutoFinish) {
      autoFinishedSessionNotifier.value = finalSession;
    }

    if (targetSession == null) {
      originalRoutine = null;
      lastInteractedExerciseId = null;
      emit(state.copyWith(activeWorkout: null, workoutTimerSeconds: 0, restTimerSeconds: 0, isMiniplayerMinimized: false));
      _prefs.remove(SessionEffectMixin.draftKey); 
    } else {
      _prefs.remove(SessionEffectMixin.draftKey); 
    }

    SyncManager.syncNow().catchError((e) {
      debugPrint("Lỗi Auto Sync ngầm: $e");
      return false;
    });
    SyncManager.scheduleBackgroundSync();
  }
  
  void updateSet(String exerciseId, String setId, bool isCompletedFlag, {
    double? weight, int? reps, double? distance, int? steps, int? time, int? rpe, SetType? type, TimerMode? timerMode
  }) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;
    
    lastInteractedExerciseId = exerciseId;

    bool willStartRest = false;
    int restTimeForThisSet = 0;

    final updatedExercises = currentSession.exercises.map((ex) {
      if (ex.id == exerciseId) {
        return ex.copyWith(
          sets: ex.sets.asMap().entries.map((entry) {
            final set = entry.value;

            if (set.id == setId) {
              if (!set.isCompleted && isCompletedFlag) {
                willStartRest = true;
                restTimeForThisSet = set.restTimeSeconds;
              } 
              return set.copyWith(
                weight: weight ?? set.weight, reps: reps ?? set.reps, distanceInKm: distance ?? set.distanceInKm, 
                steps: steps ?? set.steps, durationTimeSeconds: time ?? set.durationTimeSeconds, rpe: rpe ?? set.rpe, 
                isCompleted: isCompletedFlag, type: type ?? set.type, timerMode: timerMode ?? set.timerMode,
              );
            }
            return set;
          }).toList()
        );
      }
      return ex;
    }).toList();
    
    final targetEx = updatedExercises.firstWhere((e) => e.id == exerciseId);
    if (!targetEx.sets.any((s) => s.isCompleted)) {
      lastInteractedExerciseId = null;
    }

    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: updatedExercises))));
    saveDraftToDisk();
    evaluateAutoFinish();

    if (willStartRest && restTimeForThisSet > 0) {
      startRestTimer(restTimeForThisSet);
    } else {
      syncBackgroundNotification();
    }
  }

  void updateExerciseRestTime(String exerciseId, int newRestTimeSeconds) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;
    final updatedExercises = currentSession.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final updatedSets = ex.sets.map((set) => set.copyWith(restTimeSeconds: newRestTimeSeconds)).toList();
        return ex.copyWith(
          restTimeSeconds: newRestTimeSeconds, 
          sets: updatedSets
        );
      }
      return ex;
    }).toList();
    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: updatedExercises))));
    saveDraftToDisk();
  }

  ExerciseSet _createInitialSet(ExerciseType type) {
    final typeName = type.name.toUpperCase();
    if (typeName.contains('DISTANCE')) {
      return ExerciseSet(id: _uuid.v4(), distanceInKm: 0.0, durationTimeSeconds: 0);
    } else if (typeName.contains('STEPS')) {
      return ExerciseSet(id: _uuid.v4(), steps: 0, durationTimeSeconds: 0);
    } else if (typeName.contains('TIME') && !typeName.contains('WEIGHT')) {
      return ExerciseSet(id: _uuid.v4(), durationTimeSeconds: 0);
    } else if (typeName.contains('TIME') && typeName.contains('WEIGHT')) {
      return ExerciseSet(id: _uuid.v4(), weight: 0.0, durationTimeSeconds: 0);
    } else {
      return ExerciseSet(id: _uuid.v4(), weight: 0.0, reps: 0);
    }
  }

  void removeExercise(int indexToRemove) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;
    final currentExercises = List<WorkoutExercise>.from(currentSession.exercises);
    if (indexToRemove >= 0 && indexToRemove < currentExercises.length) {
      final removedId = currentExercises[indexToRemove].id;
      currentExercises.removeAt(indexToRemove);
      
      if (lastInteractedExerciseId == removedId) {
        lastInteractedExerciseId = null;
      }
      
      emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: currentExercises))));
      saveDraftToDisk();
      syncBackgroundNotification(); 
    }
  }

  void updateExerciseNote(String workoutExerciseId, String newNote) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;

    String? globalExerciseId; 

    final updatedExercises = currentSession.exercises.map((ex) {
      if (ex.id == workoutExerciseId) {
        globalExerciseId = ex.exercise.id; 
        return ex.copyWith(note: newNote);
      }
      return ex;
    }).toList();

    emit(state.copyWith(
      activeWorkout: currentSession.copyWith(
        sessionPayload: currentSession.sessionPayload.copyWith(exercises: updatedExercises)
      )
    ));
    saveDraftToDisk();

    if (globalExerciseId != null) {
      _exerciseRepo.updateUserNoteGlobal(globalExerciseId!, newNote);
    }
  }

  void reorderExercises(List<WorkoutExercise> reorderedList) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;
    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: reorderedList))));
    saveDraftToDisk();
    syncBackgroundNotification(); 
  }

  void removeSet(String exerciseId, String setId) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;

    final updatedExercises = currentSession.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final newSets = ex.sets.where((s) => s.id != setId).toList();
        return ex.copyWith(sets: newSets);
      }
      return ex;
    }).toList();
    
    if (lastInteractedExerciseId == exerciseId) {
      final targetEx = updatedExercises.firstWhere((e) => e.id == exerciseId);
      if (!targetEx.sets.any((s) => s.isCompleted)) {
        lastInteractedExerciseId = null;
      }
    }
    
    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: updatedExercises))));
    saveDraftToDisk();
    syncBackgroundNotification(); 
  }

  void addSetToExercise(String exerciseId) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;

    final updatedExercises = currentSession.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final lastSet = ex.sets.lastOrNull;
        final newSet = lastSet?.copyWith(id: _uuid.v4(), isCompleted: false) ?? ExerciseSet(id: _uuid.v4());
        return ex.copyWith(sets: [...ex.sets, newSet]);
      }
      return ex;
    }).toList();
    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: updatedExercises))));
    saveDraftToDisk();
    syncBackgroundNotification(); 
  }

  void linkToSuperset(String sourceExerciseId, List<String> targetExerciseIds) {
    final currentSession = state.activeWorkout;
    if (currentSession == null || targetExerciseIds.isEmpty) return;

    final currentExercises = List<WorkoutExercise>.from(currentSession.exercises);
    
    final sourceIndexRaw = currentExercises.indexWhere((e) => e.id == sourceExerciseId);
    if (sourceIndexRaw == -1) return;
    
    final targets = currentExercises.where((e) => targetExerciseIds.contains(e.id)).toList();
    final String sId = targets.firstWhere((e) => e.supersetId != null, orElse: () => targets.first).supersetId ?? const Uuid().v4();

    final allTargetIdsInGroup = currentExercises.where((e) => 
        targetExerciseIds.contains(e.id) || (e.supersetId != null && e.supersetId == sId)
    ).map((e) => e.id).toList();

    final targetExercisesToMove = currentExercises.where((e) => allTargetIdsInGroup.contains(e.id)).toList();
    currentExercises.removeWhere((e) => allTargetIdsInGroup.contains(e.id));

    final sourceIndex = currentExercises.indexWhere((e) => e.id == sourceExerciseId);
    currentExercises[sourceIndex] = currentExercises[sourceIndex].copyWith(supersetId: sId);
    
    for (int i = 0; i < targetExercisesToMove.length; i++) {
       targetExercisesToMove[i] = targetExercisesToMove[i].copyWith(supersetId: sId);
    }

    currentExercises.insertAll(sourceIndex + 1, targetExercisesToMove);

    final finalSupersetExs = currentExercises.where((e) => e.supersetId == sId).toList();
    for (int i = 0; i < finalSupersetExs.length; i++) {
      final isLast = i == finalSupersetExs.length - 1;
      final exId = finalSupersetExs[i].id;
      final exIndexInMain = currentExercises.indexWhere((e) => e.id == exId);
      
      final currentEx = currentExercises[exIndexInMain];
      final newRestTime = isLast ? (currentEx.restTimeSeconds == 0 ? 90 : currentEx.restTimeSeconds) : 0;

      final updatedSets = currentEx.sets.map((s) {
        return s.copyWith(restTimeSeconds: newRestTime);
      }).toList();

      currentExercises[exIndexInMain] = currentEx.copyWith(
        restTimeSeconds: newRestTime, 
        sets: updatedSets
      );
    }

    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: currentExercises))));
    saveDraftToDisk();
    syncBackgroundNotification();
  }

  void removeFromSuperset(String exerciseId) {
    final currentSession = state.activeWorkout;
    if (currentSession == null) return;

    final currentExercises = List<WorkoutExercise>.from(currentSession.exercises);
    final exIndex = currentExercises.indexWhere((e) => e.id == exerciseId);
    if (exIndex == -1) return;

    final targetEx = currentExercises[exIndex];
    if (targetEx.supersetId == null) return;

    final sId = targetEx.supersetId!;
    final newRestTime = targetEx.restTimeSeconds == 0 ? 90 : targetEx.restTimeSeconds;

    currentExercises[exIndex] = targetEx.copyWith(
      supersetId: null,
      restTimeSeconds: newRestTime, 
      sets: targetEx.sets.map((s) => s.copyWith(restTimeSeconds: newRestTime)).toList(),
    );

    final remaining = currentExercises.where((e) => e.supersetId == sId).toList();
    if (remaining.length == 1) {
      final lastExIndex = currentExercises.indexWhere((e) => e.id == remaining.first.id);
      currentExercises[lastExIndex] = currentExercises[lastExIndex].copyWith(supersetId: null);
    } else if (remaining.isNotEmpty) {
      final lastEx = remaining.last;
      final lastExIndex = currentExercises.indexWhere((e) => e.id == lastEx.id);
      final lastNewRestTime = lastEx.restTimeSeconds == 0 ? 90 : lastEx.restTimeSeconds;

      currentExercises[lastExIndex] = lastEx.copyWith(
        restTimeSeconds: lastNewRestTime, 
        sets: lastEx.sets.map((s) => s.copyWith(restTimeSeconds: lastNewRestTime)).toList(),
      );
    }

    emit(state.copyWith(activeWorkout: currentSession.copyWith(sessionPayload: currentSession.sessionPayload.copyWith(exercises: currentExercises))));
    saveDraftToDisk();
    syncBackgroundNotification();
  }
}