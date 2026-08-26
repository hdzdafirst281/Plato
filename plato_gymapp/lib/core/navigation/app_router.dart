// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:ui'; 
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/account_management_screen.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/settings_screen.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';

import 'app_routes.dart';
import 'main_scaffold.dart';
import '../di/injection.dart'; 

import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/auth_otp_screen.dart';
import '../../features/auth/presentation/screens/custom_splash_screen.dart';

import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../features/workout/presentation/screens/explore_programs_screen.dart';
import '../../features/workout/presentation/screens/routine_screen.dart';
import '../../features/workout/presentation/screens/log_workout_screen.dart';
import '../../features/workout/presentation/screens/session_summary_screen.dart';
import '../../features/workout/presentation/screens/exercise_library_screen.dart';
import '../../features/workout/presentation/screens/workout_detail_screen.dart';
import '../../features/workout/presentation/screens/exercise_details_screen.dart';

import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/nutrition/presentation/screens/food_encyclopedia_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_history_screen.dart'; 
import '../../features/nutrition/presentation/bloc/nutrition_cubit.dart';

import '../../features/gamification/presentation/screens/gamification_screen.dart';
import '../../features/gamification/presentation/screens/rank_screen.dart';

import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/profile/presentation/screens/tutorial_screen.dart';
import '../../features/profile/presentation/screens/calendar_screen.dart';
import '../../features/profile/presentation/screens/stats_screen.dart';

import '../../features/workout/presentation/bloc/active_session_cubit.dart';
import '../../features/workout/presentation/components/workout_components.dart';

class AppRouter {
  static final ValueNotifier<bool> _enableAutoScroll = ValueNotifier<bool>(true);
  static final ValueNotifier<int> _currentTourIndex = ValueNotifier<int>(0);
  static final ValueNotifier<bool> isTourActive = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> expandWorkoutScreenNotifier = ValueNotifier<bool>(false);
  
  static List<GlobalKey> _activeTourKeys = [];
  static int _tourOffset = 0; // [NEW]: Lưu giữ offset để không mất lịch sử

  // [NEW]: Lưu trữ callback để gọi khi Tour thực sự hoàn thành hoặc bị Skip
  static VoidCallback? _onTourCompleted;

  // [FIX]: Thêm tham số onCompleted vào hàm startTour
  static void startTour(BuildContext context, List<GlobalKey> keys, {VoidCallback? onCompleted}) {
    if (keys.isEmpty) return;
    _activeTourKeys = keys;
    _tourOffset = 0; 
    _currentTourIndex.value = 0; 
    
    // Lưu lại callback của màn hình hiện tại
    _onTourCompleted = onCompleted;
    
    isTourActive.value = true; 
    ShowCaseWidget.of(context).startShowCase(keys);
  }


  static void abortTour(BuildContext context) {
    _onTourCompleted = null; 
    try { 
      ShowCaseWidget.of(context).dismiss(); 
    } catch (_) {}
    forceAbortTour();
  }

