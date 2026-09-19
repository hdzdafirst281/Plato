import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import '../../../workout/data/models/workout_models.dart';
import '../../data/models/gamification_models.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../domain/rank_calculator.dart';
import '../../domain/reward_progress.dart';

class WorkoutRewardsContent extends StatefulWidget {
  final WorkoutSession session;
  final UserGamificationStats stats;
  final RankScreenState? rank;
  final List<Quest> beforeQuests;
  final bool animateWorkout;
  final int? streakWeeks;
  final bool leveledUp;
  final String? claimingQuestId;
  final ValueChanged<Quest> onClaim;
  final VoidCallback? onClaimChest;
  final VoidCallback onContinue;
  final VoidCallback? onAnimationComplete;

  const WorkoutRewardsContent({
    super.key,
    required this.session,
    required this.stats,
    this.rank,
    this.beforeQuests = const [],
    this.animateWorkout = true,
    this.streakWeeks,
    this.leveledUp = false,
    this.claimingQuestId,
    required this.onClaim,
    this.onClaimChest,
    required this.onContinue,
    this.onAnimationComplete,
  });

  @override
  State<WorkoutRewardsContent> createState() => _WorkoutRewardsContentState();
}

class _WorkoutRewardsContentState extends State<WorkoutRewardsContent>
    with TickerProviderStateMixin {
  static const _leadIn = 180;
  static const _stageMillis = 960;
  late final AnimationController _sequence = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _leadIn + _stages.length * _stageMillis),
  );
  late final AnimationController _xpGain = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );
  Animation<double>? _routeAnimation;
  bool _started = false;
  bool _notified = false;
  late int _xpStart = math.max(
    0,
    RewardXpProgress.total(widget.stats) -
        (widget.animateWorkout ? widget.session.xpEarned : 0),
  );
  late int _xpTarget = RewardXpProgress.total(widget.stats);

  List<String> get _stages => [
    if (widget.streakWeeks != null) 'streak',
    if (widget.stats.weeklyQuests.isNotEmpty) ...['quests', 'chest'],
    'xp',
    if (widget.rank != null) 'rp',
  ];
  bool get _running => _sequence.value < 1;
  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _sequence.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_notified) {
        _notified = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onAnimationComplete?.call();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeAnimation?.removeStatusListener(_routeChanged);
    _routeAnimation = ModalRoute.of(context)?.animation;
    if (_reduceMotion) {
      _skip();
    } else if (!_started) {
      // Wait until the route is visible; do not spend the reveal behind a route transition.
      _routeAnimation?.addStatusListener(_routeChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (_routeAnimation == null ||
                _routeAnimation!.status == AnimationStatus.completed))
          _start();
      });
    }
  }

  void _routeChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) _start();
  }

  void _start() {
    if (_started || !mounted) return;
    _started = true;
    _sequence.forward();
  }

  void _skip() {
    _started = true;
    _sequence.value = 1;
    _xpGain.value = 1;
  }

  @override
  void didUpdateWidget(covariant WorkoutRewardsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = RewardXpProgress.total(widget.stats);
    if (next != _xpTarget) {
      _xpStart = _displayedXp;
      _xpTarget = next;
      if (!_running) {
        if (_reduceMotion) {
          _xpGain.value = 1;
        } else {
          _xpGain.forward(from: 0);
        }
      }
    }
  }

  double _phase(String id, int offset, int duration) {
    if (_sequence.isCompleted) return 1;
    final start = _leadIn + _stages.indexOf(id) * _stageMillis + offset;
    final elapsed = _sequence.value * _sequence.duration!.inMilliseconds;
    return ((elapsed - start) / duration).clamp(0.0, 1.0);
  }

  double _progress(String id) =>
      Curves.easeInOutCubic.transform(_phase(id, 280, 560));
  int _between(int from, int to, double progress) =>
      (from + (to - from) * progress).round();
  int get _displayedXp => _between(
    _xpStart,
    _xpTarget,
    _running ? _progress('xp') : Curves.easeOutCubic.transform(_xpGain.value),
  );

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_routeChanged);
    _sequence.dispose();
    _xpGain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_sequence, _xpGain]),
    builder: (context, _) => Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (_running || _xpGain.isAnimating) _skip();
      },
      child: Semantics(
        onTap: _running ? _skip : null,
        label: _running ? t.workout_rewards.tap_skip : null,
        child: AbsorbPointer(
          // A tap during the sequence only skips; it must not also claim or leave.
          absorbing: _running || _xpGain.isAnimating,
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 690;
                  final accessible =
                      MediaQuery.textScalerOf(context).scale(14) > 19;
                  final content = DefaultTextStyle.merge(
                    style: TextStyle(height: compact ? 1.15 : null),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final id in _stages) ...[
                          _reveal(id, switch (id) {
                            'streak' => _streak(compact),
                            'quests' => _quests(compact),
                            'chest' => _chest(compact),
                            'xp' => _xp(compact),
                            _ => _rank(compact),
                          }),
                          SizedBox(height: compact ? 3 : 10),
                        ],
                      ],
                    ),
                  );
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      compact ? 4 : 16,
                      16,
                      compact ? 4 : 12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            Expanded(
                              child: accessible || constraints.maxHeight < 500
                                  // Accessibility/landscape escape hatch; regular phone layouts never scroll.
                                  ? SingleChildScrollView(child: content)
                                  : Align(
                                      alignment: Alignment.center,
                                      child: content,
                                    ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: widget.onContinue,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  t.workout_rewards.summary,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _reveal(String id, Widget child) {
    final value = Curves.easeOutCubic.transform(_phase(id, 0, 240));
    return ExcludeSemantics(
      excluding: value < 1,
      child: Opacity(
        key: ValueKey('reveal-$id'),
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }

  Widget _card(Widget child, bool compact, {Color? accent}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 6 : 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent?.withValues(alpha: 0.4) ?? colors.outlineVariant,
        ),
      ),
      child: child,
    );
  }

  Widget _bar(String id, num current, num target, Color color) =>
      LinearProgressIndicator(
        key: ValueKey(id),
        value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
        minHeight: 6,
        borderRadius: BorderRadius.circular(6),
        color: color,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.08),
        semanticsLabel: '$current / $target',
      );

  Widget _streak(bool compact) {
    final weeks = _between(
      math.max(0, widget.streakWeeks! - 1),
      widget.streakWeeks!,
      _progress('streak'),
    );
    final color =
        (Theme.of(context).extension<GymColors>()?.warning ?? Colors.orange);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Symbols.local_fire_department,
          color: color,
          size: compact ? 24 : 36,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            t.workout_rewards.streak(weeks: weeks),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 18 : 22,
            ),
          ),
        ),
      ],
    );
  }

  String _questTitle(Quest quest) => switch (quest.type) {
    QuestType.WORKOUT_COUNT => t.profile.lbl_stats_workouts,
    QuestType.TOTAL_VOLUME => t.common.volume,
    QuestType.PR_COUNT => t.workout_rewards.quest_prs,
    QuestType.TOTAL_TIME => t.common.duration,
    QuestType.TOTAL_SETS => t.workout_rewards.quest_sets,
    QuestType.TOTAL_EXERCISES => t.profile.btn_menu_exercises,
  };
  String _number(int value) =>
      value >= 1000 && value % 1000 == 0 ? '${value ~/ 1000}k' : '$value';

  Widget _quests(bool compact) {
    final quests = widget.stats.weeklyQuests;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.gamification.title_weekly_quests,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (quests.any((q) => q.isCompleted && !q.claimedReward))
                Tooltip(
                  message: t.workout_rewards.tap_claim,
                  child: Icon(
                    Symbols.touch_app,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 3 : 10),
          for (var i = 0; i < quests.length; i += 2) ...[
            if (i > 0) SizedBox(height: compact ? 3 : 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _questTile(quests[i], compact)),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < quests.length
                      ? _questTile(quests[i + 1], compact)
                      : const SizedBox(),
                ),
              ],
            ),
          ],
        ],
      ),
      compact,
    );
  }

  Widget _questTile(Quest quest, bool compact) {
    final colors = Theme.of(context).colorScheme;
    final before = widget.beforeQuests
        .where((q) => q.id == quest.id)
        .firstOrNull;
    final current = _between(
      before?.current ?? quest.current,
      quest.current,
      _progress('quests'),
    );
    final ready = quest.isCompleted && !quest.claimedReward;
    final busy = widget.claimingQuestId == quest.id;
    final stateText = quest.claimedReward
        ? t.workout_rewards.claimed
        : ready
        ? t.workout_rewards.claim(xp: quest.xpReward)
        : '+${quest.xpReward} XP';
    return Tooltip(
      message: '${t.translateDynamic(quest.title)} · $stateText',
      child: Semantics(
        label:
            '${t.translateDynamic(quest.title)}, ${quest.current}/${quest.target}, $stateText',
        button: ready,
        child: Material(
          textStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(height: compact ? 1.15 : null),
          color: ready
              ? colors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: ValueKey('quest-${quest.id}'),
            borderRadius: BorderRadius.circular(10),
            onTap: ready && widget.claimingQuestId == null
                ? () => widget.onClaim(quest)
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _questTitle(quest),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (busy)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (quest.claimedReward || ready)
                          Icon(
                            quest.claimedReward
                                ? Symbols.check
                                : Symbols.redeem,
                            size: 16,
                            color: colors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _bar(
                      'quest-progress-${quest.id}',
                      (before?.current ?? quest.current) +
                          (quest.current - (before?.current ?? quest.current)) *
                              _progress('quests'),
                      quest.target,
                      colors.primary,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_number(current)}/${_number(quest.target)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          quest.claimedReward ? '✓' : '+${quest.xpReward} XP',
                          style: TextStyle(
                            fontSize: 11,
                            color: ready
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chest(bool compact) {
    final colors = Theme.of(context).colorScheme;
    final required = GamificationRepository.chestRequiredQuests;
    final completed = widget.stats.weeklyQuests
        .where((q) => q.isCompleted)
        .length;
    final before = widget.beforeQuests.isEmpty
        ? completed
        : widget.beforeQuests.where((q) => q.isCompleted).length;
    final animated = before + (completed - before) * _progress('chest');
    final current = animated.round().clamp(0, required);
    final claimed = widget.stats.isChestClaimed;
    final ready = completed >= required && !claimed;
    final busy = widget.claimingQuestId == 'weekly_chest';
    return Semantics(
      button: ready,
      label: ready
          ? t.workout_rewards.claim(xp: GamificationRepository.chestXp)
          : null,
      child: Material(
        textStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(height: compact ? 1.15 : null),
        color: Colors.transparent,
        child: InkWell(
          key: ready ? const ValueKey('claim-chest') : null,
          borderRadius: BorderRadius.circular(20),
          onTap: ready && widget.claimingQuestId == null
              ? widget.onClaimChest
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: _card(
              Row(
                children: [
                  Icon(
                    Symbols.redeem,
                    color: colors.primary,
                    size: compact ? 24 : 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${t.gamification.title_weekly_chest} · $current/$required',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _bar(
                          'chest-progress',
                          animated,
                          required,
                          colors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (claimed)
                    Tooltip(
                      message: t.workout_rewards.claimed,
                      child: const Icon(Symbols.check_circle),
                    )
                  else if (busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      '+${GamificationRepository.chestXp} XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: ready ? FontWeight.w700 : FontWeight.w400,
                        color: ready ? colors.primary : colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              compact,
              accent: ready ? colors.primary : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _xp(bool compact) {
    final colors = Theme.of(context).colorScheme;
    final (level, xp) = RewardXpProgress.at(_displayedXp);
    final target = RewardXpProgress.requirement(level);
    final leveled = widget.leveledUp && level >= widget.stats.level;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.workout_rewards.level(level: level),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (leveled)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: t.gamification.msg_level_up_base,
                    child: Icon(Symbols.stars, color: colors.primary, size: 20),
                  ),
                ),
              Text(
                '+${widget.session.xpEarned} XP',
                style: TextStyle(
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 3 : 10),
          _bar('xp-progress', xp, target, colors.primary),
          const SizedBox(height: 4),
          Text(
            '$xp / $target XP',
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
        ],
      ),
      compact,
      accent: colors.primary,
    );
  }

  static const _badges = [
    'bronze1',
    'bronze2',
    'silver1',
    'silver2',
    'gold1',
    'gold2',
    'gold3',
    'diamond',
  ];
  Widget _rank(bool compact) {
    final rank = widget.rank!;
    final info = RankConfig.getRankById(rank.currentRankId);
    final scale = RewardRankScale(info);
    final colors = Theme.of(context).colorScheme;
    final gym = Theme.of(context).extension<GymColors>();
    final earned =
        widget.session.startTime >= rank.cycleStartTimeMillis &&
            widget.session.startTime <
                rank.cycleStartTimeMillis + RankCalculator.cycleDurationMillis
        ? widget.session.exercises
              .expand((e) => e.sets)
              .where((s) => s.isCompleted)
              .length
        : 0;
    final before = widget.animateWorkout
        ? math.max(0, rank.totalRp - earned)
        : rank.totalRp;
    final current = _between(before, rank.totalRp, _progress('rp'));
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/badges/${_badges[info.id - 1]}.webp',
                width: compact ? 32 : 46,
                height: compact ? 32 : 46,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translateDynamic(info.nameKey),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$current RP',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+$earned RP',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            label:
                '$current RP, ${t.workout_rewards.zone_maintain} ${info.maintainPoints}'
                '${scale.canPromote ? ', ${t.workout_rewards.zone_promote} ${info.promotePoints}' : ''}',
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: 16,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            if (scale.canDemote)
                              Expanded(
                                flex: (scale.maintain * 10000).round(),
                                child: Container(
                                  key: const ValueKey('rank-zone-demote'),
                                  color: colors.error,
                                ),
                              ),
                            Expanded(
                              flex: ((scale.promote - scale.maintain) * 10000)
                                  .round(),
                              child: Container(
                                key: const ValueKey('rank-zone-maintain'),
                                color: gym?.goldRank ?? Colors.amber,
                              ),
                            ),
                            if (scale.canPromote)
                              Expanded(
                                flex: ((1 - scale.promote) * 10000).round(),
                                child: Container(
                                  key: const ValueKey('rank-zone-promote'),
                                  color: gym?.success ?? Colors.green,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left:
                          scale.position(
                            before + (rank.totalRp - before) * _progress('rp'),
                          ) *
                          math.max(0, constraints.maxWidth - 10),
                      child: Container(
                        key: const ValueKey('rp-marker'),
                        width: 10,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors.onSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (scale.canDemote)
                Text(
                  '${t.workout_rewards.zone_demote} <${info.maintainPoints}',
                  style: const TextStyle(fontSize: 10),
                ),
              Text(
                '${t.workout_rewards.zone_maintain} ≥${info.maintainPoints}',
                style: const TextStyle(fontSize: 10),
              ),
              if (scale.canPromote)
                Text(
                  '${t.workout_rewards.zone_promote} ≥${info.promotePoints}',
                  style: const TextStyle(fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.workout_rewards.rank_review,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ),
      compact,
    );
  }
}
