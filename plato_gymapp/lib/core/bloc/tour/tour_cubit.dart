import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tour_state.dart';

class TourCubit extends Cubit<TourState> {
  final SharedPreferences _prefs;

  static const String _keyLogWorkout = 'tour_log_workout';
  static const String _keyNutrition = 'tour_nutrition';
  static const String _keyWorkout = 'tour_workout';
  static const String _keyCalendar = 'tour_calendar';
  static const String _keyTimerPlayBtn = 'tour_timer_play_btn';
  static const String _keyExerciseLibrary = 'tour_exercise_library';

  TourCubit(this._prefs) : super(const TourState()) {
    _loadTourStatus();
  }

  void _loadTourStatus() {
    emit(state.copyWith(
      hasSeenLogWorkout: _prefs.getBool(_keyLogWorkout) ?? false,
      hasSeenNutrition: _prefs.getBool(_keyNutrition) ?? false,
      hasSeenWorkout: _prefs.getBool(_keyWorkout) ?? false,
      hasSeenCalendar: _prefs.getBool(_keyCalendar) ?? false,
      hasSeenTimerPlayBtn: _prefs.getBool(_keyTimerPlayBtn) ?? false,
      hasSeenExerciseLibrary: _prefs.getBool(_keyExerciseLibrary) ?? false,
    ));
  }

  Future<void> completeLogWorkoutTour() async {
    await _prefs.setBool(_keyLogWorkout, true);
    emit(state.copyWith(hasSeenLogWorkout: true));
  }

  Future<void> completeNutritionTour() async {
    await _prefs.setBool(_keyNutrition, true);
    emit(state.copyWith(hasSeenNutrition: true));
  }

  Future<void> completeWorkoutTour() async {
    await _prefs.setBool(_keyWorkout, true);
    emit(state.copyWith(hasSeenWorkout: true));
  }

  Future<void> completeCalendarTour() async {
    await _prefs.setBool(_keyCalendar, true);
    emit(state.copyWith(hasSeenCalendar: true));
  }
  
  Future<void> completeTimerPlayBtnTour() async {
    await _prefs.setBool(_keyTimerPlayBtn, true);
    emit(state.copyWith(hasSeenTimerPlayBtn: true));
  }

  Future<void> completeExerciseLibraryTour() async {
    await _prefs.setBool(_keyExerciseLibrary, true);
    emit(state.copyWith(hasSeenExerciseLibrary: true));
  }

  Future<void> resetAllTours() async {
    await _prefs.remove(_keyLogWorkout);
    await _prefs.remove(_keyNutrition);
    await _prefs.remove(_keyWorkout);
    await _prefs.remove(_keyCalendar);
    await _prefs.remove(_keyTimerPlayBtn);
    await _prefs.remove(_keyExerciseLibrary);
    emit(const TourState());
  }

  Future<void> completeAllTours() async {
    await _prefs.setBool(_keyLogWorkout, true);
    await _prefs.setBool(_keyNutrition, true);
    await _prefs.setBool(_keyWorkout, true);
    await _prefs.setBool(_keyCalendar, true);
    await _prefs.setBool(_keyTimerPlayBtn, true);
    await _prefs.setBool(_keyExerciseLibrary, true);
    
    emit(state.copyWith(
      hasSeenLogWorkout: true,
      hasSeenNutrition: true,
      hasSeenWorkout: true,
      hasSeenCalendar: true,
      hasSeenTimerPlayBtn: true,
      hasSeenExerciseLibrary: true,
    ));
  }
}