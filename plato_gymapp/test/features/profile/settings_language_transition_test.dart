import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plato_gymapp/core/designsystem/theme/theme_cubit.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/settings_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  _FakeProfileCubit()
    : super(
        const ProfileState(
          userProfile: UserProfile(
            targetMacros: Macros(
              calories: 2000,
              protein: 150,
              carbs: 200,
              fat: 60,
            ),
            detailedBodyMetrics: BodyMetrics(),
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings animates only after the language dialog closes', (
    tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.vi);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SharedPreferences>()) {
      await getIt.unregister<SharedPreferences>();
    }
    getIt.registerSingleton<SharedPreferences>(prefs);
    addTearDown(() async {
      if (getIt.isRegistered<SharedPreferences>()) {
        await getIt.unregister<SharedPreferences>();
      }
    });

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ProfileCubit>(create: (_) => _FakeProfileCubit()),
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          ],
          child: MaterialApp(
            builder: (context, child) => ResponsiveBreakpoints.builder(
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
              ],
              child: child!,
            ),
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final languageTile = find.text(t.settings.lbl_item_language);
    await tester.scrollUntilVisible(
      languageTile,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(languageTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pump();

    expect(find.byType(Dialog), findsOneWidget);
    expect(LocaleSettings.currentLocale, AppLocale.vi);

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(Dialog), findsNothing);
    expect(LocaleSettings.currentLocale, AppLocale.en);
    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('language-change-opacity')),
    );
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('language-change-transform')),
    );
    expect(opacity.opacity, lessThan(1));
    expect(transform.transform.getTranslation().y, greaterThan(0));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
