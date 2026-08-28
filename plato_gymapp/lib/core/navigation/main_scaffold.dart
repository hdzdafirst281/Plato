import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'package:plato_gymapp/core/worker/background_workout_service.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/active_session_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../features/nutrition/presentation/components/nutrition_components.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

final ValueNotifier<bool> globalBottomBarVisibility = ValueNotifier<bool>(true);
final ValueNotifier<double> globalBottomBarAnimationProgress = ValueNotifier<double>(0.0); 
final ValueNotifier<int> globalActiveTabIndex = ValueNotifier<int>(0);
final ValueNotifier<bool> globalIsTabSwiping = ValueNotifier<bool>(false);

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

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
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
      vsync: this
    );

    _barAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

    globalBottomBarVisibility.addListener(_onGlobalVisibilityChange);

    _barAnimController.addListener(() {
      globalBottomBarAnimationProgress.value = _barAnimController.value;
    });

    _tabController.animation?.addListener(() {
      int swipeIndex = _tabController.animation!.value.round();
      if (swipeIndex != _currentBottomBarIndex) {
        setState(() {
          _currentBottomBarIndex = swipeIndex;
        });

        globalActiveTabIndex.value = swipeIndex;
        
        if (widget.navigationShell.currentIndex != swipeIndex) {
          widget.navigationShell.goBranch(
            swipeIndex,
            initialLocation: swipeIndex == widget.navigationShell.currentIndex,
          );
        }
      }
      final isSwiping = (_tabController.animation!.value - _tabController.animation!.value.round()).abs() > 0.01;
      
      if (globalIsTabSwiping.value != isSwiping) {
        globalIsTabSwiping.value = isSwiping;
      }
    });

    final initialProfile = context.read<ProfileCubit>().state.userProfile;
    _lastGoal = initialProfile.nutritionGoal;
    _lastTargetWeight = initialProfile.targetGoalWeightKg;
    
    _notificationTapSub = BackgroundWorkoutService.notificationTapStream.stream.listen((payload) {
      _handleNotificationPayload(payload);
    });
    
    if (BackgroundWorkoutService.pendingPayload != null) {
      _handleNotificationPayload(BackgroundWorkoutService.pendingPayload);
    }

    _activeSessionCubit = context.read<ActiveSessionCubit>();
    _activeSessionCubit.autoFinishedSessionNotifier.addListener(_onSessionAutoFinished);

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
          Icon(Icons.assignment_turned_in, color: Theme.of(context).gymColors.accentTeal),
          const SizedBox(width: 8),
          Expanded(child: Text(t.workout.title_auto_finish_success, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.workout.msg_auto_finish_success, style: TextStyle(color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildResultRow(t.workout.col_workout_name, session.name, colorScheme),
                const SizedBox(height: 8),
                _buildResultRow(t.stats.lbl_metric_volume, '${session.totalVolume} kg', colorScheme),
                const SizedBox(height: 8),
                _buildResultRow(t.gamification.lbl_xp_earned, '+${session.xpEarned} XP', colorScheme, valueColor: Theme.of(context).gymColors.goldRank),
              ],
            ),
          )
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
        )
      ]
    );
  }

  Widget _buildResultRow(String label, String value, ColorScheme colorScheme, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor ?? colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == 'route_log_workout') {
      BackgroundWorkoutService.pendingPayload = null; 
      
      if (!mounted) return;
      
      AppRouter.expandWorkoutScreenNotifier.value = true;
    }
  }
  
  Future<void> _checkInitialAppLaunchFromNotification() async {
    final flnp = FlutterLocalNotificationsPlugin();
    final details = await flnp.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      if (details.notificationResponse?.payload == 'route_log_workout') {
        _handleNotificationPayload('route_log_workout');
      }
    }
  }

  void _onGlobalVisibilityChange() {
    if (globalBottomBarVisibility.value && _barAnimController.value > 0.0) {
      _barAnimController.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    } else if (!globalBottomBarVisibility.value && _barAnimController.value < 1.0) {
      _barAnimController.animateTo(1.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
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
    _activeSessionCubit.autoFinishedSessionNotifier.removeListener(_onSessionAutoFinished);
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

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, Color activeBgColor, Color activeIconColor, Color inactiveIconColor, {Widget? customAvatar, bool isSymbol = false}) {
    bool isSelected = _currentBottomBarIndex == index;
    
    return GestureDetector(
      onTap: () => _onTapBottomBar(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 48,
        width: 64, 
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24), 
        ),
        child: customAvatar != null
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 30 : 26, 
                height: isSelected ? 30 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? activeIconColor : Colors.transparent, width: 1.5),
                ),
                child: ClipOval(child: customAvatar),
              )
            : Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? activeIconColor : inactiveIconColor,
                size: 26,
                fill: isSymbol ? (isSelected ? 1.0 : 0.0) : null,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    final colorScheme = Theme.of(context).colorScheme;

    final profile = context.watch<ProfileCubit>().state.userProfile;

    final Color barBgColor = colorScheme.onSurface.withValues(alpha: 0.03);
    final Color activeIndicatorColor = colorScheme.primary.withValues(alpha: 0.15); 
    final Color iconColorActive = colorScheme.primary;
    final Color iconColorInactive = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    Widget? profileAvatarWidget;
    if (profile.avatarBase64 != null && profile.avatarBase64!.isNotEmpty) {
      profileAvatarWidget = Image.memory(
        base64Decode(profile.avatarBase64!), 
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Symbols.person, color: colorScheme.onPrimaryContainer, size: 20),
      );
    } else {
      profileAvatarWidget = null; 
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) {
            return previous.userProfile.lastWeightUpdateTimestampMillis != current.userProfile.lastWeightUpdateTimestampMillis ||
                   previous.userProfile.disableWeeklyWeightReminder != current.userProfile.disableWeeklyWeightReminder ||
                   previous.userProfile.weightInKg != current.userProfile.weightInKg ||
                   previous.userProfile.targetGoalWeightKg != current.userProfile.targetGoalWeightKg ||
                   previous.userProfile.nutritionGoal != current.userProfile.nutritionGoal;
          },
          listener: (context, state) {
            final currentProfile = state.userProfile;
            final nowMillis = DateTime.now().millisecondsSinceEpoch;
            
            if (_lastGoal != currentProfile.nutritionGoal || _lastTargetWeight != currentProfile.targetGoalWeightKg) {
              _dismissedGoalReview = false; 
              _lastGoal = currentProfile.nutritionGoal;
              _lastTargetWeight = currentProfile.targetGoalWeightKg;
            }

            final currentWt = currentProfile.weightInKg;
            final targetWt = currentProfile.targetGoalWeightKg ?? currentWt;
            bool isGoalReached = false;
            
            if (currentProfile.nutritionGoal == NutritionGoal.LOSE_WEIGHT && currentWt <= targetWt && targetWt > 0) isGoalReached = true;
            if (currentProfile.nutritionGoal == NutritionGoal.GAIN_WEIGHT && currentWt >= targetWt && targetWt > 0) isGoalReached = true;

            bool isExpired = false;
            if (!isGoalReached && currentProfile.nutritionGoal != NutritionGoal.MAINTAIN_WEIGHT) {
              final startMillis = currentProfile.goalStartTimestampMillis ?? nowMillis;
              if (currentProfile.weeklyGoalRate != null && currentProfile.weeklyGoalRate! > 0) {
                final baseWt = currentProfile.startingWeightKg ?? currentWt;
                final gap = (targetWt - baseWt).abs();
                final weeks = gap / currentProfile.weeklyGoalRate!;
                final endMillis = startMillis + (weeks * 7 * 24 * 60 * 60 * 1000).toInt();
                
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
                      context.read<ProfileCubit>().updateGoalParameters(currentProfile.weightInKg, 0);
                    } else {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (navContext) => UpdateGoalDialog(
                            profile: currentProfile,
                            lockedGoal: newGoal,
                            onDismiss: () => Navigator.of(navContext, rootNavigator: true).pop(),
                            onConfirm: (wt, days) {
                              context.read<ProfileCubit>().updateGoalParameters(wt, days);
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

            final lastWeightUpdate = currentProfile.lastWeightUpdateTimestampMillis ?? nowMillis;
            final isWeeklyReminderPending = !_dismissedWeeklyReminder && 
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
            return AbsorbPointer(
              absorbing: isTourRunning, 
              child: child,
            );
          },
          child: Row(
            children: [
              if (isTablet)
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    viewInsets: EdgeInsets.zero, 
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              groupAlignment: 0.0, 
                              selectedIndex: _currentBottomBarIndex,
                              onDestinationSelected: _onTapBottomBar, 
                              labelType: NavigationRailLabelType.all,
                              backgroundColor: colorScheme.surface,
                              indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
                              selectedIconTheme: IconThemeData(color: colorScheme.primary),
                              unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                              selectedLabelTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                              unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                              destinations: [
                                NavigationRailDestination(
                                  icon: const Icon(Symbols.exercise, fill: 0.0), 
                                  selectedIcon: const Icon(Symbols.exercise, fill: 1.0),
                                  label: Text(t.workout.title_main)
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Symbols.nutrition, fill: 0.0), 
                                  selectedIcon: const Icon(Symbols.nutrition, fill: 1.0), 
                                  label: Text(t.nutrition.title_main)
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Symbols.leaderboard, fill: 0.0), 
                                  selectedIcon: const Icon(Symbols.leaderboard, fill: 1.0), 
                                  label: Text(t.gamification.title_main)
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Symbols.person, fill: 0.0), 
                                  selectedIcon: const Icon(Symbols.person, fill: 1.0), 
                                  label: Text(t.profile.title_main)
                                ),
                              ],
                            ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideX(begin: -0.1, end: 0),
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
                                if (notification.metrics.outOfRange && notification.dragDetails == null) {
                                  return false; 
                                }
                                if (notification.scrollDelta != null) {
                                  _barAnimController.value += notification.scrollDelta! / 150.0;
                                }
                              } 
                              else if (notification is OverscrollNotification) {
                                if (notification.dragDetails != null) {
                                  _barAnimController.value += notification.overscroll / 150.0;
                                }
                              } 
                              else if (notification is ScrollEndNotification) {
                                if (_barAnimController.value > 0.0 && _barAnimController.value < 1.0) {
                                  bool shouldShow = _barAnimController.value <= 0.5;
                                  
                                  if (globalBottomBarVisibility.value != shouldShow) {
                                    globalBottomBarVisibility.value = shouldShow; 
                                  } else {
                                    _barAnimController.animateTo(
                                      shouldShow ? 0.0 : 1.0, 
                                      duration: const Duration(milliseconds: 200), 
                                      curve: Curves.easeOutCubic
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
                            }
                          ),
                        ),
                        
                        if (!isTablet)
                          AnimatedBuilder(
                            animation: _barAnimController,
                            builder: (context, child) {
                              final bottomSafeArea = MediaQuery.of(context).padding.bottom;
                              
                              final barVisibleOffset = bottomSafeArea > 0 ? bottomSafeArea + 8.0 : 16.0;
                              final barHiddenOffset = -120.0;
                              final barCurrentBottom = lerpDouble(barVisibleOffset, barHiddenOffset, _barAnimController.value)!;
                              
                              return Stack(
                                children: [
                                  Positioned(
                                    left: 0, 
                                    right: 0,
                                    bottom: barCurrentBottom, 
                                    child: Center(
                                      child: Container(
                                        constraints: BoxConstraints(maxWidth: isTablet ? 420 : 320), 
                                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                                        height: 60, 
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(32),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 3), blurRadius: 8),
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
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  _buildNavItem(0, Symbols.exercise, Symbols.exercise, activeIndicatorColor, iconColorActive, iconColorInactive, isSymbol: true),
                                                  _buildNavItem(1, Symbols.nutrition, Symbols.nutrition, activeIndicatorColor, iconColorActive, iconColorInactive, isSymbol: true),
                                                  _buildNavItem(2, Symbols.leaderboard, Symbols.leaderboard, activeIndicatorColor, iconColorActive, iconColorInactive, isSymbol: true),
                                                  _buildNavItem(3, Symbols.person, Symbols.person, activeIndicatorColor, iconColorActive, iconColorInactive, customAvatar: profileAvatarWidget, isSymbol: true),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
                                  ),
                                ],
                              );
                            },
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
              child: Text(t.main.btn_weekly_reminder_update, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(), 
              child: Text(t.main.btn_weekly_reminder_skip, style: TextStyle(color: colorScheme.onSurfaceVariant))
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                context.read<ProfileCubit>().disableWeeklyWeightReminder();
                Navigator.of(context, rootNavigator: true).pop();
              }, 
              child: Text(t.nutrition.btn_never_remind_again, style: TextStyle(color: colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold))
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
              child: Text(t.nutrition.btn_never_remind_again, style: TextStyle(color: colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold))
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(), 
                  child: Text(t.main.btn_weekly_reminder_skip, style: TextStyle(color: colorScheme.onSurfaceVariant))
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
                  child: Text(t.main.btn_weekly_reminder_update, style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ],
        ),
    ]
  );
}