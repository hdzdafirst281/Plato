import 'package:shared_preferences/shared_preferences.dart';

class WorkoutSettingsPreferences {
  static const defaultRestSecondsKey = 'workout_default_rest_seconds';
  static const keepScreenAwakeKey = 'workout_keep_screen_awake';
  static const timerSoundEnabledKey = 'workout_timer_sound_enabled';
  static const confirmFinishEnabledKey = 'workout_confirm_finish_enabled';

  static int defaultRestSeconds(SharedPreferences prefs) =>
      prefs.getInt(defaultRestSecondsKey) ?? 90;

  static bool keepScreenAwake(SharedPreferences prefs) =>
      prefs.getBool(keepScreenAwakeKey) ?? false;

  static bool timerSoundEnabled(SharedPreferences prefs) =>
      prefs.getBool(timerSoundEnabledKey) ?? true;

  static bool confirmFinishEnabled(SharedPreferences prefs) =>
      prefs.getBool(confirmFinishEnabledKey) ?? true;

  static Future<bool> setDefaultRestSeconds(
    SharedPreferences prefs,
    int seconds,
  ) => prefs.setInt(defaultRestSecondsKey, seconds);

  static Future<bool> setKeepScreenAwake(
    SharedPreferences prefs,
    bool enabled,
  ) => prefs.setBool(keepScreenAwakeKey, enabled);

  static Future<bool> setTimerSoundEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) => prefs.setBool(timerSoundEnabledKey, enabled);

  static Future<bool> setConfirmFinishEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) => prefs.setBool(confirmFinishEnabledKey, enabled);
}
