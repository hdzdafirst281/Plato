import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_models.dart';
import '../../../workout/data/repositories/workout_repository.dart';

part 'onboarding_cubit.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(false) bool isLoading,
  }) = _OnboardingState;
}

@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  final AuthRepository _authRepo;
  final WorkoutRepository _workoutRepo;

  OnboardingCubit(this._authRepo, this._workoutRepo) : super(const OnboardingState());

  UserProfile calculateUserStats(UserProfile profileObject) {
    return _authRepo.recalculatePhysiologicalStats(profileObject);
  }

  Future<String> getSuggestedProgramName(UserProfile profile, String experienceLevelInput) async {
    final localPrograms = await _workoutRepo.exploreProgramsStream.first;
    const customProgramFallbackName = "Gói tập Tùy chỉnh";

    if (localPrograms.isEmpty) return customProgramFallbackName;

    String mappedDifficulty = "BEGINNER";
    if (experienceLevelInput == "Advanced") mappedDifficulty = "ADVANCED";
    if (experienceLevelInput == "Intermediate") mappedDifficulty = "INTERMEDIATE";

    final exactMatch = localPrograms.where((p) => 
        p.environment == profile.environment && 
        p.difficulty == mappedDifficulty && 
        p.goal == profile.workoutGoal
    ).firstOrNull;

    final partialMatch = localPrograms.where((p) => 
        p.environment == profile.environment && 
        p.difficulty == mappedDifficulty
    ).firstOrNull;

    final fallbackProgram = exactMatch ?? partialMatch ?? localPrograms.first;
    return fallbackProgram.name;
  }

  Future<void> completeOnboarding(UserProfile draftProfile, String experienceLevelInput, int estimatedGoalDurationInDays, Function onCompleteSuccess) async {
    emit(state.copyWith(isLoading: true));

    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    double? calculatedWeeklyRate;
    if (estimatedGoalDurationInDays > 0) {
      final weightGap = (draftProfile.targetGoalWeightKg ?? draftProfile.weightInKg) - draftProfile.weightInKg;
      calculatedWeeklyRate = (weightGap.abs() / estimatedGoalDurationInDays) * 7;
    }

    // ĐÃ REFACTOR: Bỏ initialRankId và initialRankHistory, trả về rank mặc định của object
    final profileWithNewStats = draftProfile.copyWith(
      weeklyGoalRate: calculatedWeeklyRate, 
      goalStartTimestampMillis: nowMillis, 
      startingWeightKg: draftProfile.weightInKg, 
      lastWeightUpdateTimestampMillis: nowMillis, 
    );

    final finalizedProfile = _authRepo.recalculatePhysiologicalStats(profileWithNewStats, keepExistingMacros: true);
    await _authRepo.saveProfile(finalizedProfile);
    await _authRepo.recordNewWeightMeasurement(finalizedProfile.weightInKg);

    emit(state.copyWith(isLoading: false));
    onCompleteSuccess(); 
  }
}