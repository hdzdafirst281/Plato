import 'dart:math' as math; 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/theme/colors.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/navigation/app_routes.dart'; 
import '../../../../core/designsystem/components/gym_animated_progress_bar.dart';
import '../../../../core/designsystem/components/gym_shimmer.dart';

import '../../../../core/worker/sync_manager.dart'; 

import '../../data/models/gamification_models.dart'; 
import '../../../auth/data/models/user_models.dart';
import '../../domain/rank_calculator.dart'; 
import '../bloc/gamification_cubit.dart'; 
import '../../../profile/presentation/bloc/profile_cubit.dart';
import '../../../profile/presentation/bloc/stats_cubit.dart';
import '../../../workout/presentation/bloc/workout_cubit.dart';
part '../components/gamification_components.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with SingleTickerProviderStateMixin {
  final bool debugForceLoading = false; // TODO(Debug): Đổi thành false khi build Production
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load leaderboard lần đầu khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GamificationCubit>().loadLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showChestRewardDialog(BuildContext context) {
    showDialog( 
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ChestRewardDialog(
        onClaim: () async {
          await context.read<GamificationCubit>().claimChestReward();
          if (context.mounted) {
            context.read<ProfileCubit>().refreshProfile();
          }
          if (ctx.mounted) {
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await SyncManager.syncNow();
    if (mounted) {
      final workoutHistory = context.read<WorkoutCubit>().state.historicalWorkoutSessionsList;
      context.read<GamificationCubit>().refreshWeeklyQuests(workoutHistory);
      context.read<ProfileCubit>().refreshProfile();
      context.read<GamificationCubit>().loadLeaderboard(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final gamificationState = context.watch<GamificationCubit>().state;
    final userStats = gamificationState.stats;

    final profileState = context.watch<ProfileCubit>().state;
    final userProfile = profileState.userProfile;

    final currentWeeklyStreak = context.watch<StatsCubit>().state.weeklyStreak; 

    // Sử dụng ResponsiveBreakpoints thay vì MediaQuery cứng
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    
    // Tự động giãn chiều cao AppBar nếu màn hình Mobile quá hẹp, đề phòng text bên trong bị rớt dòng
    final toolbarHeight = ResponsiveValue<double>(
      context,
      defaultValue: isTablet ? 90.0 : 110.0,
      conditionalValues: [
        const Condition.smallerThan(name: MOBILE, value: 130.0),
      ],
    ).value;

    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) => previous.userProfile != current.userProfile,
          listener: (context, state) {
            context.read<GamificationCubit>().refreshStateFromPrefs();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: toolbarHeight, 
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          titleSpacing: 0,
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _UserProfileHeader(
                userStats: userStats,
                userProfile: userProfile,
                streak: currentWeeklyStreak, 
                isTablet: isTablet,
                onAvatarClick: () => context.push('/social/${AppRoutes.rank}'), 
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: isTablet 
            ? _buildTabletLayout(colorScheme, userStats, userProfile)
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                    dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: [
                      Tab(text: t.gamification.tab_quests),
                      Tab(text: t.gamification.tab_leaderboard),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: _buildQuestTab(userStats, isTablet: false),
                        ),
                        RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: _buildLeaderboardTab(userProfile, isTablet: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(ColorScheme colorScheme, UserGamificationStats stats, UserProfile profile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(t.gamification.tab_quests, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _buildQuestTab(stats, isTablet: true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(t.gamification.tab_leaderboard, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _buildLeaderboardTab(profile, isTablet: true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestTab(UserGamificationStats stats, {required bool isTablet}) {
    final completedCount = stats.weeklyQuests.where((q) => q.isCompleted).length;

    return ListView(
      shrinkWrap: false, 
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _WeeklyChestBanner(
          completedQuests: completedCount,
          targetQuests: 5,
          isClaimed: stats.isChestClaimed,
          onClaim: () => _showChestRewardDialog(context),
        ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0), 
        
        const SizedBox(height: 24),
        Text(t.gamification.title_weekly_quests, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
          .animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),

        if (stats.weeklyQuests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(child: Text(t.gamification.msg_no_quests, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic)
        else
          ...stats.weeklyQuests.asMap().entries.map((entry) {
            return _QuestItem(
              quest: entry.value, 
              onClaim: (id) async {
                 await context.read<GamificationCubit>().claimQuestReward(id);
                 if (mounted) {
                   context.read<ProfileCubit>().refreshProfile();
                 }
              }
            ).animate(delay: (entry.key * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
          }),
      ],
    );
  }

  Widget _buildLeaderboardTab(UserProfile userProfile, {required bool isTablet}) {
    final state = context.watch<GamificationCubit>().state;
    
    if ((state.isLeaderboardLoading && state.leaderboard == null) || debugForceLoading) {
      return const _GamificationLeaderboardShimmer();
    }

    final serverLeaderboard = state.leaderboard ?? [];
    
    final displayName = userProfile.displayName.isNotEmpty ? userProfile.displayName : t.gamification.leaderboard_you;
    final me = LeaderboardEntry(
      id: "me", 
      name: displayName, 
      xp: userProfile.experiencePoints, 
      isUser: true,
      currentRankId: userProfile.activeRankId,
    );
    
    // Loại bỏ user hiện tại khỏi list nếu bị trùng (trong trường hợp Guest thì không bị trùng, 
    // trong trường hợp User thật, ta thay thế bằng data mới nhất ở local để điểm XP luôn real-time trên máy)
    final otherUsers = serverLeaderboard.where((e) => e.id != userProfile.id);

    final all = [...otherUsers, me]..sort((a, b) => b.xp.compareTo(a.xp));

    return ListView(
      shrinkWrap: false, 
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      children: [
        if (all.length >= 3) ...[
          _PodiumView(top3: all.take(3).toList(), activeRankId: userProfile.activeRankId)
            .animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 32),
          ...all.skip(3).toList().asMap().entries.map((entry) {
            return _RankItem(
              entry: entry.value,
              rankPlacement: entry.key + 4,
              activeRankId: userProfile.activeRankId,
            ).animate(delay: (entry.key * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
          }),
        ] else ...[
          const SizedBox(height: 32),
          ...all.asMap().entries.map((entry) {
            return _RankItem(
              entry: entry.value,
              rankPlacement: entry.key + 1,
              activeRankId: userProfile.activeRankId,
            ).animate(delay: (entry.key * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
          }),
        ]
      ],
    );
  }
}

class _GamificationLeaderboardShimmer extends StatelessWidget {
  const _GamificationLeaderboardShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      children: [
        _buildPodiumShimmer(context),
        const SizedBox(height: 32),
        GymShimmer(
          child: Column(
            children: List.generate(4, (index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GymListTileShimmer(hasAvatar: true),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumShimmer(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;
    final scaleResponsive = ResponsiveValue<double>(
      context,
      defaultValue: 1.0,
      conditionalValues: [const Condition.smallerThan(name: MOBILE, value: 0.8)],
    ).value;

    final order = [
      (rank: 2, height: 100.0 * scaleResponsive, scale: 0.9 * scaleResponsive, colors: [gymColors.podiumSilverStart, gymColors.podiumSilverEnd]),
      (rank: 1, height: 140.0 * scaleResponsive, scale: 1.1 * scaleResponsive, colors: [gymColors.podiumGoldStart, gymColors.podiumGoldEnd]),
      (rank: 3, height: 80.0 * scaleResponsive, scale: 0.85 * scaleResponsive, colors: [gymColors.podiumBronzeStart, gymColors.podiumBronzeEnd]),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 0),
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GymShimmer(child: GymShimmerCircle(radius: 28 * item.scale)),
                const SizedBox(height: 12),
                GymShimmer(child: GymShimmerBlock(width: 50 * item.scale, height: 12, borderRadius: 4)),
                const SizedBox(height: 6),
                GymShimmer(child: GymShimmerBlock(width: 30 * item.scale, height: 10, borderRadius: 4)),
                const SizedBox(height: 10),
                Container(
                  width: 86 * item.scale,
                  height: item.height,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(colors: item.colors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    boxShadow: [BoxShadow(color: item.colors.last.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -4))]
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
