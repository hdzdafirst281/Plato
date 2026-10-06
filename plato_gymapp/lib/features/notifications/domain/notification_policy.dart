/// Pure delivery policy. A budget is a ceiling, never a target.
enum ReminderKind { workout, streak, rank, recovery, hydration, inactivity }

enum ReminderSuppressionReason {
  deadlineExpired,
  duplicateKey,
  duplicateAutomaticKind,
  dailyLimit,
  pendingQueueLimit,
}

class SuppressedReminder {
  final ReminderCandidate candidate;
  final ReminderSuppressionReason reason;

  const SuppressedReminder(this.candidate, this.reason);
}

class MovedReminder {
  final ReminderCandidate original;
  final ReminderCandidate selected;

  const MovedReminder(this.original, this.selected);
}

class NotificationPlanResult {
  final List<ReminderCandidate> selected;
  final List<SuppressedReminder> suppressed;
  final List<MovedReminder> moved;

  const NotificationPlanResult({
    required this.selected,
    required this.suppressed,
    required this.moved,
  });
}

class ReminderDeliveryOption {
  final DateTime at;
  final String? titleKey;
  final String? bodyKey;
  final Map<String, String>? arguments;

  const ReminderDeliveryOption({
    required this.at,
    this.titleKey,
    this.bodyKey,
    this.arguments,
  });
}

class ReminderCandidate {
  final String key;
  final ReminderKind kind;
  final DateTime at;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> arguments;
  final String route;
  final String? sourceId;
  final String? actionLabelKey;
  final List<ReminderDeliveryOption> alternatives;
  final Map<String, String> metadata;

  const ReminderCandidate({
    required this.key,
    required this.kind,
    required this.at,
    required this.titleKey,
    required this.bodyKey,
    this.arguments = const {},
    required this.route,
    this.sourceId,
    this.actionLabelKey,
    this.alternatives = const [],
    this.metadata = const {},
  });

  ReminderCandidate atOption(ReminderDeliveryOption option) =>
      ReminderCandidate(
        key: key,
        kind: kind,
        at: option.at,
        titleKey: option.titleKey ?? titleKey,
        bodyKey: option.bodyKey ?? bodyKey,
        arguments: option.arguments ?? arguments,
        route: route,
        sourceId: sourceId,
        actionLabelKey: actionLabelKey,
        metadata: metadata,
      );

  ReminderCandidate copyWith({
    DateTime? at,
    String? titleKey,
    String? bodyKey,
    Map<String, String>? arguments,
    List<ReminderDeliveryOption>? alternatives,
    Map<String, String>? metadata,
    String? actionLabelKey,
  }) => ReminderCandidate(
    key: key,
    kind: kind,
    at: at ?? this.at,
    titleKey: titleKey ?? this.titleKey,
    bodyKey: bodyKey ?? this.bodyKey,
    arguments: arguments ?? this.arguments,
    route: route,
    sourceId: sourceId,
    actionLabelKey: actionLabelKey ?? this.actionLabelKey,
    alternatives: alternatives ?? this.alternatives,
    metadata: metadata ?? this.metadata,
  );
}

class NotificationPolicy {
  static const softMaxPerDay = 3;
  static const maxPerDay = 4;

  static String dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String? hydrationBody(double consumed, double target) {
    if (!target.isFinite ||
        target <= 0 ||
        !consumed.isFinite ||
        consumed >= target) {
      return null;
    }
    if (consumed <= 0) return 'notifications.body_hydration_no_log';
    return consumed / target < .5
        ? 'notifications.body_hydration_low'
        : 'notifications.body_hydration_progress';
  }

  /// Allocates fixed reminders first, then moves deadline-based reminders only
  /// to their explicit fallback times. It never invents a delivery time.
  static List<ReminderCandidate> select(
    List<ReminderCandidate> candidates, {
    required DateTime now,
    List<ReminderCandidate> committed = const [],
    int pendingLimit = 48,
  }) => plan(
    candidates,
    now: now,
    committed: committed,
    pendingLimit: pendingLimit,
  ).selected;

