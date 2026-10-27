import 'package:shared_preferences/shared_preferences.dart';

class WorkoutEffortPreferences {
  static const advancedEffortKey = 'workout_advanced_effort_enabled';

  static bool advancedEnabled(SharedPreferences prefs) =>
      prefs.getBool(advancedEffortKey) ?? false;

  static Future<void> setAdvancedEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) async {
    await prefs.setBool(advancedEffortKey, enabled);
  }
}
