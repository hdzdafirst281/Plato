import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:plato_gymapp/core/worker/sync_manager.dart';
import 'package:plato_gymapp/features/gamification/data/repositories/gamification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/enums.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

// Import Domain Logic & Components
import '../../domain/training_load_manager.dart';
import '../../domain/muscle_recovery_calculator.dart';
import '../components/workout_components.dart';

part 'workout_cubit.freezed.dart';

@freezed
class WorkoutState with _$WorkoutState {
  const factory WorkoutState({
    @Default([]) List<String> folderOrder,
    @Default([]) List<WorkoutSession> historicalWorkoutSessionsList, 
    @Default([]) List<WorkoutSession> userCustomRoutinesList,        
    @Default([]) List<WorkoutProgram> exploreProgramsList,
    @Default([]) List<RecoveryUIData> recoveryUIDataList,
    @Default([]) List<ScheduledWorkout> scheduledWorkoutsList, 
    @Default({}) Map<String, int> exerciseFrequencyMap,
  }) = _WorkoutState;
}

@injectable
class WorkoutCubit extends Cubit<WorkoutState> {
  final WorkoutRepository _workoutRepo;
  final AuthRepository _authRepo;
  final SharedPreferences _prefs; 
  final GamificationRepository _gamificationRepo;

  StreamSubscription? _historySub;
  StreamSubscription? _routinesSub;
  StreamSubscription? _programsSub; 
  StreamSubscription? _scheduledSub;

  static const String _folderOrderKey = 'WORKOUT_FOLDER_ORDER';

  WorkoutCubit(
    this._workoutRepo, 
    this._authRepo, 
    this._prefs,
    this._gamificationRepo,
  ) : super(const WorkoutState()) {
    _loadFolderOrder();
    _initStreams();
  }

  void _initStreams() {
    _historySub = _workoutRepo.workoutHistoryStream.listen((history) {
      emit(state.copyWith(historicalWorkoutSessionsList: history));
      _recalculateBackgroundData(history); 
    });

    _routinesSub = _workoutRepo.routinesStream.listen((dbRoutines) {
      if (state.userCustomRoutinesList.isNotEmpty) {
        final currentOrderIds = state.userCustomRoutinesList.map((r) => r.id).toList();
        
        final sortedRoutines = List<WorkoutSession>.from(dbRoutines);
        sortedRoutines.sort((a, b) {
          final indexA = currentOrderIds.indexOf(a.id);
          final indexB = currentOrderIds.indexOf(b.id);
          if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
          if (indexA != -1) return -1; 
          if (indexB != -1) return 1;
          return 0;
        });
        emit(state.copyWith(userCustomRoutinesList: sortedRoutines));
      } else {
        emit(state.copyWith(userCustomRoutinesList: dbRoutines));
      }
    });

    _programsSub = _workoutRepo.exploreProgramsStream.listen((programs) {
      emit(state.copyWith(exploreProgramsList: programs));
    });

    _scheduledSub = _workoutRepo.scheduledWorkoutsStream.listen((scheduled) {
      emit(state.copyWith(scheduledWorkoutsList: scheduled));
    });
  }

  @override
  Future<void> close() {
    _historySub?.cancel();
    _routinesSub?.cancel();
    _programsSub?.cancel(); 
    _scheduledSub?.cancel();
    return super.close();
  }

  void triggerSyncPrograms() {}

  List<String>? get personalRecordsSummary => _workoutRepo.prSummary;

  void _loadFolderOrder() {
    final order = _prefs.getStringList(_folderOrderKey) ?? [];
    emit(state.copyWith(folderOrder: order));
  }

  Future<void> saveFolderOrder(List<String> newlyConfiguredOrderList) async {
    emit(state.copyWith(folderOrder: newlyConfiguredOrderList));
    await _prefs.setStringList(_folderOrderKey, newlyConfiguredOrderList);
  }

  Future<void> createFolder(String folderName) async {
    final currentOrder = List<String>.from(state.folderOrder);
    
    String validatedUniqueFolderName = folderName;
    int namingCounter = 1;
    while (currentOrder.contains(validatedUniqueFolderName)) {
      validatedUniqueFolderName = "$folderName ($namingCounter)";
      namingCounter++;
    }

    currentOrder.add(validatedUniqueFolderName);
    await saveFolderOrder(currentOrder);
  }

  Future<void> deleteRoutine(String routineIdToRemove) async {
    await _workoutRepo.deleteRoutine(routineIdToRemove);
  }

  Future<void> duplicateRoutine(String routineIdToDuplicate) async {
    await _workoutRepo.duplicateRoutine(routineIdToDuplicate);
  }

