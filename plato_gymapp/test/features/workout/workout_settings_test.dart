import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/features/workout/data/workout_effort_preferences.dart';
import 'package:plato_gymapp/features/workout/data/workout_settings_preferences.dart';
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

  testWidgets('renders and persists workout settings', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(home: WorkoutSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial settings layout');

    // Verify top bar and main switch are displayed
    expect(find.byType(WorkoutSettingsScreen), findsOneWidget);
    expect(find.byIcon(Symbols.speed), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text(t.settings.title_bg_workout), findsNothing);
    expect(find.text(t.settings.title_workout_guide), findsNothing);
    expect(find.text(t.settings.lbl_default_rest_timer), findsOneWidget);
    expect(find.text(t.settings.lbl_keep_screen_awake), findsOneWidget);
    expect(find.text(t.settings.lbl_timer_sound), findsOneWidget);
    expect(find.text(t.settings.lbl_confirm_finish), findsOneWidget);
    expect(find.text(t.settings.desc_effort_tracking), findsOneWidget);
    expect(find.text(t.settings.desc_keep_screen_awake), findsOneWidget);
    expect(find.text(t.settings.desc_timer_sound), findsOneWidget);
    expect(find.byKey(const ValueKey('keep_screen_awake_info')), findsNothing);
    expect(find.byKey(const ValueKey('timer_sound_info')), findsNothing);

    // Verify default values: RPE/RIR off, rest timer 90s, keep screen awake off, timer sound on, confirm finish on
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('effort_toggle'))).value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('keep_screen_awake_toggle')),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('timer_sound_toggle')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('confirm_finish_toggle')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Text>(find.text(t.settings.lbl_effort_tracking))
          .style
          ?.decoration,
      TextDecoration.underline,
    );

    // Tapping an underlined title opens info without sharing the switch target.
    await tester.tap(find.text(t.settings.lbl_effort_tracking));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'effort info dialog');
    expect(find.textContaining(t.settings.title_rpe_info), findsOneWidget);
    expect(find.textContaining(t.settings.title_rir_info), findsOneWidget);
    await tester.tap(find.text(t.common.understood));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.settings.lbl_default_rest_timer));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'rest info dialog');
    expect(find.text(t.settings.info_default_rest_timer), findsOneWidget);
    await tester.tap(find.text(t.common.understood));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('default_rest_control')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'rest time picker');
    expect(find.text(t.workout.title_rest_time), findsOneWidget);
    expect(find.text(t.settings.info_default_rest_timer), findsNothing);
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();

    // Effort tracking is initially disabled, so SegmentedButton shouldn't be visible
    expect(find.byType(SegmentedButton<EffortInputScale>), findsNothing);

    // Enable effort tracking
    await tester.tap(find.byKey(const ValueKey('effort_toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'effort scale control');
    expect(find.byType(Dialog), findsNothing);

    // Only the RPE/RIR control remains; the redundant scale title is gone.
    expect(find.byType(SegmentedButton<EffortInputScale>), findsOneWidget);
    expect(find.text(t.settings.lbl_effort_scale), findsNothing);
    expect(find.text(t.settings.lbl_scale_rpe), findsOneWidget);
    expect(find.text(t.settings.lbl_scale_rir), findsOneWidget);

    // Tap on RIR
    await tester.tap(find.text(t.settings.lbl_scale_rir));
    await tester.pumpAndSettle();

    // Verify persisted scale
    final prefs = GetIt.instance<SharedPreferences>();
    expect(WorkoutEffortPreferences.advancedEnabled(prefs), isTrue);
    expect(WorkoutEffortPreferences.inputScale(prefs), EffortInputScale.rir);

    await tester.tap(find.byKey(const ValueKey('keep_screen_awake_toggle')));
    await tester.tap(find.byKey(const ValueKey('timer_sound_toggle')));
    await tester.tap(find.byKey(const ValueKey('confirm_finish_toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    expect(WorkoutSettingsPreferences.keepScreenAwake(prefs), isTrue);
    expect(WorkoutSettingsPreferences.timerSoundEnabled(prefs), isFalse);
    expect(WorkoutSettingsPreferences.confirmFinishEnabled(prefs), isFalse);
  });
}
