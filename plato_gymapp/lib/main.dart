import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
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
import 'features/gamification/presentation/bloc/gamification_cubit.dart';
import 'features/gamification/presentation/bloc/rank_cubit.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo đầu tiên
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    SyncManager.initialize();
    
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
        BlocProvider(create: (_) => TourCubit(getIt<SharedPreferences>())),
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
                      child: GlobalFocusUtils(child: clampedChild)
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
  bool _isFirstLevelEmitted = false;
  int _lastKnownLevel = 1;

  bool _isFirstRankEmitted = false;
  int _lastKnownRankId = 1;

  @override
  void initState() {
    super.initState();
  }

  // 1. Hàm hiển thị cho LEVEL UP
  void _showLevelUpNotification(String title, String subtitle, Color accentColor) {
    final rootContext = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (rootContext == null) return;

    final colorScheme = Theme.of(rootContext).colorScheme;

    GymTopNotification.show(
      rootContext,
      icon: null,
      accentColor: accentColor,
      duration: const Duration(seconds: 4),
      customBody: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Hàm hiển thị ĐẶC BIỆT cho RANK UP
  void _showRankUpNotification(int oldRankId, int newRankId) {
    final rootContext = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (rootContext == null) return;

    final colorScheme = Theme.of(rootContext).colorScheme;
    
    // Lấy thông tin chi tiết từ Domain Layer
    final oldRankInfo = RankConfig.getRankById(oldRankId);
    final newRankInfo = RankConfig.getRankById(newRankId);
    final rankColor = Color(newRankInfo.colorHex);

    GymTopNotification.show(
      rootContext,
      icon: null,
      accentColor: rankColor,
      duration: const Duration(seconds: 5), // Kéo dài thời gian hiển thị
      customBody: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            t.gamification.msg_rank_up,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900, 
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rank cũ (nhỏ hơn, mờ hơn)
              // 🚀 FIX: Dùng nameKey thay vì name
              Text(
                t.translateDynamic(oldRankInfo.nameKey), 
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Symbols.arrow_forward, color: colorScheme.onSurfaceVariant, size: 16),
              const SizedBox(width: 8),
              // Rank mới (To, nổi bật, có hiệu ứng Glow)
              // 🚀 FIX: Dùng nameKey thay vì name
              Text(
                t.translateDynamic(newRankInfo.nameKey), 
                style: TextStyle(
                  color: rankColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: rankColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    )
                  ]
                ),
              ),
            ],
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
          listener: (context, state) {
            final currentLevel = state.stats.level;
            
            if (!_isFirstLevelEmitted) {
              _isFirstLevelEmitted = true;
              _lastKnownLevel = currentLevel;
              return;
            }
            
            if (currentLevel > _lastKnownLevel) {
              _showLevelUpNotification(
                t.gamification.msg_level_up_base,
                '$_lastKnownLevel ➔ $currentLevel',
                Theme.of(context).gymColors.goldRank, 
              );
            }
            _lastKnownLevel = currentLevel;
          },
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listener: (context, state) {
            final currentRankId = state.userProfile.activeRankId;
            
            if (!_isFirstRankEmitted) {
              _isFirstRankEmitted = true;
              _lastKnownRankId = currentRankId > 0 ? currentRankId : 1;
              return;
            }
            
            // Xử lý logic thăng hạng
            if (currentRankId > _lastKnownRankId && _lastKnownRankId > 0) {
              _showRankUpNotification(_lastKnownRankId, currentRankId);
            }
            
            _lastKnownRankId = currentRankId;
          },
        ),
      ],
      child: widget.child,
    );
  }
}