  Future<void> renameFolder(String oldFolderNameString, String newFolderNameString) async {
    await _workoutRepo.renameFolder(oldFolderNameString, newFolderNameString);
    final currentOrder = List<String>.from(state.folderOrder);
    final targetedIndex = currentOrder.indexOf(oldFolderNameString);
    if (targetedIndex != -1) {
      currentOrder[targetedIndex] = newFolderNameString;
      saveFolderOrder(currentOrder);
    }
  }

  Future<void> deleteFolder(String folderNameToDeleteString) async {
    await _workoutRepo.deleteFolder(folderNameToDeleteString);
    final currentOrder = List<String>.from(state.folderOrder);
    if (currentOrder.remove(folderNameToDeleteString)) {
      saveFolderOrder(currentOrder);
    }
  }

  Future<void> addProgramRoutines(WorkoutProgram programDataToSave) async {
    await _workoutRepo.saveProgramRoutines(programDataToSave);
  }

  Future<void> moveAndReorderRoutine(String draggedId, String targetFolder, int targetLocalIndex, String defaultFolderName) async {
    final allRoutines = List<WorkoutSession>.from(state.userCustomRoutinesList);
    final draggedIndex = allRoutines.indexWhere((r) => r.id == draggedId);
    if (draggedIndex == -1) return;

    final draggedItem = allRoutines[draggedIndex];
    final sourceFolder = (draggedItem.programName?.trim().isNotEmpty == true) ? draggedItem.programName!.trim() : defaultFolderName;
    
    final currentFolderRoutines = allRoutines.where((r) {
      final fName = (r.programName?.trim().isNotEmpty == true) ? r.programName!.trim() : defaultFolderName;
      return fName == targetFolder;
    }).toList();

    String? targetRoutineId;
    if (targetLocalIndex < currentFolderRoutines.length) {
      targetRoutineId = currentFolderRoutines[targetLocalIndex].id;
    }

    if (targetRoutineId == draggedId) return; 

    int sourceLocalIndex = currentFolderRoutines.indexWhere((r) => r.id == draggedId);
    allRoutines.removeAt(draggedIndex);
    final actualFolderName = targetFolder == defaultFolderName ? "" : targetFolder;
    final updatedItem = draggedItem.copyWith(programName: actualFolderName);

    int insertIndex = 0;
    if (targetRoutineId != null) {
      int globalTargetIndex = allRoutines.indexWhere((r) => r.id == targetRoutineId);
      if (globalTargetIndex != -1) {
        if (sourceFolder == targetFolder && sourceLocalIndex != -1 && sourceLocalIndex < targetLocalIndex) {
          insertIndex = globalTargetIndex + 1;
        } else {
          insertIndex = globalTargetIndex;
        }
      }
    } else {
      final targetFolderItemsNow = allRoutines.where((r) {
        final fName = (r.programName?.trim().isNotEmpty == true) ? r.programName!.trim() : defaultFolderName;
        return fName == targetFolder;
      }).toList();
      
      if (targetFolderItemsNow.isNotEmpty) {
        int lastGlobalIndex = allRoutines.indexWhere((r) => r.id == targetFolderItemsNow.last.id);
        insertIndex = lastGlobalIndex + 1;
      } else {
        insertIndex = allRoutines.length; 
      }
    }

    allRoutines.insert(insertIndex, updatedItem);
    emit(state.copyWith(userCustomRoutinesList: allRoutines));
    
    if (sourceFolder != targetFolder) {
      await _workoutRepo.updateRoutineFolder(draggedId, actualFolderName);
    }
  }

  Future<void> scheduleRoutine(
    String routineId, 
    String routineName, 
    DateTime startDate, {
    int repeatType = 0, 
    List<int>? selectedWeekdays, 
    int occurrences = 999,
    int intervalDays = 1,
    String? colorHex,
  }) async {
    final recurrenceGroupId = const Uuid().v4();
    await _workoutRepo.scheduleWorkout(
      routineId, routineName, startDate,
      repeatType: repeatType, selectedWeekdays: selectedWeekdays, occurrences: occurrences, intervalDays: intervalDays, colorHex: colorHex, recurrenceGroupId: recurrenceGroupId,
    );
  }

  Future<void> removeScheduledWorkout(String scheduleId) async {
    await _workoutRepo.deleteScheduledWorkout(scheduleId);
  }

  Future<void> removeScheduledWorkoutGroup(String groupId) async {
    await _workoutRepo.deleteScheduledWorkoutGroup(groupId);
  }

