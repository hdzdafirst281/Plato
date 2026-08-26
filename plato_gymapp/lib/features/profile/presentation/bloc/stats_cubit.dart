import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../workout/data/repositories/workout_repository.dart';
import '../../../workout/data/models/workout_models.dart';
// Import Domain Logic
import '../../domain/profile_chart_utils.dart';
import '../../../../core/database/enums.dart';

part 'stats_cubit.freezed.dart';

@freezed
class StatsState with _$StatsState {
  const factory StatsState({
    @Default([]) List<WorkoutSession> workouts,
    @Default(0) int weeklyStreak,
    @Default(0) int restDays,
    @Default(true) bool isLoading,
  }) = _StatsState;
}

@injectable
class StatsCubit extends Cubit<StatsState> {
  final WorkoutRepository _workoutRepo;
  StreamSubscription? _workoutSubscription;

  StatsCubit(this._workoutRepo) : super(const StatsState()) {
    _workoutSubscription = _workoutRepo.workoutHistoryStream.listen((workouts) {
      final validWorkouts = workouts.where((w) => !w.isDeleted).toList();
      _calculateAndEmitStreaks(validWorkouts);
    });
  }

  @override
  Future<void> close() {
    _workoutSubscription?.cancel();
    return super.close();
  }

  Future<void> deleteWorkout(String id) async {
    try {
      await _workoutRepo.deleteWorkout(id);
    } catch (e) {
      debugPrint('🚨 Lỗi xóa bài tập từ Stats: $e');
    }
  }

  void clearStats() {
    emit(const StatsState(isLoading: false)); // Reset về state rỗng, thoát trạng thái loading
  }

  // --- CÁC HÀM CUNG CẤP DỮ LIỆU BIỂU ĐỒ TRỰC TIẾP CHO UI ---
  
  Map<MuscleGroup, double> getWeeklyHeatmapCoverage() {
    return ProfileChartUtils.calculateWeeklyCoverage(state.workouts);
  }

  Map<MuscleGroup, double> getDetailedMuscleScores() {
    return ProfileChartUtils.calculateDetailedMuscleScores(state.workouts);
  }

  List<StatPoint> getActivityHistory(ChartTimeRange timeRange, String langCode) {
    // Lọc workout theo timeRange trước khi truyền vào hàm aggregate
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final limitMillis = timeRange == ChartTimeRange.ALL_TIME ? 0 : nowMillis - (timeRange.days * 86400000);
    
    final filteredWorkouts = state.workouts.where((w) => w.startTime >= limitMillis).toList();
    filteredWorkouts.sort((a, b) => a.startTime.compareTo(b.startTime)); // Bắt buộc sort cũ nhất -> mới nhất
    
    return ProfileChartUtils.aggregateStatsByTimeRange(filteredWorkouts, timeRange, langCode);
  }

  // --- LOGIC TÍNH TOÁN STREAKS (CHUỖI TẬP LUYỆN) ---

  void _calculateAndEmitStreaks(List<WorkoutSession> workoutsList) {
    if (workoutsList.isEmpty) {
      emit(state.copyWith(
        workouts: [], 
        weeklyStreak: 0, 
        restDays: 0,
        isLoading: false, // 🚀 Cập nhật isLoading
      ));
      return;
    }

    // 1. Chuyển đổi timestamp thành DateTime (cắt bỏ giờ phút giây để dễ tính toán)
    final dates = workoutsList.map((w) {
      final date = DateTime.fromMillisecondsSinceEpoch(w.startTime);
      return DateTime(date.year, date.month, date.day);
    }).toSet().toList();

    // Sắp xếp giảm dần (mới nhất đứng trước)
    dates.sort((a, b) => b.compareTo(a));

    final current = DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    // 2. Tính số ngày nghỉ (Rest Days)
    final lastWorkoutDate = dates.first;
    // ĐÃ FIX: Trừ 1 để không tính ngày hôm nay là ngày nghỉ cho tới khi qua 00:00 ngày hôm sau
    int restDays = today.difference(lastWorkoutDate).inDays - 1;
    if (restDays < 0) restDays = 0; // Chặn số âm nếu tập hôm nay (diff = 0) hoặc lỗi timezone

    // 3. Tính Chuỗi Tuần (Weekly Streak)
    int weeklyStreak = 0;
    DateTime targetWeekDate = today;

    // Kiểm tra xem tuần này có tập không
    bool hasWorkoutThisWeek = dates.any((date) => _isSameWeek(date, targetWeekDate));
    if (hasWorkoutThisWeek) {
      weeklyStreak++;
    }

    while (true) {
      targetWeekDate = targetWeekDate.subtract(const Duration(days: 7));
      bool hasWorkout = dates.any((date) => _isSameWeek(date, targetWeekDate));

      if (hasWorkout) {
        weeklyStreak++;
      } else {
        break;
      }
    }

    emit(state.copyWith(
      workouts: workoutsList,
      weeklyStreak: weeklyStreak,
      restDays: restDays,
      isLoading: false, // 🚀 Cập nhật isLoading khi tính xong
    ));
  }

  // --- Helper: Kiểm tra 2 ngày có nằm trong cùng 1 tuần (Thứ 2 -> CN) không ---
  bool _isSameWeek(DateTime d1, DateTime d2) {
    // Tìm ngày Thứ 2 của d1
    final monday1 = d1.subtract(Duration(days: d1.weekday - 1));
    // Tìm ngày Thứ 2 của d2
    final monday2 = d2.subtract(Duration(days: d2.weekday - 1));

    return monday1 == monday2;
  }
}