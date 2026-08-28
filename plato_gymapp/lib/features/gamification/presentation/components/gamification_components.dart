part of '../screens/gamification_screen.dart';

// ==========================================
// DIALOG NHẬN RƯƠNG THƯỞNG
// ==========================================
class _ChestRewardDialog extends StatelessWidget {
  final VoidCallback onClaim;
  
  const _ChestRewardDialog({required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;

    final horizontalPadding = ResponsiveValue<double>(
      context, 
      defaultValue: 24.0, 
      conditionalValues: [const Condition.smallerThan(name: MOBILE, value: 16.0)]
    ).value;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Bọc SingleChildScrollView chống double-padding và chống tràn không gian dọc
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: 32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: gymColors.goldRank.withValues(alpha: 0.3),
                blurRadius: 32,
                spreadRadius: 8,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: gymColors.goldRank.withValues(alpha: 0.5), width: 2), 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/gift_box.json',
                width: 250, 
                height: 250,
                repeat: true,
                fit: BoxFit.contain,
              ),
              Text(
                t.gamification.dialog_chest_title_success.toUpperCase(), 
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: ResponsiveValue<double>(context, defaultValue: 24.0, conditionalValues: [const Condition.smallerThan(name: MOBILE, value: 20.0)]).value, 
                  color: gymColors.goldRank,
                  letterSpacing: 1.2,
                ), 
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
              ),
              const SizedBox(height: 12),
              Text(
                t.gamification.dialog_chest_desc_success, 
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15, height: 1.4), 
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: gymColors.goldRank.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gymColors.goldRank.withValues(alpha: 0.5)),
                ),
                // Bọc cụm số vào FittedBox để scale down an toàn
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('1500', style: TextStyle(fontWeight: FontWeight.w900, color: gymColors.goldRank, fontSize: 28)),
                      const SizedBox(width: 8),
                      Icon(Symbols.bolt, color: gymColors.goldRank, size: 32, fill: 1.0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: gymColors.goldRank,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onClaim,
                  child: Text(t.gamification.btn_claim_now, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              )
            ],
          ),
        ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
      ),
    );
  }
}

// ==========================================
// CÁC COMPONENT HEADER & QUESTS
// ==========================================

class _UserProfileHeader extends StatelessWidget {
  final UserGamificationStats userStats;
  final UserProfile userProfile;
  final int streak;
  final bool isTablet;
  final VoidCallback onAvatarClick;

  const _UserProfileHeader({required this.userStats, required this.userProfile, required this.streak, required this.isTablet, required this.onAvatarClick});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressRatio = userStats.nextLevelXp > 0 ? (userStats.currentXp / userStats.nextLevelXp).clamp(0.0, 1.0) : 0.0;
    
    final activeRankId = userProfile.activeRankId > 0 ? userProfile.activeRankId : 1;
    final rankInfo = RankConfig.getRankById(activeRankId);
    final rankColor = Color(rankInfo.colorHex);

    // Dynamic Avatar Size
    final avatarSize = ResponsiveValue<double>(
      context,
      defaultValue: isTablet ? 56.0 : 64.0,
      conditionalValues: [const Condition.smallerThan(name: MOBILE, value: 48.0)],
    ).value;
    
    final displayName = userProfile.displayName.isNotEmpty ? userProfile.displayName : t.gamification.leaderboard_you;

    final List<Color> xpGradient = isDark 
        ? const [xpGradientStartDark, xpGradientEndDark]
        : const [xpGradientStartLight, xpGradientEndLight];

