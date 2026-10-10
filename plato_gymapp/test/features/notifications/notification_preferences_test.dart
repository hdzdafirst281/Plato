import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/features/notifications/data/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'legacy disabled master migrates with every category disabled',
    () async {
      SharedPreferences.setMockInitialValues({
        'notification_enabled': false,
        'notification_water': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final store = NotificationPreferencesStore(prefs);

      final first = await store.load('account-a');
      final second = await store.load('account-b');

      expect(first.masterEnabled, isFalse);
      expect(first.hasEnabledCategory, isFalse);
      expect(second, isNot(same(first)));
      expect(second.masterEnabled, isTrue);
      expect(second.hydrationEnabled, isFalse);
    },
  );

  test('category preferences stay isolated between account scopes', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = NotificationPreferencesStore(prefs);
    await store.load('account-a');
    await store.save(
      'account-a',
      NotificationPreferences.defaults.copyWith(
        recoveryEnabled: false,
        streakEnabled: false,
      ),
    );

    final first = await store.load('account-a');
    final second = await store.load('account-b');

    expect(first.recoveryEnabled, isFalse);
    expect(first.streakEnabled, isFalse);
    expect(second.recoveryEnabled, isTrue);
    expect(second.streakEnabled, isTrue);
  });

  test('turning master off disables categories but preserves selections', () {
    final result = NotificationPreferences.defaults
        .copyWith(hydrationEnabled: true)
        .withMasterEnabled(false);

    expect(result.masterEnabled, isFalse);
    expect(result.hasEnabledCategory, isFalse);
    expect(result.hasSelectedCategory, isTrue);
    expect(
      result.withMasterEnabled(true).enabledCategoryCount,
      NotificationPreferenceKind.values.length,
    );
  });

  test('enabling any category also enables the master switch', () {
    final disabled = NotificationPreferences.defaults.withMasterEnabled(false);

    for (final kind in NotificationPreferenceKind.values) {
      final result = disabled.withPreference(kind, true);
      expect(result.masterEnabled, isTrue, reason: kind.name);
      expect(result.enabled(kind), isTrue, reason: kind.name);
    }
  });

  test('disabling one category leaves master and other categories enabled', () {
    final result = NotificationPreferences.defaults.withPreference(
      NotificationPreferenceKind.recovery,
      false,
    );

    expect(result.masterEnabled, isTrue);
    expect(result.recoveryEnabled, isFalse);
    expect(result.streakEnabled, isTrue);
    expect(result.rankEnabled, isTrue);
  });

  test('enabled category count excludes the master preference', () {
    final result = NotificationPreferences.defaults.copyWith(
      hydrationEnabled: true,
      recoveryEnabled: false,
    );

    expect(result.enabledCategoryCount, 3);
    expect(result.withMasterEnabled(false).enabledCategoryCount, 0);
  });

  test(
    'store preserves category selections while master is disabled',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = NotificationPreferencesStore(prefs);
      await store.load('account-a');
      await store.save(
        'account-a',
        NotificationPreferences.defaults.copyWith(masterEnabled: false),
      );

      final loaded = await store.load('account-a');
      expect(loaded.masterEnabled, isFalse);
      expect(loaded.hasEnabledCategory, isFalse);
      expect(loaded.hasSelectedCategory, isTrue);
      expect(loaded.withMasterEnabled(true).enabledCategoryCount, 3);
    },
  );
}
