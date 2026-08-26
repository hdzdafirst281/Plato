class AppRoutes {
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const splash = '/splash';
  
  // Các Tab chính ở BottomBar
  static const workout = '/workout';
  static const nutrition = '/nutrition';
  static const social = '/social';
  static const profile = '/profile';

  // ==========================================
  // MÀN HÌNH PHỤ TỪ TAB WORKOUT
  // ==========================================
  static const logWorkout = '/log_workout';
  static const sessionSummary = '/session_summary';
  
  static const createRoutine = 'create_routine';
  static const workoutDetail = 'workout_detail/:workoutId';
  static const explorePrograms = 'explore_programs';
  
  static const exerciseLibrary = 'exercise_library';
  static const exerciseDetail = 'exercise_details';

  // ==========================================
  // MÀN HÌNH PHỤ TỪ TAB NUTRITION
  // ==========================================
  static const foodEncyclopedia = 'food_encyclopedia/:mealType';

  // ==========================================
  // MÀN HÌNH PHỤ TỪ TAB SOCIAL
  // ==========================================
  static const rank = 'rank_screen';

  // ==========================================
  // MÀN HÌNH PHỤ TỪ TAB PROFILE
  // ==========================================
  static const profileSettings = 'profile_settings';
  static const stats = 'stats';
  static const tutorial = 'tutorial';
  static const settings = 'settings';
  static const calendar = 'calendar';
}