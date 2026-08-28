import 'package:flutter/foundation.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_countdown_text.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/workout/domain/workout_extensions.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/worker/sync_manager.dart';

import '../../../auth/data/models/user_models.dart';
import '../../../workout/data/models/workout_models.dart';
import '../../../gamification/domain/rank_calculator.dart';
import '../../domain/profile_chart_utils.dart';

import '../bloc/profile_cubit.dart';
import '../bloc/stats_cubit.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _handleRefresh() async {
    await SyncManager.syncNow();
    if (mounted) {
      context.read<ProfileCubit>().refreshProfile();
    }
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 80,
          maxWidth: 512,
          maxHeight: 512,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: t.profile.title_crop_avatar,
              toolbarColor: colorScheme.surface,
              toolbarWidgetColor: colorScheme.primary,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: t.profile.title_crop_image,
              aspectRatioLockEnabled: true,
              resetButtonHidden: true,
            ),
          ],
        );

        if (croppedFile != null) {
          final Uint8List imageBytes = await croppedFile.readAsBytes();
          final String base64String = base64Encode(imageBytes);

          if (context.mounted) {
            context.read<ProfileCubit>().updateAvatar(base64String);
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi chọn/cắt ảnh: $e");
    }
  }

  void _showAvatarOptions(BuildContext context, bool hasAvatar) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Symbols.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    t.profile.lbl_pick_from_gallery,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadAvatar(context);
                  },
                ),
                if (hasAvatar)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Symbols.delete,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    title: Text(
                      t.profile.lbl_delete_current_avatar,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<ProfileCubit>().updateAvatar(null);
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final profileState = context.watch<ProfileCubit>().state;
    final profile = profileState.userProfile;

    final statsState = context.watch<StatsCubit>().state;
    final isStatsLoading = statsState.isLoading; // Lấy flag loading

    final rawHistory = statsState.workouts;
    final history = List<WorkoutSession>.from(rawHistory)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final bool hasAvatar =
        profile.avatarBase64 != null && profile.avatarBase64!.isNotEmpty;

    Widget avatarImageWidget;
    if (hasAvatar) {
      avatarImageWidget = Image.memory(
        base64Decode(profile.avatarBase64!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Symbols.person, size: 56, color: colorScheme.onSurfaceVariant),
      );
    } else {
      avatarImageWidget = Icon(
        Symbols.person,
        size: 56,
        color: colorScheme.onSurfaceVariant,
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: 16,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/logo/logo_themedark.png'
                : 'assets/logo/logo_themelight.png',
            key: ValueKey(Theme.of(context).brightness),
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            tooltip: t.common.open_settings,
            icon: Icon(Symbols.settings, color: colorScheme.onSurface),
            onPressed: () => context.push('/profile/${AppRoutes.settings}'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Builder(
              builder: (context) {
                final isTablet = ResponsiveBreakpoints.of(
                  context,
                ).largerOrEqualTo(TABLET);

                if (isTablet) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: RefreshIndicator(
                            onRefresh: _handleRefresh,
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.surface,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              children: [
                                _buildIdentityAndHexagonRow(
                                  context,
                                  profile,
                                  hasAvatar,
                                  avatarImageWidget,
                                  history,
                                  isTablet: isTablet,
                                ),
                                const SizedBox(height: 24),
                                _buildRankProgressCard(
                                  context,
                                  profile,
                                  history,
                                  isStatsLoading,
                                ),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 6,
                          child: RefreshIndicator(
                            onRefresh: _handleRefresh,
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.surface,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              children: [
                                _buildMenuGrid(context),
                                const SizedBox(height: 32),
                                _buildHistoryHeader(context, history),
                                const SizedBox(height: 16),
                                _buildHistoryList(context, history),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          _buildIdentityAndHexagonRow(
                            context,
                            profile,
                            hasAvatar,
                            avatarImageWidget,
                            history,
                            isTablet: isTablet,
                          ),
                          const SizedBox(height: 24),
                          _buildRankProgressCard(
                            context,
                            profile,
                            history,
                            isStatsLoading,
                          ),
                          const SizedBox(height: 24),
                          _buildMenuGrid(context),
                          const SizedBox(height: 32),
                          _buildHistoryHeader(context, history),
                          const SizedBox(height: 16),
                          _buildHistoryList(context, history),
                          const SizedBox(height: 48),
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
    );
  }

  Widget _buildIdentityAndHexagonRow(
    BuildContext context,
    UserProfile profile,
    bool hasAvatar,
    Widget avatarImageWidget,
    List<WorkoutSession> history, {
    required bool isTablet,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final double avatarSize = ResponsiveValue<double>(
      context,
      defaultValue: 130,
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 100)],
    ).value;

    Widget avatarSection = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showAvatarOptions(context, hasAvatar),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipOval(child: avatarImageWidget),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 3),
                  ),
                  child: Icon(
                    Symbols.photo_camera,
                    size: 16,
                    color: colorScheme.onPrimary,
                    fill: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.displayName,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          maxLines: 2,
          softWrap: true,
          textAlign: TextAlign.center,
        ),
      ],
    );

    Widget hexagonSection = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => context.push(
          '/profile/${AppRoutes.stats}',
          extra: StatsScreenType.HEXAGON_DETAIL,
        ),
        child: SizedBox(
          height: 180,
          child: Center(child: _MiniHexagonChart(workouts: history)),
        ),
      ),
    );

    if (isTablet) {
      return Column(
            children: [
              avatarSection,
              const SizedBox(height: 32),
              hexagonSection,
            ],
          )
          .animate()
          .fade(duration: 400.ms, curve: Curves.easeOutCubic)
          .slideY(begin: 0.1, end: 0);
    }

    return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 1, child: avatarSection),
            Expanded(flex: 1, child: hexagonSection),
          ],
        )
        .animate()
        .fade(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildRankProgressCard(
    BuildContext context,
    UserProfile profile,
    List<WorkoutSession> history,
    bool isLoading,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // 🚀 UX FIX: Hiển thị Skeleton nếu data chưa sẵn sàng để tránh giật số
    if (isLoading) {
      return Container(
            height: 124, // Chiều cao xấp xỉ của card thật
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.1),
              ),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1200.ms,
            color: colorScheme.surface.withValues(alpha: 0.5),
          )
          .fade(duration: 400.ms);
    }

    final rankInfo = RankConfig.getRankById(profile.activeRankId);
    final isMaxRank = profile.activeRankId == RankConfig.hierarchy.last.id;

    final int nowMillis = DateTime.now().millisecondsSinceEpoch;
    final seasonResult = RankCalculator.calculateTrueRankAndSeasons(
      history,
      profile,
      nowMillis,
    );
    final int seasonEndMillis = seasonResult.cycleEndTimeMillis;

    return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/social/${AppRoutes.rank}'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RankBadge(rankId: profile.activeRankId),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t.rank.fmt_rp(
                                  arg1: profile.currentRp.toString(),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // [UI/UX FIX]: Sử dụng GymCountdownText dùng chung
                              GymCountdownText(
                                key: ValueKey(seasonEndMillis),
                                targetMillis: seasonEndMillis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                highlightColor: colorScheme.onSurfaceVariant,
                                builder: (context, duration) {
                                  final int diffMillis =
                                      duration.inMilliseconds;

                                  if (diffMillis <= 0) {
                                    return Text(
                                      t.rank.msg_season_ended,
                                      style:
                                          const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ).copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    );
                                  }

                                  const int oneDayMillis = 24 * 60 * 60 * 1000;
                                  if (diffMillis >= oneDayMillis) {
                                    final daysLeft = (diffMillis / oneDayMillis)
                                        .ceil();
                                    return Text(
                                      t.nutrition.fmt_goal_days_left(
                                        days: daysLeft.toString(),
                                      ),
                                      style:
                                          const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ).copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    );
                                  }

                                  final hours = duration.inHours;
                                  final minutes = duration.inMinutes.remainder(
                                    60,
                                  );
                                  final seconds = duration.inSeconds.remainder(
                                    60,
                                  );

                                  String timeText;
                                  if (hours > 0) {
                                    timeText = t.common.time_h_m_s(
                                      h: hours.toString(),
                                      m: minutes.toString(),
                                      s: seconds.toString(),
                                    );
                                  } else if (minutes > 0) {
                                    timeText = t.common.time_m_s(
                                      m: minutes.toString(),
                                      s: seconds.toString(),
                                    );
                                  } else {
                                    timeText = t.common.time_s(
                                      s: seconds.toString(),
                                    );
                                  }

                                  return Text(
                                    timeText,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ).copyWith(color: colorScheme.error),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _BMIStyleZoneBar(
                      currentRank: rankInfo,
                      points: profile.currentRp,
                      isMaxRank: isMaxRank,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: 50.ms)
        .fade(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildMenuGrid(BuildContext context) {
    return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MenuButton(
                    icon: Symbols.bar_chart_4_bars,
                    title: t.profile.btn_menu_stats,
                    onTap: () => context.push('/profile/${AppRoutes.stats}'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MenuButton(
                    icon: Symbols.list_alt,
                    title: t.profile.btn_menu_exercises,
                    onTap: () => context.pushNamed('exercise_library'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MenuButton(
                    icon: Symbols.person_edit,
                    title: t.profile.btn_menu_edit,
                    onTap: () =>
                        context.push('/profile/${AppRoutes.profileSettings}'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MenuButton(
                    icon: Symbols.calendar_month,
                    title: t.profile.btn_menu_cal,
                    onTap: () => context.push('/profile/${AppRoutes.calendar}'),
                  ),
                ),
              ],
            ),
          ],
        )
        .animate(delay: 200.ms)
        .fade(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildHistoryHeader(
    BuildContext context,
    List<WorkoutSession> history,
  ) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                t.profile.title_recent_history,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
                softWrap: true,
              ),
            ),
            if (history.length > 7)
              Flexible(
                child: TextButton(
                  onPressed: () =>
                      context.push('/profile/${AppRoutes.calendar}'),
                  child: Text(
                    t.profile.btn_history_see_all(
                      arg1: history.length.toString(),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
          ],
        )
        .animate(delay: 300.ms)
        .fade(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildHistoryList(BuildContext context, List<WorkoutSession> history) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            t.profile.msg_history_empty,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ),
      ).animate(delay: 400.ms).fade(duration: 400.ms);
    }

    final itemCount = history.length > 7 ? 7 : history.length;

    return Column(
      children: history.take(itemCount).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final session = entry.value;
        return _HistoryCard(
              session: session,
              onTap: () =>
                  context.push('/workout/workout_detail/${session.id}'),
              onDelete: () async {
                final confirm = await GymDialog.showDestructive(
                  context: context,
                  title: t.common.title_delete_dialog_main,
                  message: t.common.msg_delete_dialog_warn,
                  cancelText: t.common.cancel,
                );

                if (confirm == true && context.mounted) {
                  try {
                    context.read<StatsCubit>().deleteWorkout(session.id);

                    if (!context.mounted) return;

                    GymSnackbar.show(
                      context,
                      message: t.gamification.msg_workout_deleted,
                      icon: Symbols.check_circle,
                      accentColor: Theme.of(context).colorScheme.primary,
                      duration: const Duration(seconds: 2),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    GymSnackbar.show(
                      context,
                      message: 'Có lỗi xảy ra, vui lòng thử lại!',
                      icon: Symbols.error,
                      accentColor: Theme.of(context).colorScheme.error,
                    );
                  }
                }
              },
            )
            .animate(delay: (400 + index * 100).ms)
            .fade(duration: 400.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}

class _BMIStyleZoneBar extends StatelessWidget {
  final RankLevel currentRank;
  final int points;
  final bool isMaxRank;

  const _BMIStyleZoneBar({
    required this.currentRank,
    required this.points,
    required this.isMaxRank,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorMaintain = Theme.of(context).gymColors.goldRank;
    final colorPromote = Theme.of(context).gymColors.success;

    final double maxRenderRP = isMaxRank
        ? (currentRank.maintainPoints * 1.5)
        : (currentRank.promotePoints * 1.2);
    final double maintainRatio = maxRenderRP > 0
        ? (currentRank.maintainPoints / maxRenderRP).clamp(0.0, 1.0)
        : 0.0;
    final double promoteRatio = maxRenderRP > 0
        ? (currentRank.promotePoints / maxRenderRP).clamp(0.0, 1.0)
        : 0.0;
    final double targetRatio = maxRenderRP > 0
        ? (points / maxRenderRP).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        return Column(
          children: [
            Animate(key: ValueKey(points)).custom(
              duration: 1500.ms,
              curve: Curves.easeOutCubic,
              end: targetRatio,
              builder: (context, value, child) {
                return CustomPaint(
                  size: Size(
                    width.isInfinite ? 350 : width,
                    24,
                  ), // Fix infinite width crash during transitions
                  painter: _ZoneBarPainter(
                    currentRatio: value,
                    maintainRatio: maintainRatio,
                    promoteRatio: promoteRatio,
                    isRank1: currentRank.id == 1,
                    isMaxRank: isMaxRank,
                    colorDemotion: colorScheme.error,
                    colorMaintain: colorMaintain,
                    colorPromote: colorPromote,
                    colorIndicator: colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: Stack(
                children: [
                  if (currentRank.id > 1)
                    Positioned(
                      left: (width * maintainRatio) - 24,
                      child: Text(
                        "${currentRank.maintainPoints} RP",
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  if (!isMaxRank)
                    Positioned(
                      left: (width * promoteRatio) - 24,
                      child: Text(
                        "${currentRank.promotePoints} RP",
                        style: TextStyle(
                          color: colorPromote,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ZoneBarPainter extends CustomPainter {
  final double currentRatio;
  final double maintainRatio;
  final double promoteRatio;
  final bool isRank1;
  final bool isMaxRank;
  final Color colorDemotion;
  final Color colorMaintain;
  final Color colorPromote;
  final Color colorIndicator;

  _ZoneBarPainter({
    required this.currentRatio,
    required this.maintainRatio,
    required this.promoteRatio,
    required this.isRank1,
    required this.isMaxRank,
    required this.colorDemotion,
    required this.colorMaintain,
    required this.colorPromote,
    required this.colorIndicator,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;

    const double h = 12.0;
    final double y = size.height / 2;
    final double top = y - h / 2;
    final double bottom = y + h / 2;
    const Radius radius = Radius.circular(h / 2);

    final double xMaintain = size.width * maintainRatio;
    final double xPromote = size.width * promoteRatio;
    final double xCurrent = size.width * currentRatio;

    if (isRank1) {
      paint.color = colorMaintain;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          0,
          top,
          xPromote,
          bottom,
          topLeft: radius,
          bottomLeft: radius,
        ),
        paint,
      );
      paint.color = colorPromote;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          xPromote,
          top,
          size.width,
          bottom,
          topRight: radius,
          bottomRight: radius,
        ),
        paint,
      );
      canvas.drawLine(
        Offset(xPromote, top),
        Offset(xPromote, bottom),
        linePaint,
      );
    } else if (isMaxRank) {
      paint.color = colorDemotion;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          0,
          top,
          xMaintain,
          bottom,
          topLeft: radius,
          bottomLeft: radius,
        ),
        paint,
      );
      paint.color = colorMaintain;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          xMaintain,
          top,
          size.width,
          bottom,
          topRight: radius,
          bottomRight: radius,
        ),
        paint,
      );
      canvas.drawLine(
        Offset(xMaintain, top),
        Offset(xMaintain, bottom),
        linePaint,
      );
    } else {
      paint.color = colorDemotion;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          0,
          top,
          xMaintain,
          bottom,
          topLeft: radius,
          bottomLeft: radius,
        ),
        paint,
      );
      paint.color = colorMaintain;
      canvas.drawRect(Rect.fromLTRB(xMaintain, top, xPromote, bottom), paint);
      paint.color = colorPromote;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          xPromote,
          top,
          size.width,
          bottom,
          topRight: radius,
          bottomRight: radius,
        ),
        paint,
      );
      canvas.drawLine(
        Offset(xMaintain, top),
        Offset(xMaintain, bottom),
        linePaint,
      );
      canvas.drawLine(
        Offset(xPromote, top),
        Offset(xPromote, bottom),
        linePaint,
      );
    }

    paint.color = colorIndicator;
    canvas.drawCircle(Offset(xCurrent, y), 10, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(xCurrent, y), 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MiniHexagonChart extends StatefulWidget {
  final List<WorkoutSession> workouts;
  const _MiniHexagonChart({required this.workouts});

  @override
  State<_MiniHexagonChart> createState() => _MiniHexagonChartState();
}

class _MiniHexagonChartState extends State<_MiniHexagonChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _growthAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _growthAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final t30 = now - (30 * 24 * 60 * 60 * 1000);
    final currentMonth = widget.workouts
        .where((w) => w.startTime >= t30)
        .toList();

    // REFACTOR: Sử dụng mốc Dynamic Scaling
    final rawCurrent = ProfileChartUtils.calculateRawMuscleScores(currentMonth);
    final normCurrent = rawCurrent.map((k, v) {
      final dynamicLimit = ProfileChartUtils.getHexagonMaxVolume(k);
      return MapEntry(k, (v / dynamicLimit).clamp(0.0, 1.0));
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: _growthAnim,
            builder: (context, _) => CustomPaint(
              painter: _MiniHexagonPainter(
                currentStats: normCurrent,
                progress: _growthAnim.value,
                colorScheme: Theme.of(context).colorScheme,
                gymColors: Theme.of(context).gymColors,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniHexagonPainter extends CustomPainter {
  final Map<String, double> currentStats;
  final double progress;
  final ColorScheme colorScheme;
  final GymColors gymColors;

  _MiniHexagonPainter({
    required this.currentStats,
    required this.progress,
    required this.colorScheme,
    required this.gymColors,
  });

  String _getRank(double value) {
    // REFACTOR: Chia đều 6 khoảng (100% / 6) để Data khớp với Grid Lines của biểu đồ
    if (value >= 5 / 6) return 'S'; // >= 83.33%
    if (value >= 4 / 6) return 'A'; // >= 66.66%
    if (value >= 3 / 6) return 'B'; // >= 50.00%
    if (value >= 2 / 6) return 'C'; // >= 33.33%
    if (value >= 1 / 6) return 'D'; // >= 16.66%
    return 'E'; // < 16.66%
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'S':
        return gymColors.goldRank;
      case 'A':
        return colorScheme.primary;
      case 'B':
        return gymColors.success;
      case 'C':
        return gymColors.warning;
      case 'D':
        return colorScheme.error;
      case 'E':
        return colorScheme.onSurface.withValues(alpha: 0.5);
      default:
        return colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  void _paintElegantLabel(
    Canvas canvas,
    Offset center,
    String muscleName,
    String rank,
    Color rankColor,
  ) {
    final nameSpan = TextSpan(
      text: muscleName.toUpperCase(),
      style: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.8),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
    final namePainter = TextPainter(
      text: nameSpan,
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    namePainter.layout();

    final isHighRank = rank == 'S' || rank == 'A' || rank == 'B';
    final rankSpan = TextSpan(
      text: rank,
      style: TextStyle(
        color: rankColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        shadows: isHighRank
            ? [
                Shadow(color: rankColor.withValues(alpha: 0.6), blurRadius: 6),
                Shadow(color: rankColor.withValues(alpha: 0.3), blurRadius: 12),
              ]
            : [],
      ),
    );
    final rankPainter = TextPainter(
      text: rankSpan,
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    rankPainter.layout();

    final spacing = 0.0;
    final totalHeight = namePainter.height + spacing + rankPainter.height;
    final startY = center.dy - totalHeight / 2;

    namePainter.paint(
      canvas,
      Offset(center.dx - namePainter.width / 2, startY),
    );
    rankPainter.paint(
      canvas,
      Offset(
        center.dx - rankPainter.width / 2,
        startY + namePainter.height + spacing,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final maxRadius = math.min(size.width, size.height) / 2 * 0.55;
    final stepAngle = 2 * math.pi / 6;

    final paintGrid = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final paintAxis = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final a1 = i * stepAngle - math.pi / 2;
      final a2 = (i + 3) * stepAngle - math.pi / 2;
      canvas.drawLine(
        Offset(cx + maxRadius * math.cos(a1), cy + maxRadius * math.sin(a1)),
        Offset(cx + maxRadius * math.cos(a2), cy + maxRadius * math.sin(a2)),
        paintAxis,
      );
    }

    for (int l = 1; l <= 3; l++) {
      final r = maxRadius * (l / 3);
      final p = Path();
      for (int v = 0; v < 6; v++) {
        final a = v * stepAngle - math.pi / 2;
        final x = cx + r * math.cos(a);
        final y = cy + r * math.sin(a);
        if (v == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      canvas.drawPath(p, paintGrid);
    }

    final labels = [
      MapEntry("Chest", t.muscles.chest),
      MapEntry("Abs", t.muscles.core),
      MapEntry("Back", t.muscles.back),
      MapEntry("Legs", t.muscles.legs),
      MapEntry("Arms", t.muscles.arms),
      MapEntry("Shoulders", t.muscles.shoulders),
    ];

    final p = Path();
    for (int v = 0; v < 6; v++) {
      final val = (currentStats[labels[v].key] ?? 0.0) * progress;
      final a = v * stepAngle - math.pi / 2;
      final x = cx + maxRadius * val * math.cos(a);
      final y = cy + maxRadius * val * math.sin(a);
      if (v == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();

    final activeColor = gymColors.fireHexagon;
    canvas.drawPath(
      p,
      Paint()
        ..color = activeColor.withValues(alpha: 0.35 * progress)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      p,
      Paint()
        ..color = activeColor.withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    if (progress > 0.9) {
      for (int v = 0; v < 6; v++) {
        final a = v * stepAngle - math.pi / 2;
        final r = maxRadius * 1.4;
        final x = cx + r * math.cos(a);
        final y = cy + r * math.sin(a);

        final finalVal = currentStats[labels[v].key] ?? 0.0;
        final rank = _getRank(finalVal);
        final rankColor = _getRankColor(rank);

        _paintElegantLabel(
          canvas,
          Offset(x, y),
          labels[v].value,
          rank,
          rankColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniHexagonPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class RankBadge extends StatelessWidget {
  final int rankId;
  const RankBadge({super.key, required this.rankId});

  String _getBadgeAssetPath(int rankId) {
    switch (rankId) {
      case 1:
        return 'assets/badges/bronze1.webp';
      case 2:
        return 'assets/badges/bronze2.webp';
      case 3:
        return 'assets/badges/silver1.webp';
      case 4:
        return 'assets/badges/silver2.webp';
      case 5:
        return 'assets/badges/gold1.webp';
      case 6:
        return 'assets/badges/gold2.webp';
      case 7:
        return 'assets/badges/gold3.webp';
      case 8:
        return 'assets/badges/diamond.webp';
      default:
        return 'assets/badges/bronze1.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;

    String rankNameKey = 'rank.name_bronze_1';
    Color rankColor = gymColors.rankBronze;

    if (rankId == 1 || rankId == 2) {
      rankNameKey = 'rank.name_bronze_$rankId';
      rankColor = gymColors.rankBronze;
    } else if (rankId == 3 || rankId == 4) {
      rankNameKey = 'rank.name_silver_${rankId - 2}';
      rankColor = gymColors.rankSilver;
    } else if (rankId >= 5 && rankId <= 7) {
      rankNameKey = 'rank.name_gold_${rankId - 4}';
      rankColor = gymColors.rankGold;
    } else if (rankId >= 8) {
      rankNameKey = 'rank.name_diamond_1';
      rankColor = gymColors.rankDiamond;
    }

    return Container(
      // [FIX] Tinh chỉnh lại padding cho cân đối với ảnh
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.1), // Nền mờ nhẹ hơn để tôn ảnh
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: rankColor.withValues(alpha: 0.5),
          width: 1.5,
        ), // Viền thanh thoát hơn
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // [FIX] Thay thế Icon bằng Image.asset
          Image.asset(
            _getBadgeAssetPath(rankId),
            width: 24, // Size nhỏ nhắn gọn gàng
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              t.translateDynamic(rankNameKey).toString(),
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
              softWrap: true,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: colorScheme.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return t.common.time_h_m(h: h.toString(), m: m.toString());
    return t.common.time_m(m: m.toString());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat(
      "dd MMM, HH:mm",
      TranslationProvider.of(context).flutterLocale.languageCode,
    ).format(DateTime.fromMillisecondsSinceEpoch(session.startTime));

    IconData statIcon = Symbols.exercise;
    String statValue = t.onboarding.fmt_kg(
      arg1: session.totalVolume.toInt().toString(),
    );
    if (session.totalVolume <= 0 && session.totalSets > 0) {
      statIcon = Symbols.repeat;
      statValue = '${session.totalSets} Sets';
    }

    final allHistory = context.watch<StatsCubit>().state.workouts;
    final int realPrCount = session.calculateTotalPRs(allHistory);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.translateDynamic(session.name).toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                            maxLines: 3,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.profile.fmt_history_sum(
                              arg1: session.exercises.length.toString(),
                              arg2: dateStr,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.close, size: 24),
                      onPressed: onDelete,
                      color: colorScheme.error,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.schedule,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(session.totalDurationSeconds),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Icon(
                        statIcon,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statValue,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),

                      if (realPrCount > 0) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Symbols.trophy,
                          size: 18,
                          color: Theme.of(context).gymColors.goldRank,
                          fill: 1.0,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          realPrCount.toString(),
                          style: TextStyle(
                            color: Theme.of(context).gymColors.goldRank,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    height: 1,
                  ),
                ),

                Column(
                  children: session.exercises.take(3).map((ex) {
                    final completedSets = ex.sets
                        .where((s) => s.isCompleted)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              t
                                      .translateDynamic(ex.exercise.name)
                                      .toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.9,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            t.profile.fmt_history_sets(
                              arg1: completedSets.toString(),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                if (session.exercises.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      t.profile.fmt_history_more_exercises(
                        arg1: (session.exercises.length - 3).toString(),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
