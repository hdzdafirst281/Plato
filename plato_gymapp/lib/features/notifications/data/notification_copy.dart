import 'package:plato_gymapp/i18n/strings.g.dart';

/// All copy comes from the Sheet-generated translations. Missing keys are not
/// replaced by hardcoded copy or exposed to users as raw localization keys.
class NotificationCopy {
  static String? text(String key, [Map<String, String> args = const {}]) {
    final value = t[key];
    if (value == null) return null;
    if (value is String) return value;
    if (value is Function) {
      return Function.apply(value, const [], {
            for (final entry in args.entries) Symbol(entry.key): entry.value,
          })
          as String;
    }
    return null;
  }

  static bool get available => text('notifications.title_settings') != null;
}