  // ==========================================
  // QUẢN LÝ LỊCH SỬ TẬP LUYỆN
  // ==========================================
  Future<void> deleteWorkout(String workoutSessionIdToRemove) async {
    final sessionToDelete = state.historicalWorkoutSessionsList
        .where((s) => s.id == workoutSessionIdToRemove)
        .firstOrNull;

    // 🚀 FIX TẬN GỐC RACE CONDITION: Cập nhật XP trước khi xoá DB.
    if (sessionToDelete != null) {
      // 1. Tính toán điểm buổi tập gốc
      int workoutXp = sessionToDelete.xpEarned;
      if (workoutXp <= 0) workoutXp = _gamificationRepo.calculateXpForSession(sessionToDelete);

      final currentProfile = _authRepo.getProfile();
      
      // 2. Tính toán Quest XP rớt hạng dựa trên lịch sử giả lập
      final simulatedHistory = state.historicalWorkoutSessionsList
          .where((s) => s.id != workoutSessionIdToRemove).toList();
      
      await _gamificationRepo.auditSpecificWeek(sessionToDelete.startTime, simulatedHistory);

      final questXpToRollback = await _gamificationRepo.calculateWeeklyStats(
          workoutsList: simulatedHistory,
          userProfileData: currentProfile,
      );

      // 3. LƯU PROFILE (XP ĐÃ CẬP NHẬT, RP GIỮ NGUYÊN) TRƯỚC KHI KÍCH HOẠT STREAM
      int totalXpToDeduct = workoutXp + questXpToRollback;
      if (totalXpToDeduct > 0) {
        int newXp = currentProfile.experiencePoints - totalXpToDeduct;
        await _authRepo.saveProfile(
          currentProfile.copyWith(experiencePoints: newXp > 0 ? newXp : 0)
        );
      }
    }

    // 4. XÓA DB (Lúc này Stream phát ra, ProfileCubit đọc vào sẽ thấy XP đã lưu chuẩn và chỉ việc cập nhật RP).
    await _workoutRepo.deleteWorkout(workoutSessionIdToRemove);
    await SyncManager.syncNow();
  }

  void dismissPrDialog() {
    _workoutRepo.dismissPrDialog();
    emit(state.copyWith()); 
  }

  Future<void> updateSessionRpe(String sessionIdToUpdate, int newlyAssignedRpeValue) async {
    await _workoutRepo.updateSessionRpe(sessionIdToUpdate, newlyAssignedRpeValue);
  }

  Future<LoadAnalysis> getWeeklyLoadAnalysis() async {
    final currentHistory = state.historicalWorkoutSessionsList;
    return await compute(TrainingLoadManager.analyzeWeeklyLoad, currentHistory);
  }

  Future<void> _recalculateBackgroundData(List<WorkoutSession> history) async {
    final results = await Future.wait([
      compute(_calculateRecoveryInIsolate, history),
      compute(_calculateFrequencyInIsolate, history),
    ]);

    if (!isClosed) {
      emit(state.copyWith(
        recoveryUIDataList: results[0] as List<RecoveryUIData>,
        exerciseFrequencyMap: results[1] as Map<String, int>,
      ));
    }
  }

  static List<RecoveryUIData> _calculateRecoveryInIsolate(List<WorkoutSession> history) {
    final majorGroups = [
      MajorMuscleGroup.CHEST, MajorMuscleGroup.BACK, MajorMuscleGroup.LEGS,
      MajorMuscleGroup.SHOULDERS, MajorMuscleGroup.ARMS, MajorMuscleGroup.CORE
    ];

    return majorGroups.map((majorGroupEnum) {
      final associatedSubMuscles = MuscleGroup.values.where((m) => m.major == majorGroupEnum).toList();
      final recoveryStatuses = associatedSubMuscles.map(
        (m) => MuscleRecoveryCalculator.getRecoveryStatus(m, history)
      ).toList();

      final minRecovery = recoveryStatuses.isEmpty 
          ? MuscleRecoveryCalculator.getRecoveryStatus(MuscleGroup.FULL_BODY, history)
          : recoveryStatuses.reduce((curr, next) => curr.recoveryPercentage < next.recoveryPercentage ? curr : next);

      return RecoveryUIData("muscles.${majorGroupEnum.name.toLowerCase()}", minRecovery);
    }).toList();
  }

  static Map<String, int> _calculateFrequencyInIsolate(List<WorkoutSession> history) {
    final freqMap = <String, int>{};
    for (var session in history) {
      for (var ex in session.exercises) {
        freqMap[ex.exercise.id] = (freqMap[ex.exercise.id] ?? 0) + 1;
      }
    }
    return freqMap;
  }
  
  void updateGlobalRoutines(List<WorkoutSession> updatedRoutines) {
    emit(state.copyWith(userCustomRoutinesList: updatedRoutines));
  }

  void resetWorkoutState() {
    emit(WorkoutState(exploreProgramsList: state.exploreProgramsList));
    _loadFolderOrder(); 
    _workoutRepo.dismissPrDialog(); 
    _recalculateBackgroundData([]);
  }
}