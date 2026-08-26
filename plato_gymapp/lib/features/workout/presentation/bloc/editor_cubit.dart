import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_repository.dart';

part 'editor_cubit.freezed.dart';

// --- 1. ĐỊNH NGHĨA STATE (Đã bỏ exercises) ---
@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    WorkoutSession? routineToEdit,
    @Default(false) bool isLoading,
  }) = _EditorState;
}

// --- 2. ĐỊNH NGHĨA CUBIT ---
@injectable 
class EditorCubit extends Cubit<EditorState> {
  // Đã xóa ExerciseRepository
  final WorkoutRepository _workoutRepo;
  
  // THÊM BIẾN TẠM: Để ghi nhớ xem user đang bấm dấu + ở Program nào
  String _targetProgramName = "";

  EditorCubit(this._workoutRepo) : super(const EditorState());

  void setRoutineToEdit(WorkoutSession? routine, {String targetProgramName = ""}) {
    _targetProgramName = targetProgramName;
    emit(state.copyWith(routineToEdit: routine));
  }

  void initNewRoutineFromHistory(WorkoutSession session) {
    _targetProgramName = ""; 
    const uuid = Uuid();
    
    final templateExercises = session.exercises.map((we) {
      final resetSets = we.sets.map((s) => s.copyWith(
        id: uuid.v4(),
        isCompleted: false 
      )).toList();

      return we.copyWith(
        id: uuid.v4(),
        sets: resetSets
      );
    }).toList();

    final templateRoutine = session.copyWith(
      id: "NEW_FROM_HISTORY_${session.id}", 
      name: session.name,
      programName: null, 
      sessionPayload: session.sessionPayload.copyWith(exercises: templateExercises)
    );

    emit(state.copyWith(routineToEdit: templateRoutine));
  }

  Future<void> createRoutine(String routineNameInput, List<WorkoutExercise> routineExercisesList) async {
    List<WorkoutSession> currentRoutines = [];
    try {
      currentRoutines = await _workoutRepo.routinesStream.first.timeout(const Duration(seconds: 2));
    } catch (_) {}

    final existingRoutineNames = currentRoutines
        .where((r) => (r.programName ?? "").trim() == _targetProgramName.trim())
        .map((r) => r.name)
        .toList();

    String validatedUniqueRoutineName = routineNameInput;
    int namingCounter = 1;
    while (existingRoutineNames.contains(validatedUniqueRoutineName)) {
      validatedUniqueRoutineName = "$routineNameInput ($namingCounter)";
      namingCounter++;
    }

    await _workoutRepo.createRoutine(validatedUniqueRoutineName, _targetProgramName, routineExercisesList);
  }

  Future<void> updateRoutine(String routineId, String updatedRoutineName, List<WorkoutExercise> updatedExercisesList) async {
    if (routineId.startsWith("NEW_FROM_HISTORY_")) {
      await createRoutine(updatedRoutineName, updatedExercisesList);
      return;
    }
    
    await _workoutRepo.updateRoutine(routineId, updatedRoutineName, updatedExercisesList);
  }
}