import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/theme/theme_cubit.dart';
import 'package:plato_gymapp/core/utils/measurement_units.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/nutrition/presentation/components/nutrition_components.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/settings_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  MeasurementPreferences? savedPrefs;

  _FakeProfileCubit()
      : super(const ProfileState(
          userProfile: UserProfile(
            targetMacros: Macros(
              calories: 2000,
              protein: 150,
              carbs: 200,
              fat: 60,
            ),
            detailedBodyMetrics: BodyMetrics(),
          ),
        ));

  @override
  Future<void> updateMeasurementPreferences(
      MeasurementPreferences preferences) async {
    savedPrefs = preferences;
    emit(state.copyWith(
      userProfile: state.userProfile.copyWith(
        measurementPreferences: preferences,
      ),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeProfileCubit fakeProfileCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SharedPreferences>()) {
      await getIt.unregister<SharedPreferences>();
    }
    getIt.registerSingleton<SharedPreferences>(prefs);

    fakeProfileCubit = _FakeProfileCubit();
  });

  tearDown(() async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SharedPreferences>()) {
      await getIt.unregister<SharedPreferences>();
    }
  });

  testWidgets(
      'Measurement dialog renders with primary SegmentedButton and synced button layout',
      (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ProfileCubit>.value(value: fakeProfileCubit),
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
              ],
              child: child!,
            ),
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider<ProfileCubit>.value(
                                  value: fakeProfileCubit,
                                ),
                                BlocProvider<ThemeCubit>(
                                  create: (_) => ThemeCubit(),
                                ),
                              ],
                              child: const SettingsScreen(),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Settings'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open SettingsScreen
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    // Scroll until Measurement Units tile is visible
    final measurementTile = find.text(t.settings.title_measurement_units);
    await tester.scrollUntilVisible(
      measurementTile,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(measurementTile, findsOneWidget);
    await tester.tap(measurementTile);
    await tester.pumpAndSettle();

    // Verify dialog title has font size 20 and bold
    final titleFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.text(t.settings.title_measurement_units),
    );
    expect(titleFinder, findsOneWidget);
    final titleText = tester.widget<Text>(titleFinder);
    expect(titleText.style?.fontSize, 20);
    expect(titleText.style?.fontWeight, FontWeight.bold);

    // Verify SegmentedButtons use primary color in style
    final segmentedButtons = tester.widgetList<SegmentedButton>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byWidgetPredicate(
          (widget) => widget is SegmentedButton,
        ),
      ),
    );
    expect(segmentedButtons.length, 5);
    expect(segmentedButtons.any((button) => button.segments.length == 3), isTrue);
    expect(find.text(t.common.unit_ml), findsOneWidget);
    for (final sb in segmentedButtons) {
      final style = sb.style;
      expect(style, isNotNull);
      final primaryColor = AppTheme.darkTheme.colorScheme.primary;
      expect(
        style?.backgroundColor?.resolve({WidgetState.selected}),
        primaryColor,
      );
    }

    // Verify Cancel button layout and style (TextButton, fontSize 15, bold)
    final cancelBtnFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(TextButton, t.common.cancel),
    );
    expect(cancelBtnFinder, findsOneWidget);
    final cancelText = tester.widget<Text>(find.descendant(
      of: cancelBtnFinder,
      matching: find.text(t.common.cancel),
    ));
    expect(cancelText.style?.fontSize, 15);
    expect(cancelText.style?.fontWeight, FontWeight.bold);
    expect(
      cancelText.style?.color,
      AppTheme.darkTheme.colorScheme.onSurfaceVariant,
    );

    // Verify Save button layout and style (ElevatedButton, fontSize 15, bold)
    final saveBtnFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(ElevatedButton),
    );
    expect(saveBtnFinder, findsOneWidget);
    final saveText = tester.widget<Text>(find.descendant(
      of: saveBtnFinder,
      matching: find.text(t.common.save),
    ));
    expect(saveText.style?.fontSize, 15);
    expect(saveText.style?.fontWeight, FontWeight.bold);

    // Scroll dialog until Save button is visible
    await tester.scrollUntilVisible(
      saveBtnFinder,
      100,
      scrollable: find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Save and verify update is called
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();

    expect(fakeProfileCubit.savedPrefs, isNotNull);
  });

  testWidgets('Custom macros dialog has synced button text size and colors',
      (tester) async {
    Macros? savedMacros;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: 800, name: TABLET),
              Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
            ],
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: NutritionDashboard(
                currentDaily: const DailyNutrition(),
                targetMacros: const Macros(
                  calories: 2000,
                  protein: 150,
                  carbs: 200,
                  fat: 60,
                ),
                isCustomMacros: true,
                onEditMacros: (m) => savedMacros = m,
                onRevertSystem: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the dashboard to open the custom macros dialog
    await tester.tap(find.byType(NutritionDashboard));
    await tester.pumpAndSettle();

    // Verify dialog title has font size 20 and bold
    final titleFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.text(t.nutrition.title_cust_macros),
    );
    expect(titleFinder, findsOneWidget);
    final titleText = tester.widget<Text>(titleFinder);
    expect(titleText.style?.fontSize, 20);
    expect(titleText.style?.fontWeight, FontWeight.bold);

    // Verify Cancel button (TextButton, fontSize 15, bold, onSurfaceVariant)
    final cancelBtnFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(TextButton, t.common.cancel),
    );
    expect(cancelBtnFinder, findsOneWidget);
    final cancelText = tester.widget<Text>(find.descendant(
      of: cancelBtnFinder,
      matching: find.text(t.common.cancel),
    ));
    expect(cancelText.style?.fontSize, 15);
    expect(cancelText.style?.fontWeight, FontWeight.bold);
    expect(
      cancelText.style?.color,
      AppTheme.darkTheme.colorScheme.onSurfaceVariant,
    );

    // Verify Save button (ElevatedButton, fontSize 15, bold)
    final saveBtnFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(ElevatedButton, t.common.save),
    );
    expect(saveBtnFinder, findsOneWidget);
    final saveText = tester.widget<Text>(find.descendant(
      of: saveBtnFinder,
      matching: find.text(t.common.save),
    ));
    expect(saveText.style?.fontSize, 15);
    expect(saveText.style?.fontWeight, FontWeight.bold);

    // Verify System / Revert button
    final systemBtnFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(TextButton, t.settings.btn_theme_system),
    );
    expect(systemBtnFinder, findsOneWidget);
    final systemText = tester.widget<Text>(find.descendant(
      of: systemBtnFinder,
      matching: find.text(t.settings.btn_theme_system),
    ));
    expect(systemText.style?.fontSize, 14);
    expect(systemText.style?.fontWeight, FontWeight.bold);
    expect(
      systemText.style?.color,
      AppTheme.darkTheme.colorScheme.primary,
    );

    // Tap Save and verify save callback is executed
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();
    expect(savedMacros, isNotNull);
  });
}
