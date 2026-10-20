import 'package:shared_preferences/shared_preferences.dart';

enum EffortInputScale { rpe, rir }

class WorkoutEffortPreferences {
  static const advancedEffortKey = 'workout_advanced_effort_enabled';
  static const effortScaleKey = 'workout_effort_input_scale';

  static bool advancedEnabled(SharedPreferences prefs) =>
      prefs.getBool(advancedEffortKey) ?? false;

  static EffortInputScale inputScale(SharedPreferences prefs) {
    final stored = prefs.getString(effortScaleKey);
    return EffortInputScale.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => EffortInputScale.rpe,
    );
  }

  static Future<void> setAdvancedEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) async {
    await prefs.setBool(advancedEffortKey, enabled);
  }

  static Future<void> setInputScale(
    SharedPreferences prefs,
    EffortInputScale scale,
  ) async {
    await prefs.setString(effortScaleKey, scale.name);
  }
}
