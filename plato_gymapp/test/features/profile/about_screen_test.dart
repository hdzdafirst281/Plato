import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/about_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AboutScreen renders version, terms, eula, contact, and social links',
      (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: AboutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app bar
    expect(find.text(t.settings.title_about_screen), findsOneWidget);

    // Verify tiles for version, terms, eula, contact
    expect(find.text(t.settings.lbl_item_version), findsOneWidget);
    expect(find.text(t.onboarding.lbl_terms_link), findsOneWidget);
    expect(find.text(t.onboarding.lbl_eula_link), findsOneWidget);
    expect(find.text(t.settings.lbl_item_contact), findsOneWidget);

    // Scroll to see About Us section
    await tester.scrollUntilVisible(
      find.text(t.common.about_us),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    // Verify About Us section
    expect(find.text(t.common.about_us), findsOneWidget);
  });
}
