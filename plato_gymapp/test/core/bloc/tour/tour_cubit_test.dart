import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/features/auth/domain/repositories/auth_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  final String? _userId;
  _FakeAuthRepository([this._userId]);

  @override
  String? get currentUserId => _userId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TourCubit', () {
    test('initial state for guest user with no saved tours is all false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = TourCubit(prefs, _FakeAuthRepository(null));

      expect(cubit.state.hasSeenWorkout, isFalse);
      expect(cubit.state.hasSeenNutrition, isFalse);
      expect(cubit.state.hasSeenCalendar, isFalse);
      expect(cubit.state.hasSeenLogWorkout, isFalse);
      expect(cubit.state.hasSeenTimerPlayBtn, isFalse);
      expect(cubit.state.hasSeenExerciseLibrary, isFalse);
    });

    test(
      'guest user has seen tour if flag is set in SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'tour_workout': true});
        final prefs = await SharedPreferences.getInstance();
        final authRepo = _FakeAuthRepository(null);

        final cubit = TourCubit(prefs, authRepo);

        expect(cubit.state.hasSeenWorkout, isTrue);
        expect(cubit.state.hasSeenNutrition, isFalse);
        expect(cubit.state.hasSeenCalendar, isFalse);
      },
    );

    test(
      'logged-in user has all tours marked as seen immediately upon initialization',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final authRepo = _FakeAuthRepository('user-123');

        final cubit = TourCubit(prefs, authRepo);

        expect(cubit.state.hasSeenWorkout, isTrue);
        expect(cubit.state.hasSeenNutrition, isTrue);
        expect(cubit.state.hasSeenCalendar, isTrue);
        expect(cubit.state.hasSeenLogWorkout, isTrue);
        expect(cubit.state.hasSeenTimerPlayBtn, isTrue);
        expect(cubit.state.hasSeenExerciseLibrary, isTrue);

        // Verify SharedPreferences also gets updated
        await Future.delayed(const Duration(milliseconds: 50));
        expect(prefs.getBool('tour_workout'), isTrue);
        expect(prefs.getBool('tour_nutrition'), isTrue);
        expect(prefs.getBool('tour_calendar'), isTrue);
      },
    );

    test(
      'completeAllTours emits synchronously and persists to SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final cubit = TourCubit(prefs, _FakeAuthRepository(null));

        expect(cubit.state.hasSeenWorkout, isFalse);

        final future = cubit.completeAllTours();

        // Synchronous emission check (before future completes)
        expect(cubit.state.hasSeenWorkout, isTrue);
        expect(cubit.state.hasSeenNutrition, isTrue);
        expect(cubit.state.hasSeenCalendar, isTrue);
        expect(cubit.state.hasSeenLogWorkout, isTrue);
        expect(cubit.state.hasSeenTimerPlayBtn, isTrue);
        expect(cubit.state.hasSeenExerciseLibrary, isTrue);

        await future;

        expect(prefs.getBool('tour_workout'), isTrue);
        expect(prefs.getBool('tour_nutrition'), isTrue);
        expect(prefs.getBool('tour_calendar'), isTrue);
        expect(prefs.getBool('tour_log_workout'), isTrue);
        expect(prefs.getBool('tour_timer_play_btn'), isTrue);
        expect(prefs.getBool('tour_exercise_library'), isTrue);
      },
    );

    test(
      'resetAllTours clears all flags in state and SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'tour_workout': true,
          'tour_nutrition': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final cubit = TourCubit(prefs, _FakeAuthRepository(null));

        expect(cubit.state.hasSeenWorkout, isTrue);

        final future = cubit.resetAllTours();

        // Synchronously reset
        expect(cubit.state.hasSeenWorkout, isFalse);
        expect(cubit.state.hasSeenNutrition, isFalse);

        await future;

        expect(prefs.getBool('tour_workout'), isNull);
        expect(prefs.getBool('tour_nutrition'), isNull);
      },
    );

    test('complete individual tours updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = TourCubit(prefs, _FakeAuthRepository(null));

      await cubit.completeWorkoutTour();
      expect(cubit.state.hasSeenWorkout, isTrue);
      expect(prefs.getBool('tour_workout'), isTrue);

      await cubit.completeNutritionTour();
      expect(cubit.state.hasSeenNutrition, isTrue);
      expect(prefs.getBool('tour_nutrition'), isTrue);

      await cubit.completeCalendarTour();
      expect(cubit.state.hasSeenCalendar, isTrue);
      expect(prefs.getBool('tour_calendar'), isTrue);

      await cubit.completeLogWorkoutTour();
      expect(cubit.state.hasSeenLogWorkout, isTrue);
      expect(prefs.getBool('tour_log_workout'), isTrue);

      await cubit.completeTimerPlayBtnTour();
      expect(cubit.state.hasSeenTimerPlayBtn, isTrue);
      expect(prefs.getBool('tour_timer_play_btn'), isTrue);

      await cubit.completeExerciseLibraryTour();
      expect(cubit.state.hasSeenExerciseLibrary, isTrue);
      expect(prefs.getBool('tour_exercise_library'), isTrue);
    });
  });
}
