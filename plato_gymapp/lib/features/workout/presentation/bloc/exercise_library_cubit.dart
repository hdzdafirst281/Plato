import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/entities.dart';
import '../../data/repositories/exercise_repository.dart';

part 'exercise_library_cubit.freezed.dart';

// --- 1. ĐỊNH NGHĨA STATE ---
@freezed
class ExerciseLibraryState with _$ExerciseLibraryState {
  const factory ExerciseLibraryState({
    @Default([]) List<Exercise> exercises,
    @Default(false) bool isLoading,
  }) = _ExerciseLibraryState;
}

// --- 2. ĐỊNH NGHĨA CUBIT ---
@lazySingleton // Sử dụng lazySingleton để Cubit này sống xuyên suốt vòng đời app
class ExerciseLibraryCubit extends Cubit<ExerciseLibraryState> {
  final ExerciseRepository _exerciseRepo;
  
  StreamSubscription? _exerciseSubscription;

  ExerciseLibraryCubit(this._exerciseRepo) : super(const ExerciseLibraryState()) {
    // Tự động lắng nghe thay đổi từ database ngay khi khởi tạo
    _exerciseSubscription = _exerciseRepo.exercisesStream.listen((list) {
      emit(state.copyWith(exercises: list)); 
    });
  }

  @override
  Future<void> close() {
    _exerciseSubscription?.cancel(); 
    return super.close();
  }

  // Chuyển giao các hàm CRUD từ EditorCubit sang đây
  Future<void> createNewCustomExercise(Exercise newCustomExercise) async {
    emit(state.copyWith(isLoading: true));
    await _exerciseRepo.saveCustomExercise(newCustomExercise);
    emit(state.copyWith(isLoading: false));
  }

  Future<void> updateCustomExercise(Exercise updatedExercise) async {
    emit(state.copyWith(isLoading: true));
    await _exerciseRepo.saveCustomExercise(updatedExercise);
    emit(state.copyWith(isLoading: false));
  }

  Future<void> deleteCustomExercise(String exerciseId) async {
    emit(state.copyWith(isLoading: true));
    await _exerciseRepo.deleteCustomExercise(exerciseId);
    emit(state.copyWith(isLoading: false));
  }
}