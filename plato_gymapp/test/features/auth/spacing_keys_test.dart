import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.vi);
  });

  group('Localization Spacing Verification', () {
    test('Onboarding terms and and-label have appropriate spacing', () {
      final t = LocaleSettings.instance.currentTranslations;
      final agree = '${t.onboarding.lbl_agree_terms} ';
      final andLabel = ' ${t.onboarding.lbl_and} ';
      final terms = t.onboarding.lbl_terms_link;
      final eula = t.onboarding.lbl_eula_link;

      final fullString = '$agree$terms$andLabel$eula';
      expect(fullString, 'Tôi đã đọc và đồng ý với Điều khoản sử dụng và Thỏa thuận EULA');
    });

    test('English onboarding terms and and-label have appropriate spacing', () {
      LocaleSettings.setLocale(AppLocale.en);
      final t = LocaleSettings.instance.currentTranslations;
      final agree = '${t.onboarding.lbl_agree_terms} ';
      final andLabel = ' ${t.onboarding.lbl_and} ';
      final terms = t.onboarding.lbl_terms_link;
      final eula = t.onboarding.lbl_eula_link;

      final fullString = '$agree$terms$andLabel$eula';
      expect(fullString, 'I have read and agree to the Terms of Use and EULA Agreement');
      LocaleSettings.setLocale(AppLocale.vi);
    });

    test('Routine duplicate name string interpolation has space before suffix', () {
      final t = LocaleSettings.instance.currentTranslations;
      const routineName = 'Full Body';
      final duplicatedName = '$routineName ${t.workout.lbl_copy_suffix}';
      expect(duplicatedName, 'Full Body (Bản sao)');
    });

    test('History metrics label and description formatting has colon and space separator', () {
      final t = LocaleSettings.instance.currentTranslations;
      final label = t.translateDynamic('stats.lbl_metric_volume');
      final desc = t.translateDynamic('stats.desc_history_info_metrics_volume');
      final formatted = '$label: $desc';

      expect(formatted, 'Tổng tải trọng: Tổng khối lượng tạ bạn đã chinh phục.');
    });
  });
}
