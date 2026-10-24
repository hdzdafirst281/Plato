import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/features/workout/data/workout_settings_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('workout settings use safe defaults and persist changes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(WorkoutSettingsPreferences.defaultRestSeconds(prefs), 90);
    expect(WorkoutSettingsPreferences.keepScreenAwake(prefs), isFalse);
    expect(WorkoutSettingsPreferences.timerSoundEnabled(prefs), isTrue);
    expect(WorkoutSettingsPreferences.confirmFinishEnabled(prefs), isTrue);

    await WorkoutSettingsPreferences.setDefaultRestSeconds(prefs, 120);
    await WorkoutSettingsPreferences.setKeepScreenAwake(prefs, true);
    await WorkoutSettingsPreferences.setTimerSoundEnabled(prefs, false);
    await WorkoutSettingsPreferences.setConfirmFinishEnabled(prefs, false);

    expect(WorkoutSettingsPreferences.defaultRestSeconds(prefs), 120);
    expect(WorkoutSettingsPreferences.keepScreenAwake(prefs), isTrue);
    expect(WorkoutSettingsPreferences.timerSoundEnabled(prefs), isFalse);
    expect(WorkoutSettingsPreferences.confirmFinishEnabled(prefs), isFalse);
  });
}
