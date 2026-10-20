import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/features/workout/data/workout_effort_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('advanced effort is opt-in and persists its input scale', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(WorkoutEffortPreferences.advancedEnabled(prefs), isFalse);
    expect(WorkoutEffortPreferences.inputScale(prefs), EffortInputScale.rpe);

    await WorkoutEffortPreferences.setAdvancedEnabled(prefs, true);
    await WorkoutEffortPreferences.setInputScale(prefs, EffortInputScale.rir);

    expect(WorkoutEffortPreferences.advancedEnabled(prefs), isTrue);
    expect(WorkoutEffortPreferences.inputScale(prefs), EffortInputScale.rir);
  });
}
