import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/features/workout/data/workout_effort_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RPE per set is opt-in', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(WorkoutEffortPreferences.advancedEnabled(prefs), isFalse);

    await WorkoutEffortPreferences.setAdvancedEnabled(prefs, true);

    expect(WorkoutEffortPreferences.advancedEnabled(prefs), isTrue);
  });
}
