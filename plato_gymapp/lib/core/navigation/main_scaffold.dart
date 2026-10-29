import 'dart:convert';

import '../../features/notifications/application/notification_coordinator.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/core/utils/measurement_units.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plato_gymapp/core/worker/background_workout_service.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/active_session_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../features/nutrition/presentation/components/nutrition_components.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

final ValueNotifier<bool> globalBottomBarVisibility = ValueNotifier<bool>(true);
final ValueNotifier<double> globalBottomBarAnimationProgress =
    ValueNotifier<double>(0.0);
final ValueNotifier<int> globalActiveTabIndex = ValueNotifier<int>(0);
final ValueNotifier<bool> globalIsTabSwiping = ValueNotifier<bool>(false);

const double mainBottomBarHeight = 60.0;
const double mainBottomBarSafeAreaGap = 8.0;
const double mainBottomBarNoSafeAreaGap = 16.0;

double mainBottomBarVisibleTop(double bottomSafeArea) =>
    mainBottomBarHeight +
    (bottomSafeArea > 0
        ? bottomSafeArea + mainBottomBarSafeAreaGap
        : mainBottomBarNoSafeAreaGap);

/// Starts a tab's entrance only after the horizontal transition has settled.
/// The [child] is kept outside both builders so tab changes do not rebuild the
/// screen tree or restart child-owned animations.
class MainTabMotionScope extends StatelessWidget {
  final int tabIndex;
  final bool enabled;
  final Object? playOnceKey;
  final Widget child;

