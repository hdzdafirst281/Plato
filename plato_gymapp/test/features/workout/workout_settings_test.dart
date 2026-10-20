import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/features/workout/data/workout_effort_preferences.dart';
import 'package:plato_gymapp/features/workout/presentation/screens/workout_settings_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SharedPreferences>()) {
      await getIt.unregister<SharedPreferences>();
    }
    getIt.registerSingleton<SharedPreferences>(prefs);
  });

  tearDown(() async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SharedPreferences>()) {
      await getIt.unregister<SharedPreferences>();
    }
  });

  testWidgets('WorkoutSettingsScreen renders and allows toggling effort scale',
      (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: WorkoutSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify top bar and main switch are displayed
    expect(find.byType(WorkoutSettingsScreen), findsOneWidget);
    expect(find.byIcon(Symbols.speed), findsOneWidget);

    // Effort tracking is initially disabled, so SegmentedButton shouldn't be visible
    expect(find.byType(SegmentedButton<EffortInputScale>), findsNothing);

    // Enable effort tracking
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsWidgets);
    await tester.tap(switchFinder.first);
    await tester.pumpAndSettle();

    // SegmentedButton should now appear with RPE and RIR options
    expect(find.byType(SegmentedButton<EffortInputScale>), findsOneWidget);
    expect(find.text(t.settings.lbl_scale_rpe), findsOneWidget);
    expect(find.text(t.settings.lbl_scale_rir), findsOneWidget);

    // Tap on RIR
    await tester.tap(find.text(t.settings.lbl_scale_rir));
    await tester.pumpAndSettle();

    // Verify persisted scale
    final prefs = GetIt.instance<SharedPreferences>();
    expect(WorkoutEffortPreferences.advancedEnabled(prefs), isTrue);
    expect(WorkoutEffortPreferences.inputScale(prefs), EffortInputScale.rir);
  });
}
