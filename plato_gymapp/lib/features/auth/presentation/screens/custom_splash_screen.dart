import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
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
      _showLanguageSelectionDialog();
    } else {
      context.go(AppRoutes.workout);
    }
  }

  void _showLanguageSelectionDialog() {
    GymDialog.showCustom(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      titleWidget: const Text(
        "Choose Language / Chọn Ngôn Ngữ", 
        textAlign: TextAlign.center, 
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              leading: const Icon(Symbols.language),
              title: const Text("Tiếng Việt", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Symbols.chevron_right),
              onTap: () async {
                LocaleSettings.setLocaleRaw("vi");
                final prefs = getIt<SharedPreferences>();
                await prefs.setString('app_lang', 'vi');
                if (mounted) {
                  Navigator.of(context, rootNavigator: false).pop();
                  context.go(AppRoutes.onboarding);
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              leading: const Icon(Symbols.language),
              title: const Text("English", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Symbols.chevron_right),
              onTap: () async {
                LocaleSettings.setLocaleRaw("en");
                final prefs = getIt<SharedPreferences>();
                await prefs.setString('app_lang', 'en');
                if (mounted) {
                  Navigator.of(context, rootNavigator: false).pop();
                  context.go(AppRoutes.onboarding);
                }
              },
            ),
          ],
        ),
      ),
    );
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