  // [CRITICAL FIX 2]: Khóa an toàn 100% để chống Crash khi Back vật lý
  static void forceAbortTour() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onTourCompleted = null;
      if (isTourActive.value) {
        isTourActive.value = false;
      }
      _activeTourKeys.clear();
      _tourOffset = 0;
      setAutoScroll(true);
    });
  }
  
  static final _appNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNav');
  static final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
  
  static final _shellNavigatorWorkoutKey = GlobalKey<NavigatorState>(debugLabel: 'shellWorkout');
  static final _shellNavigatorNutritionKey = GlobalKey<NavigatorState>(debugLabel: 'shellNutrition');
  static final _shellNavigatorSocialKey = GlobalKey<NavigatorState>(debugLabel: 'shellSocial');
  static final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  static void setAutoScroll(bool enable) {
    _enableAutoScroll.value = enable;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _appNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const CustomSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => OnboardingScreen(
          onFinishOnboarding: () {
            getIt<SharedPreferences>().setBool('isFirstRun', false);
            context.go(AppRoutes.workout);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.auth,
        parentNavigatorKey: _appNavigatorKey, 
        builder: (context, state) {
          final flowType = state.extra as AuthFlowType? ?? AuthFlowType.login;
          return AuthOtpScreen(flowType: flowType);
        },
      ),
      GoRoute(
        path: AppRoutes.sessionSummary, 
        name: 'session_summary',
        parentNavigatorKey: _appNavigatorKey,
        builder: (context, state) {
          final workoutId = state.extra as String?;
          return SessionSummaryScreen(workoutId: workoutId); 
        },
      ),
      GoRoute(
        path: '/exercise_library', 
        name: 'exercise_library',
        parentNavigatorKey: _appNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ShowCaseWidget(
            onFinish: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                isTourActive.value = false;
                _activeTourKeys.clear(); 
                _tourOffset = 0; 
                _onTourCompleted?.call();
                _onTourCompleted = null;
              });
            },
            builder: (showcaseContext) => ExerciseLibraryScreen(
              mode: extra['mode'] ?? LibraryMode.view,
              preSelectedIds: extra['preSelectedIds'] ?? const [],
              onExercisesSelected: extra['onSelected'],
              suggestedMuscle: extra['suggestedMuscle'], 
            ),
          );
        }
      ),
      GoRoute(
        path: '/exercise_details',
        name: 'exercise_details',
        parentNavigatorKey: _appNavigatorKey,
        pageBuilder: (context, state) {
          final exercise = state.extra as Exercise?;
          return MaterialPage(
            key: ValueKey('exercise_details_${exercise?.id ?? 'null'}'),
            child: ExerciseDetailsScreen(exercise: exercise!),
          );
        },
      ),
      
      ShellRoute(
        navigatorKey: _rootNavigatorKey,
          builder: (context, state, shellChild) {
            // [FIX 1]: Binding _enableAutoScroll động để có thể bật/tắt theo từng màn hình
            return ValueListenableBuilder<bool>(
              valueListenable: _enableAutoScroll,
              builder: (context, isAutoScrollEnabled, _) {
                return ShowCaseWidget(
                  blurValue: 1,
                  
                  // [CRITICAL FIX]: TRẢ LẠI QUYỀN AUTO SCROLL CHO THƯ VIỆN.
                  // Nhờ MainScaffold đã đổi sang IndexedStack, tính năng này giờ đây 
                  // sẽ đợi cuộn dọc mượt mà đến đúng Meal Card rồi mới hiện bong bóng 
                  // mà không lo bị vỡ layout ngang.
                  enableAutoScroll: true, 
                  scrollDuration: const Duration(milliseconds: 300), // Ép thời gian cuộn để thư viện chờ
                  
                  onStart: (index, key) {
                    _currentTourIndex.value = _tourOffset + index!;
                    isTourActive.value = true;
                    // TUYỆT ĐỐI KHÔNG GỌI HÀM CUỘN CUSTOM NÀO Ở ĐÂY NỮA
                  },
                  onComplete: (index, key) {
                  },
                  onFinish: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      isTourActive.value = false;
                      _activeTourKeys.clear(); 
                      _tourOffset = 0; 

                      _onTourCompleted?.call();
                      _onTourCompleted = null;
                    });
                  },
                  globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
                    left: 0,
                    right: 0,
                    bottom: 0, 
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final isTablet = constraints.maxWidth >= 600;
                        final safeBottomPadding = MediaQuery.of(ctx).padding.bottom + 16;

                        return Padding(
                          padding: EdgeInsets.only(bottom: safeBottomPadding, left: 16, right: 16),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _currentTourIndex,
                            builder: (context, currentIndex, _) {
                              final skipBtn = ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  foregroundColor: Colors.white, 
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () {
                                  _onTourCompleted?.call();
                                  _onTourCompleted = null;

                                  ShowCaseWidget.of(showcaseContext).dismiss();
                                  isTourActive.value = false;
                                  AppRouter.setAutoScroll(true);
                                },
                                child: Text(t.common.skip, style: const TextStyle(fontWeight: FontWeight.bold)),
                              );

                              final backBtn = ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white, 
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () {
                                  final internalIndex = currentIndex - _tourOffset;
                                  if (internalIndex > 0) {
                                    ShowCaseWidget.of(showcaseContext).previous();
                                  } else if (currentIndex > 0) {
                                    _tourOffset = currentIndex - 1;
                                    final newKeys = _activeTourKeys.sublist(_tourOffset);
                                    ShowCaseWidget.of(showcaseContext).dismiss();
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      ShowCaseWidget.of(showcaseContext).startShowCase(newKeys);
                                    });
                                  }
                                }, 
                                child: Text(t.common.back, style: const TextStyle(fontWeight: FontWeight.bold)),
                              );

                              return isTablet 
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (currentIndex > 0) ...[backBtn, const SizedBox(height: 12)],
                                        skipBtn,
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        skipBtn,
                                        const SizedBox(width: 16),
                                        if (currentIndex > 0) backBtn,
                                      ],
                                    );
                            },
                          ),
                        );
                      }
                    ),
                  ),
                  builder: (showcaseContext) => ValueListenableBuilder<bool>(
                    valueListenable: isTourActive,
                    builder: (context, isActive, _) {
                      return PopScope(
                        canPop: !isActive,
                        onPopInvokedWithResult: (didPop, result) {
                          if (didPop) return;
                          if (isActive) {
                            AppRouter.abortTour(showcaseContext); // Gọi abortTour an toàn
                          }
                        },
                        child: _GlobalPlayerWrapper(
                          showcaseContext: showcaseContext, 
                          state: state, 
                          child: shellChild
                        ),
                      );
                    },
                  ),
                );
              }
            );
        },
        routes: [
          StatefulShellRoute(
            builder: (context, state, navigationShell) {
              return navigationShell; 
            },
            navigatorContainerBuilder: (context, navigationShell, children) {
              return MainScaffold(
                navigationShell: navigationShell,
                children: children, 
              );
            },
            branches: [
              StatefulShellBranch(
                navigatorKey: _shellNavigatorWorkoutKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.workout,
                    builder: (context, state) => const WorkoutScreen(),
                    routes: [
                      GoRoute(
                        path: AppRoutes.explorePrograms,
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) => const ExploreProgramsScreen(),
                      ),
                      GoRoute(
                        path: AppRoutes.createRoutine,
                        parentNavigatorKey: _appNavigatorKey, 
                        builder: (context, state) => const RoutineScreen(),
                      ),
                      GoRoute(
                        path: AppRoutes.workoutDetail,
                        name: 'workout_detail',
                        parentNavigatorKey: _appNavigatorKey, 
                        builder: (context, state) {
                          final id = state.pathParameters['workoutId'] ?? '';
                          return WorkoutDetailScreen(workoutId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: _shellNavigatorNutritionKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.nutrition,
                    builder: (context, state) => const NutritionScreen(),
                    routes: [
                      GoRoute(
                        path: 'history',
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) => const NutritionHistoryScreen(),
                      ),
                      GoRoute(
                        path: AppRoutes.foodEncyclopedia,
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) {
                          final mealTypeStr = state.pathParameters['mealType'] ?? 'BREAKFAST';
                          final mealType = MealType.values.firstWhere(
                            (e) => e.name == mealTypeStr, 
                            orElse: () => MealType.BREAKFAST
                          );
                          
                          final nutritionCubit = context.watch<NutritionCubit>();
                          final nutritionState = nutritionCubit.state;

                          return FoodEncyclopediaScreen(
                            mealType: mealType,
                            foodDatabase: nutritionState.foodDatabase,
                            recentFoods: nutritionState.recentFoods,
                            onAddFoods: (selectedFoodsMap) {
                              selectedFoodsMap.forEach((food, qty) {
                                final updatedFood = FoodResult(
                                  id: food.id,
                                  foodName: food.foodName,
                                  baseCalories: food.baseCalories,
                                  baseProtein: food.baseProtein,
                                  baseCarbs: food.baseCarbs,
                                  baseFat: food.baseFat,
                                  measurementUnit: food.measurementUnit,
                                  consumedAmount: qty.toDouble(),
                                  assignedMealType: mealType,
                                );
                                nutritionCubit.addFoodToLog(updatedFood, mealType);
                              });
                            },
                            onQuickAdd: (calories) => nutritionCubit.quickAddCalories(calories, mealType),
                            onBack: () => context.pop(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: _shellNavigatorSocialKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.social,
                    builder: (context, state) => const GamificationScreen(),
                    routes: [
                      GoRoute(
                        path: AppRoutes.rank,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const RankScreen(),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: _shellNavigatorProfileKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.profile,
                    builder: (context, state) => const ProfileScreen(),
                    routes: [
                      GoRoute(
                        path: AppRoutes.stats,
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) {
                          final initialScreen = state.extra as StatsScreenType? ?? StatsScreenType.DASHBOARD;
                          return StatsScreen(initialScreen: initialScreen);
                        },
                      ),
                      GoRoute(
                        path: AppRoutes.calendar,
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) => const CalendarScreen(),
                      ),
                      GoRoute(
                        path: AppRoutes.profileSettings,
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) => const ProfileSettingsScreen(),
                      ),
                      GoRoute(
                        path: AppRoutes.tutorial,
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) => const TutorialScreen(),
                      ),
                      GoRoute(
                        path: AppRoutes.settings,
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) => const SettingsScreen(),
                      ),
                      GoRoute(
                        path: 'account_management',
                        name: 'account_management',
                        parentNavigatorKey: _rootNavigatorKey, 
                        builder: (context, state) => const AccountManagementScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ]
      )
    ],
  );
}

class _GlobalPlayerWrapper extends StatefulWidget {
  final Widget child;
  final GoRouterState state;
  final BuildContext showcaseContext;

  const _GlobalPlayerWrapper({required this.child, required this.state, required this.showcaseContext,});

  @override
  State<_GlobalPlayerWrapper> createState() => _GlobalPlayerWrapperState();
}

enum DragState { none, expanding, minimizing }

class _GlobalPlayerWrapperState extends State<_GlobalPlayerWrapper> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _minimizeController;
  late AnimationController _expandController;

  Timer? _resizeDebouncer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final isCurrentlyMinimized = context.read<ActiveSessionCubit>().state.isMiniplayerMinimized;
    _minimizeController = AnimationController(vsync: this, value: isCurrentlyMinimized ? 1.0 : 0.0, duration: const Duration(milliseconds: 300));
    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    AppRouter.expandWorkoutScreenNotifier.addListener(_onExpandNotifierChanged);
  }

  void _onExpandNotifierChanged() {
    if (AppRouter.expandWorkoutScreenNotifier.value) {
      _expandController.forward().then((_) => HapticFeedback.selectionClick());
    } else {
      _expandController.reverse();
      FocusManager.instance.primaryFocus?.unfocus(); 
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppRouter.expandWorkoutScreenNotifier.removeListener(_onExpandNotifierChanged);
    _expandController.dispose();
    _minimizeController.dispose();
    _resizeDebouncer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    if (!AppRouter.isTourActive.value || AppRouter._activeTourKeys.isEmpty) return;

    // [FIX 1]: Tắt Tour lập tức khi bắt đầu xoay để tránh Highlight vẽ sai tọa độ
    ShowCaseWidget.of(widget.showcaseContext).dismiss();

    _resizeDebouncer?.cancel();
    _resizeDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _handleSettledLayoutShift();
    });
  }

  void _handleSettledLayoutShift() {
    final currentIndex = AppRouter._currentTourIndex.value;
    
    if (currentIndex < AppRouter._activeTourKeys.length) {
      AppRouter._tourOffset = currentIndex; 
      final remainingKeys = AppRouter._activeTourKeys.sublist(currentIndex);

      if (mounted && AppRouter.isTourActive.value) {
        ShowCaseWidget.of(widget.showcaseContext).startShowCase(remainingKeys);
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final activeCubit = context.read<ActiveSessionCubit>();
    final isPill = activeCubit.state.isMiniplayerMinimized;
    final delta = details.primaryDelta!;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_expandController.value > 0.0) {
      _expandController.value -= delta / screenHeight;
      return;
    }

    if (_minimizeController.value > 0.0 && _minimizeController.value < 1.0) {
      if (isPill) {
        _minimizeController.value -= delta / 150.0; 
      } else {
        _minimizeController.value += delta / 150.0; 
      }
      return;
    }

    if (delta < 0) {
      _expandController.value -= delta / screenHeight;
    } else {
      if (isPill) {
        _minimizeController.value -= delta / 150.0;
      } else {
        _minimizeController.value += delta / 150.0;
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final activeCubit = context.read<ActiveSessionCubit>();
    final isPill = activeCubit.state.isMiniplayerMinimized;
    final velocity = details.primaryVelocity ?? 0;
    
    if (_expandController.value > 0.0 && _expandController.value < 1.0) {
      final bool shouldExpand = velocity < -300 || _expandController.value > 0.2;
      if (shouldExpand) {
         _expandController.forward().then((_) => HapticFeedback.selectionClick());
         AppRouter.expandWorkoutScreenNotifier.value = true;
      } else {
         _expandController.reverse();
         AppRouter.expandWorkoutScreenNotifier.value = false;
         FocusManager.instance.primaryFocus?.unfocus();
      }
      return; 
    }

    if (_minimizeController.value > 0.0 && _minimizeController.value < 1.0) {
      if (isPill) {
        if (velocity > 300 || _minimizeController.value < 0.7) {
          activeCubit.maximizeMiniplayer(); 
        } else {
          _minimizeController.animateTo(1.0, curve: Curves.easeOutCubic);
        }
      } else {
        if (velocity > 300 || _minimizeController.value > 0.3) {
          activeCubit.minimizeMiniplayer(); 
        } else {
          _minimizeController.animateTo(0.0, curve: Curves.easeOutCubic);
        }
      }
    }
  }

  Widget _buildFloatingTimerPill(BuildContext context, ActiveSessionState sessionState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isResting = sessionState.restTimerSeconds > 0;
    final time = isResting ? sessionState.restTimerSeconds : sessionState.workoutTimerSeconds;

    final h = time ~/ 3600;
    final m = (time % 3600) ~/ 60;
    final s = time % 60;
    final formattedMS = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final timeStr = h > 0 ? '$h:$formattedMS' : formattedMS;

    final activeBgColor = time > 240 * 60 
        ? colorScheme.error 
        : (time > 120 * 60 ? Theme.of(context).gymColors.warning : colorScheme.primary);
    final bgColor = isResting ? Theme.of(context).gymColors.warning : activeBgColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: bgColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isResting ? Symbols.timer : Symbols.play_arrow, color: Colors.white, size: 20, fill: 1.0),
          const SizedBox(width: 8),
          Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFeatures: [FontFeature.tabularFigures()])),
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSessionCubit = context.watch<ActiveSessionCubit>();
    final activeSessionState = activeSessionCubit.state;
    final activeWorkout = activeSessionState.activeWorkout;
    final isWorkoutActive = activeWorkout != null;
    final isMinimized = activeSessionState.isMiniplayerMinimized;
    
    final currentPath = widget.state.uri.path;
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final isHiddenScreen = currentPath.contains('exercise_library') || 
                           currentPath.contains('exercise_details');

    final hasBottomBar = !isTablet && ['/workout', '/nutrition', '/social', '/profile'].contains(currentPath);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocListener<ActiveSessionCubit, ActiveSessionState>(
        listenWhen: (prev, curr) => prev.isMiniplayerMinimized != curr.isMiniplayerMinimized,
        listener: (context, state) {
          HapticFeedback.heavyImpact();

          if (state.isMiniplayerMinimized) {
            _minimizeController.animateTo(1.0, curve: Curves.easeOutCubic);
          } else {
            _minimizeController.animateTo(0.0, curve: Curves.easeOutCubic);
          }
        },
        child: Stack(
          children: [
            widget.child,
            if (isWorkoutActive && !isHiddenScreen)
              ValueListenableBuilder<double>(
                valueListenable: globalBottomBarAnimationProgress,
                builder: (context, animValue, _) {
                  final bottomSafeArea = MediaQuery.of(context).padding.bottom;
                  
                  double maxPlayerBottom;
                  if (isTablet) {
                    maxPlayerBottom = bottomSafeArea + 4.0;
                  } else if (hasBottomBar) {
                    maxPlayerBottom = lerpDouble(80.0 + bottomSafeArea, bottomSafeArea + 4.0, animValue) ?? (bottomSafeArea + 4.0);
                  } else {
                    maxPlayerBottom = bottomSafeArea + 4.0; 
                  }

                  return AnimatedBuilder(
                    animation: _minimizeController,
                    builder: (context, _) {
                      final val = _minimizeController.value;
                      
                      return Stack(
                        children: [
                          Positioned(
                            bottom: maxPlayerBottom + 12, 
                            right: 24,
                            child: IgnorePointer(
                              ignoring: !isMinimized,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragUpdate: (d) => _handleDragUpdate(d),
                                onVerticalDragEnd: (d) => _handleDragEnd(d),
                                onTap: () => AppRouter.expandWorkoutScreenNotifier.value = true,
                                child: Transform.translate(
                                  offset: Offset(0, 50.0 * (1.0 - val)), 
                                  child: Transform.scale(
                                    scale: 0.8 + (0.2 * val), 
                                    child: Opacity(
                                      opacity: val.clamp(0.0, 1.0),
                                      child: _buildFloatingTimerPill(context, activeSessionState),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: maxPlayerBottom, 
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              ignoring: isMinimized, 
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque, 
                                onVerticalDragUpdate: (d) => _handleDragUpdate(d),
                                onVerticalDragEnd: (d) => _handleDragEnd(d),
                                child: Transform.translate(
                                  offset: Offset(0, val * 100.0), 
                                  child: Opacity(
                                    opacity: (1.0 - val).clamp(0.0, 1.0),
                                    child: SafeArea(
                                      top: false, bottom: false, 
                                      child: WorkoutMiniPlayer(
                                        currentActiveSession: activeWorkout, 
                                        activeSessionCubit: activeSessionCubit,
                                        onResumeSessionClick: () => AppRouter.expandWorkoutScreenNotifier.value = true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            if (isWorkoutActive)
              AnimatedBuilder(
                animation: _expandController,
                builder: (context, child) {
                  final val = _expandController.value;
                  if (val == 0.0) return const Offstage(); 
                  return Offstage(
                    offstage: val == 0.0,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1), 
                        end: Offset.zero, 
                      ).animate(CurvedAnimation(
                        parent: _expandController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: LogWorkoutScreen(
                  onMinimize: () => AppRouter.expandWorkoutScreenNotifier.value = false,
                  isExpandedNotifier: AppRouter.expandWorkoutScreenNotifier,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
