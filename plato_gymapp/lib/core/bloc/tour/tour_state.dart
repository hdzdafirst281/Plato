class TourState {
  final bool hasSeenLogWorkout;
  final bool hasSeenNutrition;
  final bool hasSeenWorkout;
  final bool hasSeenCalendar;
  final bool hasSeenTimerPlayBtn;
  // [NEW]: Trạng thái cho Exercise Library Screen
  final bool hasSeenExerciseLibrary;

  const TourState({
    this.hasSeenLogWorkout = false,
    this.hasSeenNutrition = false,
    this.hasSeenWorkout = false,
    this.hasSeenCalendar = false,
    this.hasSeenTimerPlayBtn = false,
    this.hasSeenExerciseLibrary = false,
  });

  TourState copyWith({
    bool? hasSeenLogWorkout,
    bool? hasSeenNutrition,
    bool? hasSeenWorkout,
    bool? hasSeenCalendar,
    bool? hasSeenTimerPlayBtn,
    bool? hasSeenExerciseLibrary,
  }) {
    return TourState(
      hasSeenLogWorkout: hasSeenLogWorkout ?? this.hasSeenLogWorkout,
      hasSeenNutrition: hasSeenNutrition ?? this.hasSeenNutrition,
      hasSeenWorkout: hasSeenWorkout ?? this.hasSeenWorkout,
      hasSeenCalendar: hasSeenCalendar ?? this.hasSeenCalendar,
      hasSeenTimerPlayBtn: hasSeenTimerPlayBtn ?? this.hasSeenTimerPlayBtn,
      hasSeenExerciseLibrary: hasSeenExerciseLibrary ?? this.hasSeenExerciseLibrary,
    );
  }
}