    Widget avatarWidget;
    if (userProfile.avatarBase64 != null && userProfile.avatarBase64!.isNotEmpty) {
      avatarWidget = Image.memory(
        base64Decode(userProfile.avatarBase64!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Text(displayName[0].toUpperCase(), style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: avatarSize * 0.4)),
      );
    } else {
      avatarWidget = Text(displayName[0].toUpperCase(), style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: avatarSize * 0.4));
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 12 : 20),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize, height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), 
                    border: Border.all(color: rankColor, width: 2.5),
                    boxShadow: [BoxShadow(color: rankColor.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)]
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAvatarClick,
                      child: ClipOval(
                        child: SizedBox(
                          width: double.infinity, 
                          height: double.infinity, 
                          child: Center(child: avatarWidget)
                        )
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4, right: -4,
                  child: Container(
                    width: isTablet ? 22 : 28, // [FIX] Nới rộng một chút cho ảnh
                    height: isTablet ? 22 : 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      _getBadgeAssetPath(activeRankId),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(child: Text(displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(t.gamification.fmt_user_level(arg1: userStats.level.toString()), style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Theme.of(context).gymColors.fireHexagon.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Symbols.local_fire_department, color: Theme.of(context).gymColors.fireHexagon, size: 16, fill: 1.0),
                          const SizedBox(width: 4),
                          Text("$streak", style: TextStyle(color: Theme.of(context).gymColors.fireHexagon, fontSize: 13, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 8 : 12),
                SizedBox(
                  height: 18,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 18,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: progressRatio),
                        duration: const Duration(milliseconds: 800), 
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value, 
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                gradient: LinearGradient(
                                  colors: xpGradient,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: xpGradient.last.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              ),
                            ),
                          );
                        }
                      ),
                      Center(
                        child: Text(
                          t.gamification.fmt_xp_progress(arg1: userStats.currentXp.toString(), arg2: userStats.nextLevelXp.toString()),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                              Shadow(color: Colors.black45, blurRadius: 2),
                            ]
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _WeeklyChestBanner extends StatelessWidget {
  final int completedQuests;
  final int targetQuests;
  final bool isClaimed;
  final VoidCallback onClaim;

  const _WeeklyChestBanner({
    required this.completedQuests, 
    required this.targetQuests, 
    required this.isClaimed, 
    required this.onClaim
  });

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;
    final isClaimable = completedQuests >= targetQuests && !isClaimed;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClaimable 
              ? [gymColors.chestBannerStart, gymColors.chestBannerEnd] 
              : [gymColors.chestBannerStart.withValues(alpha: 0.6), gymColors.chestBannerEnd.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isClaimable 
            ? [BoxShadow(color: gymColors.chestBannerEnd.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))] 
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), 
                shape: BoxShape.circle,
                boxShadow: isClaimable 
                    ? [BoxShadow(color: gymColors.goldRank.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)] 
                    : []
              ),
              child: Icon(isClaimable ? Symbols.redeem : Symbols.featured_seasonal_and_gifts, color: isClaimed ? Colors.white54 : gymColors.goldRank, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.gamification.title_weekly_chest, 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                    maxLines: 2,
                    softWrap: true,
                  ),
                  const SizedBox(height: 6),
                  if (isClaimed)
                    Text(t.gamification.msg_chest_claimed, style: TextStyle(color: gymColors.goldRank, fontSize: 14, fontWeight: FontWeight.w600))
                  else if (isClaimable)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: gymColors.goldRank, foregroundColor: Colors.black, minimumSize: const Size(0, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: onClaim,
                      child: Text(t.gamification.btn_open_chest, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                    )
                  else ...[
                    Text(t.gamification.fmt_chest_requirement(arg1: completedQuests.toString(), arg2: targetQuests.toString()), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 16,
                      child: Stack(
                        children: [
                          GymAnimatedProgressBar(
                            progress: (completedQuests / targetQuests).clamp(0.0, 1.0),
                            color: gymColors.goldRank,
                            trackColor: Colors.white30,
                            height: 16,
                          ),
                          Center(
                            child: Text(
                              "$completedQuests/$targetQuests",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          )
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _QuestItem extends StatelessWidget {
  final Quest quest;
  final Function(String) onClaim;

  const _QuestItem({required this.quest, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData iconData = Symbols.star;
    if (quest.iconKey == "workout_count") iconData = Symbols.date_range;
    if (quest.iconKey == "total_volume") iconData = Symbols.exercise;
    if (quest.iconKey == "pr_count") iconData = Symbols.trophy;
    if (quest.iconKey == "duration") iconData = Symbols.timer;
    if (quest.iconKey == "sets") iconData = Symbols.repeat;
    if (quest.iconKey == "exercises") iconData = Symbols.format_list_bulleted;

    final progressRatio = quest.target > 0 ? (quest.current / quest.target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: quest.isCompleted ? Theme.of(context).gymColors.success.withValues(alpha: 0.5) : colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: quest.isCompleted ? Theme.of(context).gymColors.success.withValues(alpha: 0.2) : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(iconData, color: quest.isCompleted ? Theme.of(context).gymColors.success : colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.translateDynamic(quest.title), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface), maxLines: 2, softWrap: true),
                  const SizedBox(height: 4),
                  Text(t.translateDynamic(quest.description), style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant), maxLines: 3, softWrap: true),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 14,
                    child: Stack(
                      children: [
                        GymAnimatedProgressBar(
                          progress: progressRatio,
                          color: quest.isCompleted ? Theme.of(context).gymColors.success : colorScheme.primary,
                          trackColor: colorScheme.onSurface.withValues(alpha: 0.1),
                          height: 14,
                        ),
                        Center(
                          child: Text(
                            "${quest.current}/${quest.target}",
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildClaimSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimSection(BuildContext context) {
    if (quest.claimedReward) {
      return Icon(Symbols.check_circle, color: Theme.of(context).gymColors.success, size: 32, fill: 1.0);
    } else if (quest.isCompleted) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).gymColors.goldRank, foregroundColor: Colors.black, minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: () => onClaim(quest.id),
        child: Text(t.gamification.btn_claim_reward, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
      );
    } else {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("${quest.xpReward}", style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).gymColors.goldRank, fontSize: 15)),
            Icon(Symbols.bolt, color: Theme.of(context).gymColors.goldRank, size: 18, fill: 1.0),
          ],
        ),
      );
    }
  }
}

// ==========================================
// CÁC COMPONENT BỤC VINH QUANG LEADERBOARD
// ==========================================

class _PodiumView extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final int activeRankId;

  const _PodiumView({required this.top3, required this.activeRankId});

  Color _getThemeRankColor(int rankId, GymColors gymColors) {
    if (rankId <= 2) return gymColors.rankBronze;
    if (rankId <= 4) return gymColors.rankSilver;
    if (rankId <= 7) return gymColors.rankGold;
    return gymColors.rankDiamond;
  }

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;
    final order = [top3[1], top3[0], top3[2]];

    final scaleResponsive = ResponsiveValue<double>(
      context,
      defaultValue: 1.0,
      conditionalValues: [const Condition.smallerThan(name: MOBILE, value: 0.8)],
    ).value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 0), 
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;

          int rank = index == 0 ? 2 : (index == 1 ? 1 : 3);
          
          double targetHeight = (index == 0 ? 100.0 : (index == 1 ? 140.0 : 80.0)) * scaleResponsive;
          double scale = (index == 0 ? 0.9 : (index == 1 ? 1.1 : 0.85)) * scaleResponsive;

          List<Color> gradientColors;
          if (rank == 1) {
             gradientColors = [gymColors.podiumGoldStart, gymColors.podiumGoldEnd]; 
          } else if (rank == 2) {
             gradientColors = [gymColors.podiumSilverStart, gymColors.podiumSilverEnd]; 
          } else {
             gradientColors = [gymColors.podiumBronzeStart, gymColors.podiumBronzeEnd]; 
          }

          final int rankId = user.currentRankId > 0 ? user.currentRankId : 1;
              
          final rankColor = _getThemeRankColor(rankId, gymColors);

          return _PodiumColumn(
            user: user, 
            rank: rank, 
            height: targetHeight, 
            scale: scale, 
            gradientColors: gradientColors, 
            rankColor: rankColor,
            rankId: rankId, // Truyền rankId xuống
            animDelay: index * 200,
          );
        }).toList(),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry user;
  final int rank;
  final double height;
  final double scale;
  final List<Color> gradientColors;
  final Color rankColor;
  final int rankId; // [FIX] Nhận rankId
  final int animDelay;

  const _PodiumColumn({required this.user, required this.rank, required this.height, required this.scale, required this.gradientColors, required this.rankColor, required this.rankId, required this.animDelay});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget avatarWidget = Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24 * scale, color: colorScheme.onSurface));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56 * scale, height: 56 * scale,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surfaceContainerHighest, border: Border.all(color: rankColor, width: 3)),
                alignment: Alignment.center,
                child: ClipOval(child: SizedBox(width: double.infinity, height: double.infinity, child: Center(child: avatarWidget))),
              ),
              Positioned(
                bottom: -2, right: -6,
                child: Container(
                  width: 24 * scale, height: 24 * scale, // [FIX] Nới rộng nhẹ để nhét ảnh
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surface),
                  padding: const EdgeInsets.all(2),
                  // [FIX] Đổi Icon sang Image
                  child: Image.asset(
                    _getBadgeAssetPath(rankId),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (rank == 1)
                Positioned(
                  top: -12, right: -10,
                  child: Transform.rotate(
                    angle: 15 * math.pi / 180, 
                    child: Icon(Symbols.trophy, color: Theme.of(context).gymColors.goldRank, size: 30, fill: 1.0),
                  ),
                )
            ],
          ).animate(delay: animDelay.ms).fade(duration: 400.ms).slideY(begin: 0.5, end: 0),
          
          const SizedBox(height: 12),
          SizedBox(
            width: 86 * scale,
            child: Text(
              user.isUser ? t.gamification.fmt_user_name_badge(arg1: user.name) : user.name,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: user.isUser ? colorScheme.primary : colorScheme.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            ),
          ).animate(delay: animDelay.ms).fade(),
          
          const SizedBox(height: 2),
          Text(t.gamification.fmt_xp_value(arg1: user.xp.toString()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).gymColors.goldRank))
            .animate(delay: animDelay.ms).fade(),
            
          const SizedBox(height: 10),
          
          Container(
            width: 86 * scale, height: height,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: gradientColors, 
                begin: Alignment.topCenter, 
                end: Alignment.bottomCenter
              ),
              boxShadow: [BoxShadow(color: gradientColors.last.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -4))]
            ),
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 16), 
              child: Text("$rank", style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontWeight: FontWeight.w900, fontSize: 46 * scale)),
            ),
          ).animate(delay: animDelay.ms).scaleY(begin: 0.0, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack, alignment: Alignment.bottomCenter)
        ],
      ),
    );
  }
}

