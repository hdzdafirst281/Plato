import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../workout/domain/streak_calculator.dart';
import '../components/workout_rewards_content.dart';
export '../components/workout_rewards_content.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

import '../../../notifications/application/notification_coordinator.dart';
import '../../../workout/data/models/workout_models.dart';
import '../../../workout/presentation/bloc/workout_cubit.dart';
import '../../data/models/gamification_models.dart';
import '../bloc/gamification_cubit.dart';
import '../bloc/rank_cubit.dart';

/// Carries the actual save operation, so intermediate history emissions cannot
/// be mistaken for a fully awarded workout.
class WorkoutRewardsRequest {
  final String workoutId;
  final Future<WorkoutSession?> completion;
  final List<Quest> beforeQuests;

  WorkoutRewardsRequest({
    required this.workoutId,
    required this.completion,
    this.beforeQuests = const [],
  }) {
    // The route may mount on a later frame or be removed before it mounts.
    // Keep errors handled here; awaiting the original future still reports them.
    completion.ignore();
  }
}

class WorkoutRewardsScreen extends StatefulWidget {
  final String? workoutId;
  final Future<WorkoutSession?>? completion;
  final List<Quest> beforeQuests;

  const WorkoutRewardsScreen({
    super.key,
    this.workoutId,
    this.completion,
    this.beforeQuests = const [],
  });

  @override
  State<WorkoutRewardsScreen> createState() => _WorkoutRewardsScreenState();
}

class _WorkoutRewardsScreenState extends State<WorkoutRewardsScreen> {
  WorkoutSession? _session;
  bool _failed = false;
  bool _leaving = false;
  String? _claiming;
  int? _initialLevel;
  bool _workoutLevelUp = false;
  int? _streakWeeks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      if (widget.workoutId == null) throw StateError('Missing workout ID');
      final gamification = context.read<GamificationCubit>();
      final rank = context.read<RankCubit>();
      final workouts = context.read<WorkoutCubit>();
      final session = widget.completion != null
          ? await widget.completion!
          : workouts.state.historicalWorkoutSessionsList
                .where((s) => s.id == widget.workoutId && !s.isDeleted)
                .firstOrNull;
      if (!mounted) return;
      if (session == null || session.isDeleted) {
        throw StateError('Workout unavailable');
      }
      final beforeHistory = workouts.state.historicalWorkoutSessionsList
          .where((s) => s.id != session.id)
          .toList();
      final history = [...beforeHistory, session];
      final now = DateTime.now();
      final streak = StreakCalculator.count(history, now);
      final increased =
          widget.completion != null &&
          StreakCalculator.qualifies(session) &&
          StreakCalculator.weekStart(
                DateTime.fromMillisecondsSinceEpoch(session.startTime),
              ) ==
              StreakCalculator.weekStart(now) &&
          streak > StreakCalculator.count(beforeHistory, now);
      await gamification.refreshWeeklyQuests(history);
      await gamification.refreshStateFromPrefs();
      await rank.refreshRankData();
      if (!mounted) return;
      final stats = gamification.state.stats;
      setState(() {
        _session = session;
        _streakWeeks = increased ? streak : null;
        _initialLevel = stats.level;
        _workoutLevelUp =
            widget.completion != null &&
            stats.level > 1 &&
            session.xpEarned > stats.currentXp;
      });
      if (!MediaQuery.disableAnimationsOf(context)) {
        unawaited(HapticFeedback.mediumImpact());
      }
    } catch (error, stack) {
      debugPrint('Workout rewards could not load: $error\n$stack');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _claim(Quest quest) async {
    if (_claiming != null || quest.claimedReward || !quest.isCompleted) return;
    await _claimReward(
      quest.id,
      () => context.read<GamificationCubit>().claimQuestReward(quest.id),
    );
  }

  Future<void> _claimChest() async {
    if (_claiming != null) return;
    await _claimReward(
      'weekly_chest',
      () => context.read<GamificationCubit>().claimChestReward(),
    );
  }

  Future<void> _claimReward(String id, Future<void> Function() claim) async {
    setState(() => _claiming = id);
    try {
      await claim();
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        unawaited(HapticFeedback.lightImpact());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.workout_rewards.claim_error)));
      }
    } finally {
      if (mounted) setState(() => _claiming = null);
    }
  }

  Future<void> _acknowledgeAnimation() async {
    final service = NotificationCoordinator.instance;
    if (service == null) return;
    final scope = service.scope;
    final key = 'event:completed:${widget.workoutId}';
    try {
      final event = await service.store.read(key);
      if (!mounted || scope != service.scope || event == null) return;
      // Keep unrelated milestones available for the summary/notification host.
      final remaining = (event['parts'] as List).where((part) {
        final title = part['title'] as String;
        return !(title == 'gamification.msg_level_up_base' &&
                _workoutLevelUp) &&
            !(_streakWeeks != null &&
                title.startsWith('notifications.title_streak_'));
      }).toList();
      await service.store.write(key, {
        ...event,
        'parts': remaining,
        'shown': remaining.isEmpty || event['shown'] == true,
      });
    } catch (error) {
      debugPrint('Reward feedback acknowledgement failed: $error');
    }
  }

  void _continue() {
    if (_leaving) return;
    _leaving = true;
    context.pushReplacementNamed('session_summary', extra: widget.workoutId);
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_failed)
                    const Icon(Symbols.info, size: 40)
                  else
                    const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _failed
                        ? t.workout_rewards.load_error
                        : t.workout_rewards.loading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/workout'),
                    child: Text(t.common.back),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return BlocBuilder<GamificationCubit, GamificationState>(
      builder: (context, gamification) =>
          BlocBuilder<RankCubit, RankScreenState?>(
            builder: (context, rank) => WorkoutRewardsContent(
              session: _session!,
              stats: gamification.stats,
              rank: rank,
              leveledUp:
                  _workoutLevelUp || gamification.stats.level > _initialLevel!,
              claimingQuestId: _claiming,
              onClaim: _claim,
              onClaimChest: _claimChest,
              onContinue: _continue,
              beforeQuests: widget.beforeQuests,
              animateWorkout: widget.completion != null,
              streakWeeks: _streakWeeks,
              onAnimationComplete: _acknowledgeAnimation,
            ),
          ),
    );
  }
}