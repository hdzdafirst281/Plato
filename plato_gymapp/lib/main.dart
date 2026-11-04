import 'dart:async';
import 'dart:math' as math;
import 'features/notifications/application/notification_background_worker.dart';
import 'package:flutter/material.dart';
import 'features/notifications/application/notification_coordinator.dart';
import 'features/notifications/presentation/notification_feedback_host.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/workout/data/repositories/workout_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/app_database.dart';
import 'core/designsystem/theme/app_theme.dart';
import 'core/designsystem/theme/theme_cubit.dart'; 
import 'core/navigation/app_router.dart';
import 'core/worker/sync_manager.dart';
import 'core/worker/background_workout_service.dart'; 
import 'core/di/injection.dart'; 
import 'core/utils/focus_utils.dart'; 

import 'core/bloc/tour/tour_cubit.dart'; 

// Import Seeder
import 'features/workout/data/program_seeder.dart';

// Import toàn bộ Cubits từ các Feature
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/bloc/onboarding_cubit.dart';
import 'features/workout/presentation/bloc/active_session_cubit.dart';
import 'features/workout/presentation/bloc/editor_cubit.dart';
import 'features/workout/presentation/bloc/workout_cubit.dart';
import 'features/nutrition/presentation/bloc/nutrition_cubit.dart';
import 'features/profile/presentation/bloc/profile_cubit.dart';
import 'features/profile/presentation/bloc/stats_cubit.dart';
import 'features/gamification/domain/rank_calculator.dart';
import 'features/gamification/domain/reward_progress.dart';
import 'features/gamification/presentation/bloc/gamification_cubit.dart';
import 'features/gamification/presentation/bloc/rank_cubit.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo đầu tiên
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await SyncManager.initialize();
    
    await BackgroundWorkoutService().initialize();
    
    // Khởi tạo các Dependecies (bao gồm SharedPreferences đăng ký trong GetIt)
    await configureDependencies();
    await getIt.allReady();

    final prefs = getIt<SharedPreferences>();
    final savedLang = prefs.getString('app_lang');
    if (savedLang != null) {
      LocaleSettings.setLocaleRaw(savedLang);
    } else {
      LocaleSettings.useDeviceLocale();
    }

    final db = getIt<AppDatabase>(); 
    final programDao = db.workoutProgramDao;
    final currentPrograms = await programDao.getAllPrograms();

    if (currentPrograms.isEmpty) {
      debugPrint("⏳ Đang nạp Programs từ Seeder...");
      final seedData = ProgramSeeder.getInitialPrograms();
      await programDao.insertPrograms(seedData);
    }

    await NotificationCoordinator(db, prefs, getIt<WorkoutRepository>(), getIt<AuthRepository>()).initialize();
    try {
      await NotificationBackgroundWorker.register();
    } catch (error) {
      debugPrint('Notification background registration failed: $error');
    }

    runApp(
      TranslationProvider(
        child: const GymApp(),
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "CRITICAL INIT ERROR:\n\n$e\n\n$stackTrace",
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()), 
        BlocProvider(create: (_) => getIt<AuthCubit>()),
        BlocProvider(create: (_) => getIt<OnboardingCubit>()),
        BlocProvider(create: (_) => getIt<ActiveSessionCubit>(), lazy: false),
        BlocProvider(create: (_) => getIt<ExerciseLibraryCubit>(), lazy: false),
        BlocProvider(create: (_) => getIt<WorkoutCubit>()),
        BlocProvider(create: (_) => getIt<EditorCubit>()),
        BlocProvider(create: (_) => getIt<NutritionCubit>()),
        BlocProvider(create: (_) => getIt<ProfileCubit>()),
        BlocProvider(create: (_) => getIt<StatsCubit>()),
        BlocProvider(create: (_) => getIt<GamificationCubit>()),
        BlocProvider(create: (_) => getIt<RankCubit>()),
        
        // [SỬA LỖI Ở ĐÂY]: Sử dụng đúng TourCubit đã khởi tạo
        BlocProvider(create: (_) => TourCubit(getIt<SharedPreferences>(), getIt<AuthRepository>())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, currentThemeMode) {
          return MaterialApp.router(
            title: 'Plato',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: AppLocaleUtils.supportedLocales,
            locale: TranslationProvider.of(context).flutterLocale, 
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentThemeMode, 
            routerConfig: AppRouter.router, 
            builder: (context, child) {
              // [UI/UX FIX]: 1. Lấy MediaQuery hiện tại của OS
              final mediaQueryData = MediaQuery.of(context);
              
              // [UI/UX FIX]: 2. Clamping TextScaler (Ngưỡng an toàn: 0.9x -> 1.25x)
              final clampedTextScaler = mediaQueryData.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.25,
              );

              // [UI/UX FIX]: 3. Bọc child gốc bằng MediaQuery đã được khống chế text scale
              final clampedChild = MediaQuery(
                data: mediaQueryData.copyWith(textScaler: clampedTextScaler),
                child: child!,
              );

              // 4. Khởi tạo Breakpoints bọc lấy toàn bộ app
              return ResponsiveBreakpoints.builder(
                breakpoints: [
                  const Breakpoint(start: 0, end: 360, name: 'NARROW_MOBILE'),
                  const Breakpoint(start: 361, end: 450, name: MOBILE),
                  const Breakpoint(start: 451, end: 800, name: TABLET),
                  const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                ],
                // 5. Sử dụng Builder để sinh ra innerContext nằm BÊN DƯỚI Breakpoints
                child: Builder(
                  builder: (innerContext) {
                    Widget wrapper = GlobalNotificationWrapper(
                      child: NotificationFeedbackHost(child: GlobalFocusUtils(child: clampedChild))
                    );

                    // 6. Sử dụng innerContext để gọi hàm .of() an toàn
                    if (ResponsiveBreakpoints.of(innerContext).equals('NARROW_MOBILE')) {
                      return ResponsiveScaledBox(
                        width: 360, // Auto scale-down cho các máy có width < 360px
                        child: wrapper,
                      );
                    }
                    
                    return wrapper;
                  },
                ),
              );
            },
          );
        }
      ),
    );
  }
}

