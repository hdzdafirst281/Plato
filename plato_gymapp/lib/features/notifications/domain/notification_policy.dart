/// Pure delivery policy. A budget is a ceiling, never a target.
enum ReminderKind { workout, streak, rank, hydration, recovery, inactivity }

class ReminderCandidate {
  final String key;
  final ReminderKind kind;
  final DateTime at;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> arguments;
  final String route;
  final String? sourceId;

  const ReminderCandidate({
    required this.key,
    required this.kind,
    required this.at,
    required this.titleKey,
    required this.bodyKey,
    this.arguments = const {},
    required this.route,
    this.sourceId,
  });
}

class NotificationPolicy {
  static String dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime monday(DateTime date) =>
      DateTime(date.year, date.month, date.day - date.weekday + 1);

  static String? hydrationBody(double consumed, double target) {
    if (!target.isFinite ||
        target <= 0 ||
        !consumed.isFinite ||
        consumed >= target)
      return null;
    if (consumed <= 0) return 'notifications.body_hydration_no_log';
    return consumed / target < .5
        ? 'notifications.body_hydration_low'
        : 'notifications.body_hydration_progress';
  }

  /// [committed] includes past scheduled slots: reopening cannot reset the cap.
  /// Never move a candidate to another time/day to fill the budget.
  static List<ReminderCandidate> select(
    List<ReminderCandidate> candidates, {
    required DateTime now,
    List<ReminderCandidate> committed = const [],
    int dailyLimit = 3,
    int quietStart = 22,
    int quietEnd = 8,
    int pendingLimit = 48,
    int quietStartMinute = 0,
    int quietEndMinute = 0,
  }) {
    final limit = dailyLimit.clamp(1, 4);
    final accepted = <ReminderCandidate>[];
    final occupied = [...committed];
    final seen = committed.map((e) => e.key).toSet();
    final ordered = [...candidates]
      ..sort((a, b) {
        // Reserve nearer days before filling the finite OS queue with distant workouts.
        final dayOrder = dayKey(a.at).compareTo(dayKey(b.at));
        if (dayOrder != 0) return dayOrder;
        int priorityOf(ReminderKind kind) =>
            kind == ReminderKind.rank ? ReminderKind.streak.index : kind.index;
        final priority = priorityOf(a.kind).compareTo(priorityOf(b.kind));
        return priority != 0 ? priority : a.at.compareTo(b.at);
      });
    for (final candidate in ordered) {
      if (accepted.length >= pendingLimit) break;
      if (!candidate.at.isAfter(now) || seen.contains(candidate.key)) continue;
      final minute = candidate.at.hour * 60 + candidate.at.minute;
      final start = quietStart * 60 + quietStartMinute;
      final end = quietEnd * 60 + quietEndMinute;
      final quiet = start == end
          ? false
          : start > end
          ? minute >= start || minute < end
          : minute >= start && minute < end;
      if (quiet) continue;
      final day = dayKey(candidate.at);
      final sameDay = occupied.where((e) => dayKey(e.at) == day).toList();
      if (sameDay.length >= limit) continue;
      if (candidate.kind == ReminderKind.workout &&
          sameDay.where((e) => e.kind == ReminderKind.workout).length >=
              (limit == 4 ? 3 : 2))
        continue;
      if (sameDay.any(
        (e) =>
            e.kind == candidate.kind && candidate.kind != ReminderKind.workout,
      ))
        continue;
      if (candidate.kind != ReminderKind.workout &&
          occupied.any(
            (e) =>
                e.at.difference(candidate.at).abs() < const Duration(hours: 3),
          ))
        continue;
      if ((candidate.kind == ReminderKind.recovery ||
              candidate.kind == ReminderKind.inactivity) &&
          sameDay.any((e) => e.kind == ReminderKind.workout))
        continue;
      if (candidate.kind == ReminderKind.recovery &&
          occupied
                  .where(
                    (e) =>
                        e.kind == ReminderKind.recovery &&
                        monday(e.at) == monday(candidate.at),
                  )
                  .length >=
              2)
        continue;
      accepted.add(candidate);
      occupied.add(candidate);
      seen.add(candidate.key);
    }
    return accepted..sort((a, b) => a.at.compareTo(b.at));
  }
}
