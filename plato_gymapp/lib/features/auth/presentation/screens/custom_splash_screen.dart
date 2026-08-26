import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/navigation/app_routes.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), 
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // CẢI THIỆN: Lắng nghe trạng thái animation thay vì dùng Timer delay cứng
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAndNavigate();
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    // Đảm bảo widget vẫn còn trong tree trước khi điều hướng
    if (!mounted) return;

    final prefs = getIt<SharedPreferences>();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.workout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface, 
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              isDarkMode 
                  ? 'assets/logo/logo_themedark.png' 
                  : 'assets/logo/logo_themelight.png', 
              width: 300, 
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}