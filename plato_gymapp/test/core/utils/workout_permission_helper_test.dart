import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/utils/workout_permission_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('an explicit decision suppresses the first-workout prompt', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(WorkoutPermissionHelper.shouldAskPrePermission(prefs), isTrue);

    await WorkoutPermissionHelper.markPrePermissionHandled(prefs);

    expect(WorkoutPermissionHelper.shouldAskPrePermission(prefs), isFalse);
  });
}
