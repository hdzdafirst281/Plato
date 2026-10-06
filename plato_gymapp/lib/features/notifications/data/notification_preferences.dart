import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPreferenceKind { hydration, recovery, streak, rank }

class NotificationPreferences {
  final bool masterEnabled;
  final bool hydrationEnabled;
  final bool recoveryEnabled;
  final bool streakEnabled;
  final bool rankEnabled;

  const NotificationPreferences({
    required this.masterEnabled,
    required this.hydrationEnabled,
    required this.recoveryEnabled,
    required this.streakEnabled,
    required this.rankEnabled,
  });

  static const defaults = NotificationPreferences(
    masterEnabled: true,
    hydrationEnabled: false,
    recoveryEnabled: true,
    streakEnabled: true,
    rankEnabled: true,
  );

  bool enabled(NotificationPreferenceKind kind) => switch (kind) {
    NotificationPreferenceKind.hydration => hydrationEnabled,
    NotificationPreferenceKind.recovery => recoveryEnabled,
    NotificationPreferenceKind.streak => streakEnabled,
    NotificationPreferenceKind.rank => rankEnabled,
  };

  bool get hasEnabledCategory =>
      hydrationEnabled || recoveryEnabled || streakEnabled || rankEnabled;

  int get enabledCategoryCount => [
    hydrationEnabled,
    recoveryEnabled,
    streakEnabled,
    rankEnabled,
  ].where((value) => value).length;

  /// Turning the master switch off is an explicit opt-out, so every category
  /// switch follows it. Turning it on does not guess which categories the
  /// user wants; a category can enable the master through [withPreference].
  NotificationPreferences withMasterEnabled(bool value) => value
      ? copyWith(masterEnabled: true)
      : copyWith(
          masterEnabled: false,
          hydrationEnabled: false,
          recoveryEnabled: false,
          streakEnabled: false,
          rankEnabled: false,
        );

  /// Enabling any category also enables the master switch. Disabling one
  /// category leaves the master and the other category choices unchanged.
  NotificationPreferences withPreference(
    NotificationPreferenceKind kind,
    bool value,
  ) {
    final updated = switch (kind) {
      NotificationPreferenceKind.hydration => copyWith(hydrationEnabled: value),
      NotificationPreferenceKind.recovery => copyWith(recoveryEnabled: value),
      NotificationPreferenceKind.streak => copyWith(streakEnabled: value),
      NotificationPreferenceKind.rank => copyWith(rankEnabled: value),
    };
    return value ? updated.copyWith(masterEnabled: true) : updated;
  }

  NotificationPreferences get normalized =>
      !masterEnabled && hasEnabledCategory ? withMasterEnabled(false) : this;

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? hydrationEnabled,
    bool? recoveryEnabled,
    bool? streakEnabled,
    bool? rankEnabled,
  }) => NotificationPreferences(
    masterEnabled: masterEnabled ?? this.masterEnabled,
    hydrationEnabled: hydrationEnabled ?? this.hydrationEnabled,
    recoveryEnabled: recoveryEnabled ?? this.recoveryEnabled,
    streakEnabled: streakEnabled ?? this.streakEnabled,
    rankEnabled: rankEnabled ?? this.rankEnabled,
  );
}

class NotificationPreferencesStore {
  static const _migrationKey = 'notification_preferences_scoped_v1';
  final SharedPreferences prefs;

  const NotificationPreferencesStore(this.prefs);

  Future<NotificationPreferences> load(String scope) async {
    final prefix = _prefix(scope);
    if (prefs.getBool(_migrationKey) != true) {
      final migrated = NotificationPreferences(
        masterEnabled: prefs.getBool('notification_enabled') ?? true,
        hydrationEnabled: prefs.getBool('notification_water') ?? false,
        recoveryEnabled: true,
        streakEnabled: true,
        rankEnabled: true,
      ).normalized;
      await save(scope, migrated);
      await prefs.setBool(_migrationKey, true);
      return migrated;
    }
    final loaded = NotificationPreferences(
      masterEnabled:
          prefs.getBool('${prefix}master') ??
          NotificationPreferences.defaults.masterEnabled,
      hydrationEnabled:
          prefs.getBool('${prefix}hydration') ??
          NotificationPreferences.defaults.hydrationEnabled,
      recoveryEnabled:
          prefs.getBool('${prefix}recovery') ??
          NotificationPreferences.defaults.recoveryEnabled,
      streakEnabled:
          prefs.getBool('${prefix}streak') ??
          NotificationPreferences.defaults.streakEnabled,
      rankEnabled:
          prefs.getBool('${prefix}rank') ??
          NotificationPreferences.defaults.rankEnabled,
    );
    final normalized = loaded.normalized;
    if (!loaded.masterEnabled && loaded.hasEnabledCategory) {
      await save(scope, normalized);
    }
    return normalized;
  }

  Future<void> save(String scope, NotificationPreferences value) async {
    final prefix = _prefix(scope);
    final normalized = value.normalized;
    await Future.wait([
      prefs.setBool('${prefix}master', normalized.masterEnabled),
      prefs.setBool('${prefix}hydration', normalized.hydrationEnabled),
      prefs.setBool('${prefix}recovery', normalized.recoveryEnabled),
      prefs.setBool('${prefix}streak', normalized.streakEnabled),
      prefs.setBool('${prefix}rank', normalized.rankEnabled),
    ]);
  }

  static String _prefix(String scope) => 'notification_pref_${scope}_';
}
