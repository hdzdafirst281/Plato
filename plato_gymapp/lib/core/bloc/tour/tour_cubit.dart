import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/features/auth/domain/repositories/auth_repository.dart';
import 'tour_state.dart';

class TourCubit extends Cubit<TourState> {
  final SharedPreferences _prefs;
  final AuthRepository? _authRepo;

  static const String _keyLogWorkout = 'tour_log_workout';
  static const String _keyNutrition = 'tour_nutrition';
  static const String _keyWorkout = 'tour_workout';
  static const String _keyCalendar = 'tour_calendar';
  static const String _keyTimerPlayBtn = 'tour_timer_play_btn';
  static const String _keyExerciseLibrary = 'tour_exercise_library';

  TourCubit(this._prefs, [this._authRepo]) : super(const TourState()) {
    _loadTourStatus();
  }

  void _loadTourStatus() {
    final isLoggedIn = _authRepo?.currentUserId != null;
    emit(state.copyWith(
      hasSeenLogWorkout: isLoggedIn || (_prefs.getBool(_keyLogWorkout) ?? false),
      hasSeenNutrition: isLoggedIn || (_prefs.getBool(_keyNutrition) ?? false),
      hasSeenWorkout: isLoggedIn || (_prefs.getBool(_keyWorkout) ?? false),
      hasSeenCalendar: isLoggedIn || (_prefs.getBool(_keyCalendar) ?? false),
      hasSeenTimerPlayBtn: isLoggedIn || (_prefs.getBool(_keyTimerPlayBtn) ?? false),
      hasSeenExerciseLibrary: isLoggedIn || (_prefs.getBool(_keyExerciseLibrary) ?? false),
    ));
    if (isLoggedIn) {
      completeAllTours();
    }
  }

  Future<void> completeLogWorkoutTour() async {
    emit(state.copyWith(hasSeenLogWorkout: true));
    await _prefs.setBool(_keyLogWorkout, true);
  }

  Future<void> completeNutritionTour() async {
    emit(state.copyWith(hasSeenNutrition: true));
    await _prefs.setBool(_keyNutrition, true);
  }

  Future<void> completeWorkoutTour() async {
    emit(state.copyWith(hasSeenWorkout: true));
    await _prefs.setBool(_keyWorkout, true);
  }

  Future<void> completeCalendarTour() async {
    emit(state.copyWith(hasSeenCalendar: true));
    await _prefs.setBool(_keyCalendar, true);
  }
  
  Future<void> completeTimerPlayBtnTour() async {
    emit(state.copyWith(hasSeenTimerPlayBtn: true));
    await _prefs.setBool(_keyTimerPlayBtn, true);
  }

  Future<void> completeExerciseLibraryTour() async {
    emit(state.copyWith(hasSeenExerciseLibrary: true));
    await _prefs.setBool(_keyExerciseLibrary, true);
  }

  Future<void> resetAllTours() async {
    emit(const TourState());
    await Future.wait([
      _prefs.remove(_keyLogWorkout),
      _prefs.remove(_keyNutrition),
      _prefs.remove(_keyWorkout),
      _prefs.remove(_keyCalendar),
      _prefs.remove(_keyTimerPlayBtn),
      _prefs.remove(_keyExerciseLibrary),
    ]);
  }

  Future<void> completeAllTours() async {
    emit(state.copyWith(
      hasSeenLogWorkout: true,
      hasSeenNutrition: true,
      hasSeenWorkout: true,
      hasSeenCalendar: true,
      hasSeenTimerPlayBtn: true,
      hasSeenExerciseLibrary: true,
    ));

    await Future.wait([
      _prefs.setBool(_keyLogWorkout, true),
      _prefs.setBool(_keyNutrition, true),
      _prefs.setBool(_keyWorkout, true),
      _prefs.setBool(_keyCalendar, true),
      _prefs.setBool(_keyTimerPlayBtn, true),
      _prefs.setBool(_keyExerciseLibrary, true),
    ]);
  }
}
