import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';
import '../models/user_models.dart';
import '../../../../core/database/enums.dart';
import '../../../nutrition/data/models/nutrition_models.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  static const String _profileKey = 'USER_PROFILE';
  static const String _otpTimestampKey = 'otp_last_sent_timestamp';
  static const String _measurementsKey = 'BODY_MEASUREMENTS';

  final _profileUpdateController = StreamController<UserProfile>.broadcast();
  @override
  Stream<UserProfile> get profileUpdateStream => _profileUpdateController.stream;

  AuthRepositoryImpl(this._supabase, this._prefs);

  @override
  int? get otpCooldownTimestamp => _prefs.getInt(_otpTimestampKey);

  @override
  Future<void> saveOtpCooldownTimestamp(int timestamp) async {
    await _prefs.setInt(_otpTimestampKey, timestamp);
  }

  @override
  UserProfile getProfile() {
    final jsonString = _prefs.getString(_profileKey);
    if (jsonString != null) {
      try {
        return UserProfile.fromJson(jsonDecode(jsonString));
      } catch (e) {
        debugPrint('🚨 Lỗi parse Profile: $e');
      }
    }
    return const UserProfile(
      targetMacros: Macros(),
      detailedBodyMetrics: BodyMetrics(), 
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    _profileUpdateController.add(profile);
  }

  @override
  void dispose() {
    _profileUpdateController.close();
  }

  @override
  List<BodyMeasurement> getBodyMeasurements() {
    final jsonString = _prefs.getString(_measurementsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => BodyMeasurement.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> recordNewWeightMeasurement(double newWeightKgInput) async {
    final newRecord = BodyMeasurement(
      recordTimestampMillis: DateTime.now().millisecondsSinceEpoch,
      recordedWeightKg: newWeightKgInput,
    );
    
    final currentHistory = getBodyMeasurements();
    currentHistory.add(newRecord);
    await _prefs.setString(_measurementsKey, jsonEncode(currentHistory.map((e) => e.toJson()).toList()));

    final activeProfile = getProfile().copyWith(weightInKg: newWeightKgInput);
    final recalculatedProfile = recalculatePhysiologicalStats(activeProfile, keepExistingMacros: true);
    await saveProfile(recalculatedProfile);
  }

  @override
  bool get isUserLoggedIn => _supabase.auth.currentSession != null;
  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==========================================
  // --- AUTH FLOWS (ĐÃ REFACTOR) ---
  // ==========================================

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase.rpc('check_email_exists', params: {'user_email': email});
      return response as bool;
    } catch (e) {
      debugPrint("🚨 Lỗi check_email_exists: $e");
      return false; // Mặc định false nếu rớt mạng/lỗi để block luồng an toàn
    }
  }

  @override
  Future<bool> requestLoginOtp(String email) async {
    try {
      if (email.trim().toLowerCase() == 'testing_app@plato.com') {
        return true; 
      }
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
      return true;
    } on AuthException catch (e) {
      debugPrint("🚨 Auth Error (Login): ${e.message}");
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestLinkOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: true);
      return true;
    } on AuthException catch (e) {
      debugPrint("🚨 Auth Error (Link): ${e.message}");
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateUserEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
      return true;
    } catch (e) {
      debugPrint("🚨 Error (Update Email): $e");
      return false;
    }
  }

  @override
  Future<String?> verifyOtpAndRetrieveUserId(String userEmailInputString, String verificationOtpTokenString) async {
    try {
      if (userEmailInputString.trim().toLowerCase() == 'testing_app@plato.com' && 
          verificationOtpTokenString == '123456') {
         final response = await _supabase.auth.signInWithPassword(
           email: userEmailInputString.trim(), 
           password: verificationOtpTokenString,
         );
         return response.user?.id;
      }

      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email, email: userEmailInputString, token: verificationOtpTokenString,
      );
      return response.user?.id;
    } on AuthException catch (e) {
      debugPrint("🚨 Supabase Auth Error (Verify): ${e.message}");
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Bắt lỗi an toàn. Khi user đã bị xóa trên cloud, signOut sẽ quăng lỗi.
      // Chúng ta chỉ cần ignore nó để app tiếp tục dọn dẹp Local.
      debugPrint("🚨 Bỏ qua lỗi Supabase SignOut: $e");
    }
  }

  @override
  Future<bool> deleteUserAccountOnCloud() async {
    try {
      if (!isUserLoggedIn) {
        return true; // Guest account: only local data needs to be deleted
      }
      await _supabase.rpc('delete_user_account');
      return true;
    } catch (e) {
      debugPrint("🚨 Lỗi deleteUserAccountOnCloud: $e");
      return false;
    }
  }

  // ==========================================
  // --- PROFILE SYNC & CALCULATION ---
  // ==========================================

  @override
  Future<void> fetchAndSyncProfileIfLocalIsCorrupted() async {
    final userId = currentUserId;
    if (userId != null) {
      await forceSyncProfileFromCloud(userId);
    }
  }

  @override
  Future<bool> forceSyncProfileFromCloud(String targetUserId) async {
    try {
      final response = await _supabase.from('users').select().eq('id', targetUserId).maybeSingle();

      if (response != null) {
        final prefs = response['workout_preferences'] ?? {};
        final health = response['health_profile'] ?? {};
        final targets = response['current_targets'] ?? {};

        final historyResponse = await _supabase.from('user_rank_history')
            .select('new_rank_id, event_type, created_at')
            .eq('user_id', targetUserId)
            .order('created_at', ascending: false);

        List<RankTimelineItem> parsedHistory = [];
        for (var row in historyResponse as List) {
          String mappedReason = 'REASON_MAINTAINED';
          if (row['event_type'] == 'PROMOTION') mappedReason = 'REASON_PROMOTED';
          if (row['event_type'] == 'DEMOTION') mappedReason = 'REASON_DEMOTED';

          parsedHistory.add(RankTimelineItem(
            rankId: row['new_rank_id'] as int,
            achievedAtMillis: DateTime.parse(row['created_at']).millisecondsSinceEpoch,
            unlockReasonDescription: mappedReason,
          ));
        }

        final fetchedProfile = UserProfile(
          id: response['id'],
          displayName: response['name'] ?? 'Gym Warrior',
          gender: Gender.values.firstWhere((e) => e.name == response['gender'], orElse: () => Gender.MALE),
          userAge: response['age'] ?? 25,
          heightInCm: (response['height_cm'] ?? 175).toDouble(),
          weightInKg: (response['weight_kg'] ?? 75).toDouble(),
          bodyFatPercentage: response['body_fat'] != null ? (response['body_fat'] as num).toDouble() : null,
          
          experiencePoints: response['xp'] ?? 0,
          currentRp: response['current_rp'] ?? 0, 
          lastRpSeasonId: response['last_rp_season_id'] ?? 1, 
          activeRankId: response['current_rank_id'] ?? 1,
          rankAdvancementHistory: parsedHistory, 
          
          workoutGoal: WorkoutGoal.values.firstWhere((e) => e.name == prefs['workout_goal'], orElse: () => WorkoutGoal.STRENGTH),
          nutritionGoal: NutritionGoal.values.firstWhere((e) => e.name == targets['nutrition_goal'], orElse: () => NutritionGoal.MAINTAIN_WEIGHT),
          experienceLevel: prefs['experience_level'],
          activityLevel: ActivityLevel.values.firstWhere((e) => e.name == prefs['activity_level'], orElse: () => ActivityLevel.MODERATE),
          trainingDaysPerWeek: prefs['days_available'] ?? '3-5',
          environment: WorkoutEnvironment.values.firstWhere((e) => e.name == prefs['environment'], orElse: () => WorkoutEnvironment.GYM),

          reportedInjuries: List<String>.from(health['injuries'] ?? []),
          dietaryRestrictions: List<String>.from(health['dietary_restrictions'] ?? []),

          targetGoalWeightKg: (targets['target_weight_kg'])?.toDouble(),
          dietPlan: targets['diet_plan'],
          calculatedTdee: targets['tdee'] ?? 2000,
          targetMacros: Macros.fromJson(targets['target_macros'] ?? const {'c': 0, 'f': 0, 'p': 0, 'cal': 0}),
          isCustomMacros: targets['is_custom_macros'] ?? false,
          weeklyGoalRate: (targets['weekly_goal_rate'])?.toDouble(),
          
          detailedBodyMetrics: const BodyMetrics(),
        );

        await saveProfile(fetchedProfile);
        debugPrint("✅ Tải Profile & Rank History từ Cloud về Local thành công!");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("🚨 Lỗi kéo Profile từ mạng: $e");
      return false;
    }
  }

  @override
  UserProfile recalculatePhysiologicalStats(UserProfile baseProfile, {bool keepExistingMacros = false}) {
    double bmr = (10 * baseProfile.weightInKg) + (6.25 * baseProfile.heightInCm) - (5 * baseProfile.userAge);
    bmr += (baseProfile.gender == Gender.MALE) ? 5 : -161;

    double multiplier = 1.2;
    switch (baseProfile.activityLevel) {
      case ActivityLevel.SEDENTARY: multiplier = 1.2; break;
      case ActivityLevel.LIGHT: multiplier = 1.375; break;
      case ActivityLevel.MODERATE: multiplier = 1.55; break;
      case ActivityLevel.ACTIVE: multiplier = 1.725; break;
    }
    final tdee = (bmr * multiplier).toInt();

    if (baseProfile.isCustomMacros || (keepExistingMacros && baseProfile.targetMacros.calories > 0)) {
      return baseProfile.copyWith(calculatedTdee: tdee);
    }

    int targetCalories = tdee;
    if (baseProfile.weeklyGoalRate != null) {
      targetCalories += (baseProfile.weeklyGoalRate! * 7700 / 7).round();
    } else {
      if (baseProfile.nutritionGoal == NutritionGoal.LOSE_WEIGHT) targetCalories -= 500; 
      if (baseProfile.nutritionGoal == NutritionGoal.GAIN_WEIGHT) targetCalories += 300;
    }

    int protein = (baseProfile.weightInKg * 2.2).toInt(); 
    int fat = (baseProfile.weightInKg * 1.0).toInt();     
    int carbs = ((targetCalories - (protein * 4) - (fat * 9)) / 4).toInt();

    return baseProfile.copyWith(
      calculatedTdee: tdee,
      targetMacros: Macros(calories: targetCalories, protein: protein, fat: fat, carbs: carbs > 0 ? carbs : 0),
    );
  }
}