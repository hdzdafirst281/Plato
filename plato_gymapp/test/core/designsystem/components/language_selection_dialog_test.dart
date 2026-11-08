import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/language_selection_dialog.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final mode in {
    'light': Brightness.light,
    'dark': Brightness.dark,
  }.entries) {
    testWidgets(
      'highlights the selected row and returns a locale in ${mode.key} mode',
      (tester) async {
        LocaleSettings.setLocale(AppLocale.vi);
        AppLocale? selectedLocale;

        await tester.pumpWidget(
          TranslationProvider(
            child: MaterialApp(
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: mode.value,
                ),
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => Center(
                    child: FilledButton(
                      onPressed: () async {
                        selectedLocale = await LanguageSelectionDialog.show(
                          context: context,
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final vietnameseOption = find.byKey(
          const ValueKey('language-option-vi'),
        );
        final englishOption = find.byKey(const ValueKey('language-option-en'));

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text(t.settings.title_language_dialog), findsOneWidget);
        expect(find.text('Tiếng Việt'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.byIcon(Symbols.language), findsOneWidget);
        expect(
          tester.getSize(vietnameseOption).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester.getTopLeft(englishOption).dy,
          greaterThan(tester.getTopLeft(vietnameseOption).dy),
        );
        expect(
          find.descendant(
            of: vietnameseOption,
            matching: find.byIcon(Symbols.check),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: englishOption,
            matching: find.byIcon(Symbols.check),
          ),
          findsNothing,
        );
        final selectedDecoration =
            tester.widget<AnimatedContainer>(vietnameseOption).decoration
                as BoxDecoration;
        final unselectedDecoration =
            tester.widget<AnimatedContainer>(englishOption).decoration
                as BoxDecoration;
        expect(selectedDecoration.color, isNot(unselectedDecoration.color));
        expect(find.widgetWithText(TextButton, t.common.close), findsOneWidget);

        await tester.tap(englishOption);
        await tester.pumpAndSettle();

        expect(selectedLocale, AppLocale.en);
        expect(find.byType(Dialog), findsNothing);
      },
    );
  }

  testWidgets('always slides the new locale subtree in from below', (
    tester,
  ) async {
    var locale = 'vi';
    var trigger = 0;
    late StateSetter setHostState;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return Column(
                children: [
                  FilledButton(
                    onPressed: () => setHostState(() {
                      locale = 'en';
                      trigger++;
                    }),
                    child: const Text('Switch'),
                  ),
                  LanguageChangeTransition(
                    trigger: trigger,
                    child: Text(locale, key: ValueKey(locale)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Switch'));
    await tester.pump();

    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(LanguageChangeTransition),
        matching: find.byType(Transform),
      ),
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(LanguageChangeTransition),
        matching: find.byType(Opacity),
      ),
    );
    expect(transform.transform.getTranslation().y, closeTo(48, 0.01));
    expect(opacity.opacity, 0);
    expect(find.text('vi'), findsNothing);
    expect(find.text('en'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 320));
    final settledTransform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(LanguageChangeTransition),
        matching: find.byType(Transform),
      ),
    );
    final settledOpacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(LanguageChangeTransition),
        matching: find.byType(Opacity),
      ),
    );
    expect(settledTransform.transform.getTranslation().y, 0);
    expect(settledOpacity.opacity, 1);
  });

  testWidgets('waits for apply confirmation before closing the dialog', (
    tester,
  ) async {
    final confirmation = Completer<void>();
    var applyStarted = false;
    AppLocale? selectedLocale;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  selectedLocale = await LanguageSelectionDialog.show(
                    context: context,
                    onSelected: (locale) async {
                      applyStarted = true;
                      await confirmation.future;
                      return true;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pump();

    expect(applyStarted, isTrue);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(selectedLocale, isNull);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);

    confirmation.complete();
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(selectedLocale, AppLocale.en);
  });

  testWidgets('can hide the explicit close action for onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => LanguageSelectionDialog.show(
                  context: context,
                  showCloseAction: false,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, t.common.close), findsNothing);
  });
}
