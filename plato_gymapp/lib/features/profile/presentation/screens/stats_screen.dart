import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/profile/presentation/components/profile_components.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';

import '../bloc/stats_cubit.dart';
import 'stats/heatmap_detail_screen.dart';
import 'stats/hexagon_detail_screen.dart';
import 'stats/load_analysis_detail_screen.dart';
import 'stats/history_detail_screen.dart';

class StatsScreen extends StatefulWidget {
  final StatsScreenType initialScreen;

  const StatsScreen({
    super.key,
    this.initialScreen = StatsScreenType.DASHBOARD, // Default để không làm hỏng các luồng gọi cũ
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late StatsScreenType _activeScreen;

  @override
  void initState() {
    super.initState();
    // Gán state ban đầu dựa trên tham số truyền vào
    _activeScreen = widget.initialScreen;
  }

  void _handleBack() {
    if (_activeScreen == StatsScreenType.DASHBOARD) {
      context.pop();
    } else {
      setState(() => _activeScreen = StatsScreenType.DASHBOARD); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<StatsCubit>().state.workouts;

    return PopScope(
      canPop: _activeScreen == StatsScreenType.DASHBOARD,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _activeScreen = StatsScreenType.DASHBOARD);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildCurrentScreen(workouts, context),
      ),
    );
  }

  Widget _buildCurrentScreen(List<dynamic> workouts, BuildContext context) {
    switch (_activeScreen) {
      case StatsScreenType.DASHBOARD:
        return _StatsDashboard(
          key: const ValueKey('DASHBOARD'),
          onBack: _handleBack,
          onNavigate: (type) => setState(() => _activeScreen = type),
        );
      case StatsScreenType.LOAD_DETAIL:
        return LoadAnalysisDetailScreen(key: const ValueKey('LOAD'), workouts: workouts.cast(), onBack: _handleBack);
      case StatsScreenType.HEXAGON_DETAIL:
        return HexagonDetailScreen(key: const ValueKey('HEX'), workouts: workouts.cast(), onBack: _handleBack);
      case StatsScreenType.HEATMAP_DETAIL:
        return HeatmapDetailScreen(key: const ValueKey('HEAT'), workouts: workouts.cast(), onBack: _handleBack);
      case StatsScreenType.HISTORY_DETAIL:
        return HistoryDetailScreen(key: const ValueKey('HIST'), workouts: workouts.cast(), onBack: _handleBack);
    }
  }
}

class _StatsDashboard extends StatelessWidget {
  final VoidCallback onBack;
  final Function(StatsScreenType) onNavigate;

  const _StatsDashboard({super.key, required this.onBack, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // [REFACTOR] Sử dụng ResponsiveValue để tối ưu không gian các cạnh
    final double screenPadding = ResponsiveValue<double>(
      context,
      defaultValue: 16.0,
      conditionalValues: [
        Condition.equals(name: 'NARROW_MOBILE', value: 12.0),
        Condition.largerThan(name: MOBILE, value: 24.0),
        Condition.largerThan(name: TABLET, value: 32.0),
      ],
    ).value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(title: t.stats.title_main_dashboard, onBackClick: onBack),
      body: SafeArea(
        // [REFACTOR] Align + ConstrainedBox để chống stretch thẻ card trên Tablet/Desktop
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: EdgeInsets.all(screenPadding),
              children: [
                Text(
                  t.stats.desc_main_prompt, 
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: screenPadding),
                
                DashboardCard(
                  title: t.stats.title_card_load_analysis, 
                  subtitle: t.stats.desc_card_load_analysis,
                  icon: Symbols.cardiology, 
                  color: Theme.of(context).gymColors.warning,
                  onClick: () => onNavigate(StatsScreenType.LOAD_DETAIL),
                ),
                SizedBox(height: screenPadding),
                
                DashboardCard(
                  title: t.stats.title_card_muscle_balance, 
                  subtitle: t.stats.desc_card_muscle_balance,
                  icon: Symbols.hexagon, 
                  color: colorScheme.error,
                  onClick: () => onNavigate(StatsScreenType.HEXAGON_DETAIL),
                ),
                SizedBox(height: screenPadding),
                
                DashboardCard(
                  title: t.stats.title_card_body_heatmap, 
                  subtitle: t.stats.desc_card_body_heatmap,
                  icon: Symbols.conditions, 
                  color: Theme.of(context).gymColors.success,
                  onClick: () => onNavigate(StatsScreenType.HEATMAP_DETAIL),
                ),
                SizedBox(height: screenPadding),
                
                DashboardCard(
                  title: t.stats.title_card_activity_history, 
                  subtitle: t.stats.desc_card_activity_history,
                  icon: Symbols.bar_chart, 
                  color: colorScheme.primary,
                  onClick: () => onNavigate(StatsScreenType.HISTORY_DETAIL),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}