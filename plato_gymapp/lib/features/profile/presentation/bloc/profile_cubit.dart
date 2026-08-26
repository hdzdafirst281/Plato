import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/data/models/user_models.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../../workout/data/models/workout_models.dart';
import '../../../gamification/data/repositories/gamification_repository.dart';
import '../../../../core/database/enums.dart';

import '../../../nutrition/domain/nutrition_calculator.dart';
import '../../../nutrition/data/models/nutrition_models.dart';

part 'profile_cubit.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    required UserProfile userProfile,
    @Default(false) bool isUserLoggedIn,
  }) = _ProfileState;
}

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository _authRepo;
  final GamificationRepository _gamificationRepo;
  final WorkoutRepository _workoutRepo;

  StreamSubscription? _workoutHistorySubscription;
  StreamSubscription? _profileUpdateSubscription;

  ProfileCubit(
    this._authRepo,
    this._gamificationRepo,
    this._workoutRepo,
  ) : super(ProfileState(
          userProfile: _authRepo.getProfile(),
          isUserLoggedIn: _authRepo.isUserLoggedIn,
        )) {
    
    _profileUpdateSubscription = _authRepo.profileUpdateStream.listen((updatedProfile) {
      emit(state.copyWith(
        userProfile: updatedProfile,
        isUserLoggedIn: _authRepo.isUserLoggedIn,
      ));
    });

    _workoutHistorySubscription = _workoutRepo.workoutHistoryStream.listen((historicalSessions) async {

      // 1. Đọc lại Profile MỚI NHẤT từ Local Storage 
      final latestProfile = _authRepo.getProfile();
      
      // CRITICAL FIX: Bỏ điều kiện check ID để Local/Guest user vẫn được Audit điểm bình thường.
      // 2. Chạy Audit Thăng/Giáng Hạng Tức Thì (Optimistic) cho MỌI user
      await _triggerRankAudit(historicalSessions, latestProfile);
    });
  }

  @override
  Future<void> close() {
    _workoutHistorySubscription?.cancel();
    _profileUpdateSubscription?.cancel();
    return super.close();
  }

  void refreshProfile() {
    emit(state.copyWith(
      userProfile: _authRepo.getProfile(),
      isUserLoggedIn: _authRepo.isUserLoggedIn,
    ));
  }

  Future<void> _triggerRankAudit(List<WorkoutSession> historicalSessions, UserProfile currentProfile) async {
    final validSessions = historicalSessions.where((session) => !session.isDeleted).toList();

    // Xử lý trường hợp xóa sạch không còn buổi tập nào
    if (validSessions.isEmpty) {
      if (currentProfile.activeRankId != 1 || currentProfile.currentRp != 0 || currentProfile.experiencePoints != 0) {
        await _authRepo.saveProfile(currentProfile.copyWith(
          activeRankId: 1, // Đưa về Bronze 1
          currentRp: 0,
          experiencePoints: 0,
          rankAdvancementHistory: [],
        ));
      }
      return;
    }

    await _gamificationRepo.evaluateAndLogRankChange(
      workoutsHistoryList: validSessions,
      userProfileData: currentProfile,
      onRankChangedAction: (fullTimelineItemsList, newlyCalculatedRankId, newlyCalculatedRp) async {
        
        // CHỐNG LOOP: Chỉ lưu xuống AuthRepo nếu thực sự có sự thay đổi RP hoặc Rank
        if (currentProfile.activeRankId != newlyCalculatedRankId || 
            currentProfile.currentRp != newlyCalculatedRp) { 
            
            final updatedProfileData = currentProfile.copyWith(
              activeRankId: newlyCalculatedRankId,
              currentRp: newlyCalculatedRp, 
              // ❌ Bỏ dòng ghi đè XP
              // experiencePoints: recalculatedXp, 
              rankAdvancementHistory: fullTimelineItemsList,
            );

            await _authRepo.saveProfile(updatedProfileData);
            // Không cần emit() thủ công, _profileUpdateSubscription sẽ tự nhận tín hiệu
        }
      },
    );
  }

  Future<void> updateProfile(UserProfile updatedProfileData) async {
    final finalized = _authRepo.recalculatePhysiologicalStats(updatedProfileData);
    await _authRepo.saveProfile(finalized);
    emit(state.copyWith(userProfile: finalized));
  }

  Future<void> updateAvatar(String? base64Image) async {
    final updatedProfile = state.userProfile.copyWith(avatarBase64: base64Image);
    await _authRepo.saveProfile(updatedProfile);
    emit(state.copyWith(userProfile: updatedProfile));
  }

  // ==========================================
  // QUẢN LÝ THỂ CHẤT & MỤC TIÊU
  // ==========================================
  
  Future<void> disableWeeklyWeightReminder() async {
    final updatedProfile = state.userProfile.copyWith(disableWeeklyWeightReminder: true);
    await _authRepo.saveProfile(updatedProfile);
    emit(state.copyWith(userProfile: updatedProfile));
  }
  
  Future<void> updateCurrentWeight(double newWeightInput) async {
    final activeProfile = state.userProfile; 
    
    final profilePendingUpdate = activeProfile.copyWith(weightInKg: newWeightInput);
    
    await _authRepo.recordNewWeightMeasurement(newWeightInput);
    
    final recalculatedProfile = _authRepo.recalculatePhysiologicalStats(profilePendingUpdate);
    
    final finalProfile = recalculatedProfile.copyWith(
      lastWeightUpdateTimestampMillis: DateTime.now().millisecondsSinceEpoch
    );
    
    await _authRepo.saveProfile(finalProfile);
    emit(state.copyWith(userProfile: finalProfile)); 
  }

  Future<void> updateGoalParameters(double newTargetWeight, int newTargetDurationDays) async {
    final activeProfile = state.userProfile;
    final weightDifferenceGap = newTargetWeight - activeProfile.weightInKg;

    NutritionGoal dynamicallyDeterminedGoal = NutritionGoal.MAINTAIN_WEIGHT;
    if (weightDifferenceGap < 0) dynamicallyDeterminedGoal = NutritionGoal.LOSE_WEIGHT;
    if (weightDifferenceGap > 0) dynamicallyDeterminedGoal = NutritionGoal.GAIN_WEIGHT;

    double? calculatedWeeklyRate;
    if (weightDifferenceGap != 0.0 && newTargetDurationDays > 0) {
      calculatedWeeklyRate = (weightDifferenceGap.abs() / newTargetDurationDays) * 7;
    }

    int minDays = NutritionCalculator.calculateMinDays(activeProfile.weightInKg, newTargetWeight);
    int safeDays = newTargetDurationDays < minDays ? minDays : newTargetDurationDays;
    if (safeDays <= 0) safeDays = 1;

    double bmr = NutritionCalculator.calculateBMR(
      activeProfile.weightInKg, activeProfile.heightInCm, activeProfile.userAge, activeProfile.gender, null
    );
    double tdee = NutritionCalculator.calculateTDEE(bmr, activeProfile.activityLevel);

    int targetCals = NutritionCalculator.calculateTargetCalories(
      bmr, tdee, activeProfile.weightInKg, newTargetWeight, safeDays, dynamicallyDeterminedGoal
    );
    
    Macros newTargetMacros = NutritionCalculator.calculateMacros(
      activeProfile.weightInKg, targetCals, dynamicallyDeterminedGoal
    );

    final updatedProfile = activeProfile.copyWith(
      nutritionGoal: dynamicallyDeterminedGoal,
      targetGoalWeightKg: newTargetWeight,
      startingWeightKg: activeProfile.weightInKg, 
      goalStartTimestampMillis: DateTime.now().millisecondsSinceEpoch,
      weeklyGoalRate: calculatedWeeklyRate, 
      targetMacros: newTargetMacros,
      isCustomMacros: false, 
    );
    
    await updateProfile(updatedProfile); 
  }

  Future<void> updateTargetWeightKeepCustomMacros(double newTargetWeight) async {
    final activeProfile = state.userProfile;
    
    double bmr = NutritionCalculator.calculateBMR(
      activeProfile.weightInKg, activeProfile.heightInCm, activeProfile.userAge, activeProfile.gender, null
    );
    double tdee = NutritionCalculator.calculateTDEE(bmr, activeProfile.activityLevel);

    int predictedDays = NutritionCalculator.calculateDaysFromCustomCalories(
      tdee, activeProfile.targetMacros.calories, activeProfile.weightInKg, newTargetWeight
    );

    double? newWeeklyRate;
    if (predictedDays > 0) {
       final gap = (newTargetWeight - activeProfile.weightInKg).abs();
       newWeeklyRate = (gap / predictedDays) * 7;
    } else {
       newWeeklyRate = null; 
    }

    final weightDifferenceGap = newTargetWeight - activeProfile.weightInKg;
    NutritionGoal newGoal = NutritionGoal.MAINTAIN_WEIGHT;
    if (weightDifferenceGap < 0) newGoal = NutritionGoal.LOSE_WEIGHT;
    if (weightDifferenceGap > 0) newGoal = NutritionGoal.GAIN_WEIGHT;

    final updatedProfile = activeProfile.copyWith(
      targetGoalWeightKg: newTargetWeight,
      nutritionGoal: newGoal,
      weeklyGoalRate: newWeeklyRate, 
      goalStartTimestampMillis: DateTime.now().millisecondsSinceEpoch, 
    );

    await updateProfile(updatedProfile);
  }

  Future<void> updateCustomTargetMacros(Macros customMacros) async {
    final activeProfile = state.userProfile;
    double targetWeight = activeProfile.targetGoalWeightKg ?? activeProfile.weightInKg;
    
    double bmr = NutritionCalculator.calculateBMR(
      activeProfile.weightInKg, activeProfile.heightInCm, activeProfile.userAge, activeProfile.gender, null
    );
    double tdee = NutritionCalculator.calculateTDEE(bmr, activeProfile.activityLevel);

    int predictedDays = NutritionCalculator.calculateDaysFromCustomCalories(
      tdee, customMacros.calories, activeProfile.weightInKg, targetWeight
    );

    double? newWeeklyRate;
    if (predictedDays > 0) {
       final gap = (targetWeight - activeProfile.weightInKg).abs();
       newWeeklyRate = (gap / predictedDays) * 7;
    } else {
       newWeeklyRate = null; 
    }

    final updatedProfile = activeProfile.copyWith(
      targetMacros: customMacros,
      isCustomMacros: true, 
      weeklyGoalRate: newWeeklyRate, 
      goalStartTimestampMillis: DateTime.now().millisecondsSinceEpoch, 
    );

    await updateProfile(updatedProfile);
  }

  Future<void> handleGoalReviewAction(String userReviewActionString) async {
    final activeProfile = state.userProfile;
    double newTargetWeight = activeProfile.targetGoalWeightKg ?? activeProfile.weightInKg;
    int daysToTarget = 0;

    if (userReviewActionString == "EXTEND") {
      final diff = (activeProfile.weightInKg - newTargetWeight).abs();
      daysToTarget = (diff / 0.5 * 7).toInt(); 
    } else if (userReviewActionString == "DIET_BREAK") {
      newTargetWeight = activeProfile.weightInKg; 
      daysToTarget = 14; 
    } else if (userReviewActionString == "ACCEPT") {
      newTargetWeight = activeProfile.weightInKg; 
      daysToTarget = 0;
    }

    await updateGoalParameters(newTargetWeight, daysToTarget);
  }
}