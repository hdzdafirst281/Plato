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

  bool selected(NotificationPreferenceKind kind) => switch (kind) {
    NotificationPreferenceKind.hydration => hydrationEnabled,
    NotificationPreferenceKind.recovery => recoveryEnabled,
    NotificationPreferenceKind.streak => streakEnabled,
    NotificationPreferenceKind.rank => rankEnabled,
  };

  bool enabled(NotificationPreferenceKind kind) =>
      masterEnabled && selected(kind);

  bool get hasSelectedCategory =>
      hydrationEnabled || recoveryEnabled || streakEnabled || rankEnabled;

  bool get hasEnabledCategory => masterEnabled && hasSelectedCategory;

  int get enabledCategoryCount => [
    for (final kind in NotificationPreferenceKind.values) enabled(kind),
  ].where((value) => value).length;

  /// Category choices remain stored while the master switch is off so turning
  /// it back on restores the user's previous selection. [enabled] still makes
  /// every category appear and behave as disabled while the master is off.
  NotificationPreferences withMasterEnabled(bool value) =>
      copyWith(masterEnabled: value);

  /// Enabling any category also enables the master switch. Disabling one
  /// category leaves the master and the other category choices unchanged.
  NotificationPreferences withPreference(
    NotificationPreferenceKind kind,
    bool value,
  ) {
    final base = value && !masterEnabled
        ? copyWith(
            masterEnabled: true,
            hydrationEnabled: false,
            recoveryEnabled: false,
            streakEnabled: false,
            rankEnabled: false,
          )
        : this;
    final updated = switch (kind) {
      NotificationPreferenceKind.hydration => base.copyWith(
        hydrationEnabled: value,
      ),
      NotificationPreferenceKind.recovery => base.copyWith(
        recoveryEnabled: value,
      ),
      NotificationPreferenceKind.streak => base.copyWith(streakEnabled: value),
      NotificationPreferenceKind.rank => base.copyWith(rankEnabled: value),
    };
    return value ? updated.copyWith(masterEnabled: true) : updated;
  }

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
      );
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
    return loaded;
  }

  Future<void> save(String scope, NotificationPreferences value) async {
    final prefix = _prefix(scope);
    await Future.wait([
      prefs.setBool('${prefix}master', value.masterEnabled),
      prefs.setBool('${prefix}hydration', value.hydrationEnabled),
      prefs.setBool('${prefix}recovery', value.recoveryEnabled),
      prefs.setBool('${prefix}streak', value.streakEnabled),
      prefs.setBool('${prefix}rank', value.rankEnabled),
    ]);
  }

  static String _prefix(String scope) => 'notification_pref_${scope}_';
}