  const MainTabMotionScope({
    super.key,
    required this.tabIndex,
    this.enabled = true,
    this.playOnceKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: globalActiveTabIndex,
      child: child,
      builder: (context, activeTab, child) => ValueListenableBuilder<bool>(
        valueListenable: globalIsTabSwiping,
        child: child,
        builder: (context, isSwiping, child) => GymMotionScope(
          active: enabled && activeTab == tabIndex && !isSwiping,
          playOnceKey: playOnceKey,
          child: child!,
        ),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const MainScaffold({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  bool _dismissedWeeklyReminder = false;
  bool _dismissedGoalReview = false;

  NutritionGoal? _lastGoal;
  double? _lastTargetWeight;

  late final TabController _tabController;
  late int _currentBottomBarIndex;

  late final AnimationController _barAnimController;

  StreamSubscription? _notificationTapSub;
  late final ActiveSessionCubit _activeSessionCubit;

  @override
  void initState() {
    super.initState();
    _currentBottomBarIndex = widget.navigationShell.currentIndex;
    globalActiveTabIndex.value = _currentBottomBarIndex;
    _tabController = TabController(
      length: widget.children.length,
      initialIndex: _currentBottomBarIndex,
      vsync: this,
    );

    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    globalBottomBarVisibility.addListener(_onGlobalVisibilityChange);

    _barAnimController.addListener(() {
      globalBottomBarAnimationProgress.value = _barAnimController.value;
    });

    _tabController.animation?.addListener(() {
      final animationValue = _tabController.animation!.value;
      final settledIndex = animationValue.round();
      final isSwiping = (animationValue - settledIndex).abs() > 0.01;

      if (globalIsTabSwiping.value != isSwiping) {
        globalIsTabSwiping.value = isSwiping;
      }
      if (isSwiping || settledIndex == _currentBottomBarIndex) return;

      setState(() => _currentBottomBarIndex = settledIndex);
      globalActiveTabIndex.value = settledIndex;
      if (widget.navigationShell.currentIndex != settledIndex) {
        widget.navigationShell.goBranch(settledIndex);
      }
    });

    final initialProfile = context.read<ProfileCubit>().state.userProfile;
    _lastGoal = initialProfile.nutritionGoal;
    _lastTargetWeight = initialProfile.targetGoalWeightKg;

    _notificationTapSub = BackgroundWorkoutService.notificationTapStream.stream
        .listen((response) {
          _handleNotificationPayload(
            response.payload,
            actionId: response.actionId,
          );
        });

    if (BackgroundWorkoutService.pendingPayload != null) {
      _handleNotificationPayload(
        BackgroundWorkoutService.pendingPayload,
        actionId: BackgroundWorkoutService.pendingActionId,
      );
    }

    _activeSessionCubit = context.read<ActiveSessionCubit>();
    _activeSessionCubit.autoFinishedSessionNotifier.addListener(
      _onSessionAutoFinished,
    );

    _checkInitialAppLaunchFromNotification();
  }

  void _onSessionAutoFinished() {
    final session = _activeSessionCubit.autoFinishedSessionNotifier.value;
    if (session != null) {
      _activeSessionCubit.autoFinishedSessionNotifier.value = null;
      _showAutoFinishResultDialog(session);
    }
  }

  void _showAutoFinishResultDialog(WorkoutSession session) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    GymDialog.showCustom(
      context: context,
      titleWidget: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: Theme.of(context).gymColors.accentTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.workout.title_auto_finish_success,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.workout.msg_auto_finish_success,
            style: TextStyle(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildResultRow(
                  t.workout.col_workout_name,
                  session.name,
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _buildResultRow(
                  t.stats.lbl_metric_volume,
                  MeasurementFormatter(
                    context
                        .read<ProfileCubit>()
                        .state
                        .userProfile
                        .measurementPreferences,
                  ).formatWeight(session.totalVolume),
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _buildResultRow(
                  t.gamification.lbl_xp_earned,
                  '+${session.xpEarned} XP',
                  colorScheme,
                  valueColor: Theme.of(context).gymColors.goldRank,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t.common.confirm,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _handleNotificationPayload(String? payload, {String? actionId}) {
    if (payload != null && payload.startsWith('{')) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final service = NotificationCoordinator.instance;
        if (service == null ||
            data['scope'] != service.scope ||
            (data['v'] != 1 && data['v'] != 2))
          return;
        final route = data['route'] as String?;
        if (route == null ||
            ![
              '/profile/calendar',
              '/nutrition?water=1',
              '/workout',
              '/workout?recovery=1',
              '/social/rank_screen',
            ].contains(route))
          return;
        final notificationKey = data['key'] as String?;
        if (notificationKey != null) {
          unawaited(
            service.recordExternalInteraction(
              notificationKey,
              actionId: actionId,
            ),
          );
        }
        BackgroundWorkoutService.pendingPayload = null;
        BackgroundWorkoutService.pendingActionId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || data['scope'] != service.scope) return;
          final id = data['sourceId'] as String?;
          context.go(
            route == '/profile/calendar' && id != null
                ? '$route?schedule=${Uri.encodeComponent(id)}'
                : route,
          );
        });
      } catch (_) {
        /* Ignore malformed or obsolete payloads. */
      }
      return;
    }
    if (payload == 'route_log_workout') {
      BackgroundWorkoutService.pendingPayload = null;
      BackgroundWorkoutService.pendingActionId = null;

      if (!mounted) return;

      AppRouter.expandWorkoutScreenNotifier.value = true;
    }
  }

  Future<void> _checkInitialAppLaunchFromNotification() async {
    final flnp = FlutterLocalNotificationsPlugin();
    final details = await flnp.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      _handleNotificationPayload(
        details.notificationResponse?.payload,
        actionId: details.notificationResponse?.actionId,
      );
    }
  }

  void _onGlobalVisibilityChange() {
    if (globalBottomBarVisibility.value && _barAnimController.value > 0.0) {
      _barAnimController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else if (!globalBottomBarVisibility.value &&
        _barAnimController.value < 1.0) {
      _barAnimController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void didUpdateWidget(covariant MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _currentBottomBarIndex) {
      setState(() {
        _currentBottomBarIndex = widget.navigationShell.currentIndex;
      });
      globalActiveTabIndex.value = _currentBottomBarIndex;
      if (_tabController.index != _currentBottomBarIndex) {
        _tabController.animateTo(_currentBottomBarIndex);
      }
    }
  }

  @override
  void dispose() {
    _activeSessionCubit.autoFinishedSessionNotifier.removeListener(
      _onSessionAutoFinished,
    );
    _notificationTapSub?.cancel();
    globalBottomBarVisibility.removeListener(_onGlobalVisibilityChange);
    _barAnimController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTapBottomBar(int index) {
    if (AppRouter.isTourActive.value) return;

    _tabController.animateTo(index);
    if (!globalBottomBarVisibility.value) {
      globalBottomBarVisibility.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    final colorScheme = Theme.of(context).colorScheme;

    final avatarUrl = context.select<ProfileCubit, String?>(
      (c) => c.state.userProfile.avatarUrl,
    );

    Widget? profileAvatarWidget;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      final cacheSize = (32 * MediaQuery.devicePixelRatioOf(context)).round();
      profileAvatarWidget = Image.network(
        avatarUrl,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Symbols.person,
          color: colorScheme.onPrimaryContainer,
          size: 20,
        ),
      );
    } else {
      profileAvatarWidget = null;
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) {
            return previous.userProfile.lastWeightUpdateTimestampMillis !=
                    current.userProfile.lastWeightUpdateTimestampMillis ||
                previous.userProfile.disableWeeklyWeightReminder !=
                    current.userProfile.disableWeeklyWeightReminder ||
                previous.userProfile.weightInKg !=
                    current.userProfile.weightInKg ||
                previous.userProfile.targetGoalWeightKg !=
                    current.userProfile.targetGoalWeightKg ||
                previous.userProfile.nutritionGoal !=
                    current.userProfile.nutritionGoal;
          },
          listener: (context, state) {
            final currentProfile = state.userProfile;
            final nowMillis = DateTime.now().millisecondsSinceEpoch;

            if (_lastGoal != currentProfile.nutritionGoal ||
                _lastTargetWeight != currentProfile.targetGoalWeightKg) {
              _dismissedGoalReview = false;
              _lastGoal = currentProfile.nutritionGoal;
              _lastTargetWeight = currentProfile.targetGoalWeightKg;
            }

            final currentWt = currentProfile.weightInKg;
            final targetWt = currentProfile.targetGoalWeightKg ?? currentWt;
            bool isGoalReached = false;

            if (currentProfile.nutritionGoal == NutritionGoal.LOSE_WEIGHT &&
                currentWt <= targetWt &&
                targetWt > 0)
              isGoalReached = true;
            if (currentProfile.nutritionGoal == NutritionGoal.GAIN_WEIGHT &&
                currentWt >= targetWt &&
                targetWt > 0)
              isGoalReached = true;

            bool isExpired = false;
            if (!isGoalReached &&
                currentProfile.nutritionGoal != NutritionGoal.MAINTAIN_WEIGHT) {
              final startMillis =
                  currentProfile.goalStartTimestampMillis ?? nowMillis;
              if (currentProfile.weeklyGoalRate != null &&
                  currentProfile.weeklyGoalRate! > 0) {
                final baseWt = currentProfile.startingWeightKg ?? currentWt;
                final gap = (targetWt - baseWt).abs();
                final weeks = gap / currentProfile.weeklyGoalRate!;
                final endMillis =
                    startMillis + (weeks * 7 * 24 * 60 * 60 * 1000).toInt();

                if (nowMillis > endMillis) {
                  isExpired = true;
                }
              }
            }

            if (!_dismissedGoalReview && (isGoalReached || isExpired)) {
              _dismissedGoalReview = true;
              showGoalReviewDialog(
                context,
                profile: currentProfile,
                onAction: (action) {
                  context.read<ProfileCubit>().handleGoalReviewAction(action);
                },
                onSuccessGoal: (newGoal) {
                  if (newGoal == NutritionGoal.MAINTAIN_WEIGHT) {
                    context.read<ProfileCubit>().updateGoalParameters(
                      currentProfile.weightInKg,
                      0,
                    );
                  } else {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (navContext) => UpdateGoalDialog(
                          profile: currentProfile,
                          lockedGoal: newGoal,
                          onDismiss: () => Navigator.of(
                            navContext,
                            rootNavigator: true,
                          ).pop(),
                          onConfirm: (wt, days) {
                            context.read<ProfileCubit>().updateGoalParameters(
                              wt,
                              days,
                            );
                            Navigator.of(navContext, rootNavigator: true).pop();
                          },
                        ),
                      ),
                    );
                  }
                },
              );
              return;
            }

            final lastWeightUpdate =
                currentProfile.lastWeightUpdateTimestampMillis ?? nowMillis;
            final isWeeklyReminderPending =
                !_dismissedWeeklyReminder &&
                !currentProfile.disableWeeklyWeightReminder &&
                (nowMillis - lastWeightUpdate > 7 * 24 * 60 * 60 * 1000);

            if (isWeeklyReminderPending) {
              _dismissedWeeklyReminder = true;
              _showWeeklyWeightReminderDialog(context);
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: ValueListenableBuilder<bool>(
          valueListenable: AppRouter.isTourActive,
          builder: (context, isTourRunning, child) {
            return AbsorbPointer(absorbing: isTourRunning, child: child);
          },
          child: Row(
            children: [
              if (isTablet)
                MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(viewInsets: EdgeInsets.zero),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: GymEntrance(
                              offset: const Offset(-10, 0),
                              child: NavigationRail(
                                groupAlignment: 0.0,
                                selectedIndex: _currentBottomBarIndex,
                                onDestinationSelected: _onTapBottomBar,
                                labelType: NavigationRailLabelType.all,
                                backgroundColor: colorScheme.surface,
                                indicatorColor: colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                selectedIconTheme: IconThemeData(
                                  color: colorScheme.primary,
                                ),
                                unselectedIconTheme: IconThemeData(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                                selectedLabelTextStyle: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                unselectedLabelTextStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                destinations: [
                                  NavigationRailDestination(
                                    icon: const Icon(
                                      Symbols.exercise,
                                      fill: 0.0,
                                    ),
                                    selectedIcon: const Icon(
                                      Symbols.exercise,
                                      fill: 1.0,
                                    ),
                                    label: Text(t.workout.title_main),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(
                                      Symbols.nutrition,
                                      fill: 0.0,
                                    ),
                                    selectedIcon: const Icon(
                                      Symbols.nutrition,
                                      fill: 1.0,
                                    ),
                                    label: Text(t.nutrition.title_main),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(
                                      Symbols.leaderboard,
                                      fill: 0.0,
                                    ),
                                    selectedIcon: const Icon(
                                      Symbols.leaderboard,
                                      fill: 1.0,
                                    ),
                                    label: Text(t.gamification.title_main),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Symbols.person, fill: 0.0),
                                    selectedIcon: const Icon(
                                      Symbols.person,
                                      fill: 1.0,
                                    ),
                                    label: Text(t.profile.title_main),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.axis == Axis.vertical) {
                              if (notification is ScrollUpdateNotification) {
                                if (notification.metrics.outOfRange &&
                                    notification.dragDetails == null) {
                                  return false;
                                }
                                if (notification.scrollDelta != null) {
                                  _barAnimController.value +=
                                      notification.scrollDelta! / 150.0;
                                }
                              } else if (notification
                                  is OverscrollNotification) {
                                if (notification.dragDetails != null) {
                                  _barAnimController.value +=
                                      notification.overscroll / 150.0;
                                }
                              } else if (notification
                                  is ScrollEndNotification) {
                                if (_barAnimController.value > 0.0 &&
                                    _barAnimController.value < 1.0) {
                                  bool shouldShow =
                                      _barAnimController.value <= 0.5;

                                  if (globalBottomBarVisibility.value !=
                                      shouldShow) {
                                    globalBottomBarVisibility.value =
                                        shouldShow;
                                  } else {
                                    _barAnimController.animateTo(
                                      shouldShow ? 0.0 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  }
                                }
                              }
                            }
                            return false;
                          },
                          child: ValueListenableBuilder<bool>(
                            valueListenable: AppRouter.isTourActive,
                            builder: (context, isTourRunning, child) {
                              // [CRITICAL FIX]: Thay thế TabBarView bằng IndexedStack khi Tour đang chạy.
                              // Điều này HỦY DIỆT hoàn toàn Scrollable ngang, khiến hàm Scrollable.ensureVisible()
                              // của native Flutter không thể tìm thấy trục ngang để kéo lệch layout,
                              // giải quyết triệt để lỗi "giật ngang/vỡ layout" trên Tablet.
                              if (isTourRunning) {
                                return IndexedStack(
                                  index: _tabController.index,
                                  children: widget.children,
                                );
                              }

                              // Khi không có Tour, trả lại TabBarView bình thường để user vuốt tab
                              return TabBarView(
                                controller: _tabController,
                                children: widget.children,
                              );
                            },
                          ),
                        ),

                        if (!isTablet)
                          GymEntrance(
                            delay: GymMotion.stagger(2),
                            effect: GymMotionEffect.fadeScale,
                            child: _FloatingPillBottomBar(
                              tabController: _tabController,
                              currentIndex: _currentBottomBarIndex,
                              barAnimController: _barAnimController,
                              onTap: _onTapBottomBar,
                              profileAvatar: profileAvatarWidget,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingPillBottomBar extends StatelessWidget {
  final TabController tabController;
  final int currentIndex;
  final AnimationController barAnimController;
  final ValueChanged<int> onTap;
  final Widget? profileAvatar;

  const _FloatingPillBottomBar({
    required this.tabController,
    required this.currentIndex,
    required this.barAnimController,
    required this.onTap,
    required this.profileAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);

    final Color barBgColor = colorScheme.onSurface.withValues(alpha: 0.03);
    final Color activeIndicatorColor = colorScheme.primary.withValues(
      alpha: 0.15,
    );
    final Color iconColorActive = colorScheme.primary;
    final Color iconColorInactive = colorScheme.onSurfaceVariant.withValues(
      alpha: 0.7,
    );

    return AnimatedBuilder(
      animation: barAnimController,
      builder: (context, child) {
        final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
        final barVisibleOffset =
            mainBottomBarVisibleTop(bottomSafeArea) - mainBottomBarHeight;
        const barHiddenOffset = -120.0;
        final barCurrentBottom =
            lerpDouble(
              barVisibleOffset,
              barHiddenOffset,
              barAnimController.value,
            ) ??
            barVisibleOffset;

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: barCurrentBottom,
              child: IgnorePointer(
                ignoring: barAnimController.value > 0.5,
                child: child,
              ),
            ),
          ],
        );
      },
      child: RepaintBoundary(
        child: GymEntrance(
          offset: const Offset(0, 10),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isTablet ? 380 : 288),
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              height: mainBottomBarHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: barBgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        const tabCount = 4;
                        final segmentWidth = totalWidth / tabCount;
                        const indicatorWidth = 64.0;
                        const indicatorHeight = 48.0;

                        return AnimatedBuilder(
                          animation: tabController.animation ?? tabController,
                          builder: (context, _) {
                            final animVal =
                                tabController.animation?.value ??
                                currentIndex.toDouble();
                            final indicatorLeft =
                                (animVal * segmentWidth +
                                        (segmentWidth - indicatorWidth) / 2)
                                    .clamp(0.0, totalWidth - indicatorWidth);

                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // 1. Nền nổi bật trượt mượt mà theo animation chuyển tab
                                Positioned(
                                  left: indicatorLeft,
                                  top:
                                      (constraints.maxHeight -
                                          indicatorHeight) /
                                      2,
                                  width: indicatorWidth,
                                  height: indicatorHeight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: activeIndicatorColor,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),

                                // 2. Hàng các tab điều hướng
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FloatingPillNavItem(
                                        index: 0,
                                        animVal: animVal,
                                        unselectedIcon: Symbols.exercise,
                                        selectedIcon: Symbols.exercise,
                                        activeIconColor: iconColorActive,
                                        inactiveIconColor: iconColorInactive,
                                        onTap: () => onTap(0),
                                      ),
                                    ),
                                    Expanded(
                                      child: _FloatingPillNavItem(
                                        index: 1,
                                        animVal: animVal,
                                        unselectedIcon: Symbols.nutrition,
                                        selectedIcon: Symbols.nutrition,
                                        activeIconColor: iconColorActive,
                                        inactiveIconColor: iconColorInactive,
                                        onTap: () => onTap(1),
                                      ),
                                    ),
                                    Expanded(
                                      child: _FloatingPillNavItem(
                                        index: 2,
                                        animVal: animVal,
                                        unselectedIcon: Symbols.leaderboard,
                                        selectedIcon: Symbols.leaderboard,
                                        activeIconColor: iconColorActive,
                                        inactiveIconColor: iconColorInactive,
                                        onTap: () => onTap(2),
                                      ),
                                    ),
                                    Expanded(
                                      child: _FloatingPillNavItem(
                                        index: 3,
                                        animVal: animVal,
                                        unselectedIcon: Symbols.person,
                                        selectedIcon: Symbols.person,
                                        activeIconColor: iconColorActive,
                                        inactiveIconColor: iconColorInactive,
                                        customAvatar: profileAvatar,
                                        onTap: () => onTap(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingPillNavItem extends StatelessWidget {
  final int index;
  final double animVal;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final Color activeIconColor;
  final Color inactiveIconColor;
  final VoidCallback onTap;
  final Widget? customAvatar;

  const _FloatingPillNavItem({
    required this.index,
    required this.animVal,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.onTap,
    this.customAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final distance = (animVal - index).abs();
    final activeProgress = (1.0 - distance).clamp(0.0, 1.0);
    final isSelected = distance < 0.5;

    final iconColor =
        Color.lerp(inactiveIconColor, activeIconColor, activeProgress) ??
        inactiveIconColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        width: 64,
        alignment: Alignment.center,
        child: customAvatar != null
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: isSelected ? 30 : 26,
                height: isSelected ? 30 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        Color.lerp(
                          Colors.transparent,
                          activeIconColor,
                          activeProgress,
                        ) ??
                        Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(child: customAvatar),
              )
            : Transform.scale(
                scale: 1.0 + 0.06 * activeProgress,
                child: Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: iconColor,
                  size: 26,
                  fill: activeProgress >= 0.5 ? 1.0 : 0.0,
                ),
              ),
      ),
    );
  }
}

void _showWeeklyWeightReminderDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final isSmallMobile = ResponsiveBreakpoints.of(context).smallerThan(MOBILE);

  GymDialog.showCustom(
    context: context,
    useRootNavigator: true,
    titleWidget: Text(
      t.main.title_weekly_reminder,
      style: const TextStyle(fontWeight: FontWeight.bold),
      maxLines: 2,
      softWrap: true,
    ),
    content: Text(
      t.main.msg_weekly_reminder,
      style: TextStyle(color: colorScheme.onSurfaceVariant),
      softWrap: true,
    ),
    actions: [
      if (isSmallMobile)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push('/profile_settings');
              },
              child: Text(
                t.main.btn_weekly_reminder_update,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(
                t.main.btn_weekly_reminder_skip,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                context.read<ProfileCubit>().disableWeeklyWeightReminder();
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text(
                t.nutrition.btn_never_remind_again,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        )
      else
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                context.read<ProfileCubit>().disableWeeklyWeightReminder();
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text(
                t.nutrition.btn_never_remind_again,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(
                    t.main.btn_weekly_reminder_skip,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    context.push('/profile_settings');
                  },
                  child: Text(
                    t.main.btn_weekly_reminder_update,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
    ],
  );
}