  static NotificationPlanResult plan(
    List<ReminderCandidate> candidates, {
    required DateTime now,
    List<ReminderCandidate> committed = const [],
    int pendingLimit = 48,
  }) {
    final accepted = <ReminderCandidate>[];
    final suppressed = <SuppressedReminder>[];
    final moved = <MovedReminder>[];
    final occupied = [...committed];
    final seen = committed.map((e) => e.key).toSet();

    int priorityOf(ReminderKind kind) => switch (kind) {
      ReminderKind.workout => 0,
      ReminderKind.rank => 1,
      ReminderKind.streak => 2,
      ReminderKind.recovery => 3,
      ReminderKind.hydration => 4,
      ReminderKind.inactivity => 5,
    };

    final ordered = [...candidates]
      ..sort((a, b) {
        final dayOrder = dayKey(a.at).compareTo(dayKey(b.at));
        if (dayOrder != 0) return dayOrder;
        final priority = priorityOf(a.kind).compareTo(priorityOf(b.kind));
        return priority != 0 ? priority : a.at.compareTo(b.at);
      });

    // User-authored workout reminders are fixed and reserve their real day.
    for (final candidate in ordered.where(
      (candidate) => candidate.kind == ReminderKind.workout,
    )) {
      final reason = _acceptFixed(candidate, now, occupied, accepted, seen);
      if (reason != null) suppressed.add(SuppressedReminder(candidate, reason));
    }

    final automatic =
        ordered
            .where((candidate) => candidate.kind != ReminderKind.workout)
            .toList()
          ..sort((a, b) {
            final priority = priorityOf(a.kind).compareTo(priorityOf(b.kind));
            return priority != 0 ? priority : a.at.compareTo(b.at);
          });
    for (final candidate in automatic) {
      if (seen.contains(candidate.key)) {
        suppressed.add(
          SuppressedReminder(candidate, ReminderSuppressionReason.duplicateKey),
        );
        continue;
      }
      final options = <ReminderCandidate>[
        candidate,
        ...candidate.alternatives.map(candidate.atOption),
      ].where((option) => option.at.isAfter(now)).toList();
      if (options.isEmpty) {
        suppressed.add(
          SuppressedReminder(
            candidate,
            ReminderSuppressionReason.deadlineExpired,
          ),
        );
        continue;
      }

      ReminderCandidate? choice;
      for (final option in options) {
        if (_dayCount(occupied, option.at) < softMaxPerDay &&
            !_sameAutomaticKind(occupied, option)) {
          choice = option;
          break;
        }
      }
      if (choice == null) {
        for (final option in options) {
          if (_dayCount(occupied, option.at) < maxPerDay &&
              !_sameAutomaticKind(occupied, option)) {
            choice = option;
            break;
          }
        }
      }
      if (choice == null) {
        final duplicateKind = options.every(
          (option) => _sameAutomaticKind(occupied, option),
        );
        suppressed.add(
          SuppressedReminder(
            candidate,
            duplicateKind
                ? ReminderSuppressionReason.duplicateAutomaticKind
                : ReminderSuppressionReason.dailyLimit,
          ),
        );
        continue;
      }
      accepted.add(choice);
      occupied.add(choice);
      seen.add(choice.key);
      if (choice.at != candidate.at)
        moved.add(MovedReminder(candidate, choice));
    }

    accepted.sort((a, b) => a.at.compareTo(b.at));
    if (accepted.length > pendingLimit) {
      for (final candidate in accepted.skip(pendingLimit)) {
        suppressed.add(
          SuppressedReminder(
            candidate,
            ReminderSuppressionReason.pendingQueueLimit,
          ),
        );
      }
      accepted.removeRange(pendingLimit, accepted.length);
    }
    return NotificationPlanResult(
      selected: List.unmodifiable(accepted),
      suppressed: List.unmodifiable(suppressed),
      moved: List.unmodifiable(moved),
    );
  }

  static ReminderSuppressionReason? _acceptFixed(
    ReminderCandidate candidate,
    DateTime now,
    List<ReminderCandidate> occupied,
    List<ReminderCandidate> accepted,
    Set<String> seen,
  ) {
    if (!candidate.at.isAfter(now)) {
      return ReminderSuppressionReason.deadlineExpired;
    }
    if (seen.contains(candidate.key)) {
      return ReminderSuppressionReason.duplicateKey;
    }
    if (_dayCount(occupied, candidate.at) >= maxPerDay) {
      return ReminderSuppressionReason.dailyLimit;
    }
    accepted.add(candidate);
    occupied.add(candidate);
    seen.add(candidate.key);
    return null;
  }

  static int _dayCount(List<ReminderCandidate> items, DateTime at) =>
      items.where((item) => dayKey(item.at) == dayKey(at)).length;

  static bool _sameAutomaticKind(
    List<ReminderCandidate> items,
    ReminderCandidate candidate,
  ) => items.any(
    (item) =>
        item.kind == candidate.kind &&
        item.kind != ReminderKind.workout &&
        dayKey(item.at) == dayKey(candidate.at),
  );
}