class _RankItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rankPlacement;
  final int activeRankId;

  const _RankItem({required this.entry, required this.rankPlacement, required this.activeRankId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = entry.isUser 
        ? Color.lerp(colorScheme.surface, colorScheme.primary, 0.2) ?? colorScheme.surface
        : colorScheme.surface;
    
    final borderColor = entry.isUser ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outline.withValues(alpha: 0.3);
    final borderWidth = entry.isUser ? 1.5 : 1.0;

    final int itemRankId = entry.currentRankId > 0 ? entry.currentRankId : 1;
        
    final rankColor = Color(RankConfig.getRankById(itemRankId).colorHex);

    Widget avatarWidget = Text(entry.name.isNotEmpty ? entry.name[0].toUpperCase() : "?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: colorScheme.onSurface));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text("#$rankPlacement", style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurfaceVariant, fontSize: 15)),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surface, border: Border.all(color: rankColor, width: 2)),
                alignment: Alignment.center,
                child: ClipOval(child: SizedBox(width: double.infinity, height: double.infinity, child: Center(child: avatarWidget))),
              ),
              Positioned(
                bottom: -2, right: -2,
                child: Container(
                  width: 20, height: 20, // [FIX] Nới rộng một chút
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surface),
                  padding: const EdgeInsets.all(2),
                  // [FIX] Sử dụng ảnh Badge thay vì Icon
                  child: Image.asset(
                    _getBadgeAssetPath(itemRankId),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              entry.isUser ? t.gamification.fmt_user_name_badge(arg1: entry.name) : entry.name,
              style: TextStyle(fontWeight: entry.isUser ? FontWeight.w900 : FontWeight.w600, fontSize: 15, color: entry.isUser ? colorScheme.primary : colorScheme.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          // Bọc FittedBox để bảo vệ khi user có XP quá lớn
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              t.gamification.fmt_xp_value(arg1: entry.xp.toString()),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Theme.of(context).gymColors.goldRank),
            ),
          )
        ],
      ),
    );
  }
}

String _getBadgeAssetPath(int rankId) {
  switch (rankId) {
    case 1: return 'assets/badges/bronze1.webp';
    case 2: return 'assets/badges/bronze2.webp';
    case 3: return 'assets/badges/silver1.webp';
    case 4: return 'assets/badges/silver2.webp';
    case 5: return 'assets/badges/gold1.webp';
    case 6: return 'assets/badges/gold2.webp';
    case 7: return 'assets/badges/gold3.webp';
    case 8: return 'assets/badges/diamond.webp';
    default: return 'assets/badges/bronze1.webp';
  }
}