class GlobalNotificationWrapper extends StatefulWidget {
  final Widget child;
  const GlobalNotificationWrapper({super.key, required this.child});

  @override
  State<GlobalNotificationWrapper> createState() => _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState extends State<GlobalNotificationWrapper> {
  bool _isInitialized = false;
  int _lastKnownLevel = 1;
  int _lastKnownRankId = 1;

  int? _pendingBaseLevel;
  int? _pendingBaseRankId;
  Timer? _evaluationDebounceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final profile = context.read<ProfileCubit>().state.userProfile;
      final profileLevel = RewardXpProgress.at(profile.experiencePoints).$1;
      final gamificationLevel = context.read<GamificationCubit>().state.stats.level;
      _lastKnownLevel = math.max(profileLevel, gamificationLevel);
      _lastKnownRankId = profile.activeRankId;
    }
  }

  @override
  void dispose() {
    _evaluationDebounceTimer?.cancel();
    super.dispose();
  }

  void _onGamificationChanged(int currentLevel) {
    if (!_isInitialized) {
      _lastKnownLevel = math.max(_lastKnownLevel, currentLevel);
      return;
    }
    _scheduleEvaluation();
  }

  void _onProfileChanged(int currentRankId, int currentProfileLevel) {
    if (!_isInitialized) {
      _lastKnownRankId = currentRankId;
      _lastKnownLevel = math.max(_lastKnownLevel, currentProfileLevel);
      return;
    }
    _scheduleEvaluation();
  }

  void _scheduleEvaluation() {
    _pendingBaseLevel ??= _lastKnownLevel;
    _pendingBaseRankId ??= _lastKnownRankId;

    _evaluationDebounceTimer?.cancel();
    // 350ms delay gives enough time for screen pop/navigation transition
    // and keyboard dismiss animation to complete smoothly.
    _evaluationDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _evaluateAndShowNotification();
    });
  }

  void _evaluateAndShowNotification() {
    final baseLevel = _pendingBaseLevel ?? _lastKnownLevel;
    final baseRankId = _pendingBaseRankId ?? _lastKnownRankId;
    _pendingBaseLevel = null;
    _pendingBaseRankId = null;

    final profile = context.read<ProfileCubit>().state.userProfile;
    final profileLevel = RewardXpProgress.at(profile.experiencePoints).$1;
    final gamificationLevel = context.read<GamificationCubit>().state.stats.level;
    final currentLevel = math.max(profileLevel, gamificationLevel);
    final currentRankId = profile.activeRankId;

    final handledThrough = NotificationCoordinator.instance?.levelHandledThrough ?? 0;
    final hasLevelUp = currentLevel > baseLevel && currentLevel > handledThrough;
    final hasRankUp = currentRankId > baseRankId;

    _lastKnownLevel = currentLevel;
    _lastKnownRankId = currentRankId;

    String currentRoute = '';
    try {
      currentRoute = AppRouter.router.routeInformationProvider.value.uri.toString();
    } catch (_) {}
    if (currentRoute.contains('workout_rewards') || AppRouter.isTourActive.value) {
      return;
    }

    if (hasLevelUp && hasRankUp) {
      _showCombinedProgressionNotification(
        oldLevel: baseLevel,
        newLevel: currentLevel,
        oldRankId: baseRankId,
        newRankId: currentRankId,
      );
    } else if (hasLevelUp) {
      _showLevelUpNotification(
        oldLevel: baseLevel,
        newLevel: currentLevel,
      );
    } else if (hasRankUp) {
      _showRankUpNotification(
        oldRankId: baseRankId,
        newRankId: currentRankId,
      );
    }
  }

  static String _rankBadgeAsset(int rankId) => switch (rankId) {
    1 => 'assets/badges/bronze1.webp',
    2 => 'assets/badges/bronze2.webp',
    3 => 'assets/badges/silver1.webp',
    4 => 'assets/badges/silver2.webp',
    5 => 'assets/badges/gold1.webp',
    6 => 'assets/badges/gold2.webp',
    7 => 'assets/badges/gold3.webp',
    8 => 'assets/badges/diamond.webp',
    _ => 'assets/badges/bronze1.webp',
  };

  void _showCombinedProgressionNotification({
    required int oldLevel,
    required int newLevel,
    required int oldRankId,
    required int newRankId,
  }) {
    final rootContext = AppRouter.router.routerDelegate.navigatorKey.currentContext ?? (mounted ? context : null);
    if (rootContext == null) return;

    final theme = Theme.of(rootContext);
    final colorScheme = theme.colorScheme;
    final newRank = RankConfig.getRankById(newRankId);
    final oldRank = RankConfig.getRankById(oldRankId);
    final newRankName = t.translateDynamic(newRank.nameKey);
    final oldRankName = t.translateDynamic(oldRank.nameKey);
    final accentColor = Color(newRank.colorHex);

    final title = '${t.gamification.msg_level_up_base} & ${t.gamification.msg_rank_up}';
    final levelText = 'Lv. $oldLevel ➔ $newLevel';
    final rankText = '$oldRankName ➔ $newRankName';

    GymTopNotification.show(
      rootContext,
      accentColor: accentColor,
      duration: const Duration(seconds: 4),
      semanticLabel: '$title: $levelText, $rankText',
      leading: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Image.asset(
          _rankBadgeAsset(newRankId),
          width: 30,
          height: 30,
          cacheWidth: 90,
          cacheHeight: 90,
          fit: BoxFit.contain,
        ),
      ),
      customBody: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.gymColors.goldRank.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  levelText,
                  style: TextStyle(
                    color: theme.gymColors.goldRank,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rankText,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLevelUpNotification({
    required int oldLevel,
    required int newLevel,
  }) {
    final rootContext = AppRouter.router.routerDelegate.navigatorKey.currentContext ?? (mounted ? context : null);
    if (rootContext == null) return;

    final theme = Theme.of(rootContext);
    final colorScheme = theme.colorScheme;
    final accentColor = theme.gymColors.goldRank;
    final title = t.gamification.msg_level_up_base;
    final subtitle = 'Lv. $oldLevel ➔ $newLevel';

    GymTopNotification.show(
      rootContext,
      accentColor: accentColor,
      duration: const Duration(seconds: 4),
      semanticLabel: '$title: $subtitle',
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Icon(
          Icons.trending_up_rounded,
          color: accentColor,
          size: 22,
        ),
      ),
      customBody: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showRankUpNotification({
    required int oldRankId,
    required int newRankId,
  }) {
    final rootContext = AppRouter.router.routerDelegate.navigatorKey.currentContext ?? (mounted ? context : null);
    if (rootContext == null) return;

    final theme = Theme.of(rootContext);
    final colorScheme = theme.colorScheme;
    final newRank = RankConfig.getRankById(newRankId);
    final oldRank = RankConfig.getRankById(oldRankId);
    final newRankName = t.translateDynamic(newRank.nameKey);
    final oldRankName = t.translateDynamic(oldRank.nameKey);
    final accentColor = Color(newRank.colorHex);

    final title = t.gamification.msg_rank_up;
    final subtitle = '$oldRankName ➔ $newRankName';

    GymTopNotification.show(
      rootContext,
      accentColor: accentColor,
      duration: const Duration(seconds: 4),
      semanticLabel: '$title: $subtitle',
      leading: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Image.asset(
          _rankBadgeAsset(newRankId),
          width: 30,
          height: 30,
          cacheWidth: 90,
          cacheHeight: 90,
          fit: BoxFit.contain,
        ),
      ),
      customBody: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GamificationCubit, GamificationState>(
          listenWhen: (previous, current) => previous.stats.level != current.stats.level,
          listener: (context, state) => _onGamificationChanged(state.stats.level),
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.userProfile.activeRankId != current.userProfile.activeRankId ||
              previous.userProfile.experiencePoints != current.userProfile.experiencePoints,
          listener: (context, state) => _onProfileChanged(
            state.userProfile.activeRankId,
            RewardXpProgress.at(state.userProfile.experiencePoints).$1,
          ),
        ),
      ],
      child: widget.child,
    );
  }
}