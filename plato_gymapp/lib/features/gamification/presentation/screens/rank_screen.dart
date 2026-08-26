import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_countdown_text.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/designsystem/theme/app_theme.dart';
import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/designsystem/components/gym_shimmer.dart';

import '../../../auth/data/models/user_models.dart';
import '../../domain/rank_calculator.dart'; 
import '../bloc/rank_cubit.dart'; 
part '../components/rank_components.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with SingleTickerProviderStateMixin {
  final bool debugForceLoading = false; // TODO(Debug): Đổi thành false khi build Production
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    
    Widget buildInfoBox(String title, String desc, Color color) {
      return Card(
        elevation: 0,
        color: color.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    
    GymDialog.showCustom(
      context: context,
      useRootNavigator: false,
      titleWidget: Row(
        children: [
          Icon(Symbols.info, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(t.rank.title_info_dialog, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18))),
        ],
      ),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                children: [
                  TextSpan(text: t.rank.desc_info_rp_abbreviation, style: TextStyle(fontWeight: FontWeight.bold, fontFeatures: const [ui.FontFeature.tabularFigures()], color: colorScheme.primary, fontSize: 16)),
                  const TextSpan(text: " "),
                  TextSpan(text: t.rank.desc_info_rp_definition),
                ]
              ),
            ),
            const SizedBox(height: 16),
            buildInfoBox(t.rank.title_info_zone_green, t.rank.desc_info_zone_green, gymColors.success),
            const SizedBox(height: 12),
            buildInfoBox(t.rank.title_info_zone_yellow, t.rank.desc_info_zone_yellow, gymColors.goldRank),
            const SizedBox(height: 12),
            buildInfoBox(t.rank.title_info_zone_red, t.rank.desc_info_zone_red, colorScheme.error),
          ]
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: false).pop(), 
          child: Text(t.common.understood, style: const TextStyle(fontWeight: FontWeight.bold))
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rankState = context.watch<RankCubit>().state; 

    final bool isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final Widget bottomTabBar = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, -4),
            blurRadius: 16,
          )
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: !isTablet,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), 
          child: TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            indicatorPadding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.map, size: 22),
                    const SizedBox(height: 4), 
                    Text(t.rank.tab_journey, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.history, size: 22),
                    const SizedBox(height: 4),
                    Text(t.rank.tab_history, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (rankState == null || debugForceLoading) {
      return _RankShimmer(
        bottomTabBar: bottomTabBar, 
        isTablet: isTablet, 
        tabController: _tabController,
      );
    }

    final int activeRankId = rankState.currentRankId;
    final RankLevel currentRank = RankConfig.getRankById(activeRankId);
    final int currentPoints = rankState.totalRp;
    final int cycleStartTimeMillis = rankState.cycleStartTimeMillis; 
        
    final List<RankLevel> allAvailableRanks = RankConfig.hierarchy;
    final List<RankTimelineItem> advancementHistory = rankState.history;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        backgroundColor: colorScheme.surface,
        title: t.rank.title_main,
        onBackClick: () => context.pop(),
        actions: [
          IconButton(icon: Icon(Symbols.info, color: colorScheme.primary), onPressed: () => _showInfoDialog(context))
        ],
      ),
      bottomNavigationBar: isTablet ? null : bottomTabBar,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SafeArea(
            bottom: isTablet, 
            child: isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _RankGaugeHeader(
                            currentRank: currentRank,
                            points: currentPoints,
                            cycleStartMillis: cycleStartTimeMillis,
                            allRanks: allAvailableRanks,
                            isTablet: true,
                          ),
                        ),
                      ),
                      Container(width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _JourneyTimelineList(allRanks: allAvailableRanks, activeRankId: activeRankId, currentRp: currentPoints),
                                  _HistoryLineChart(history: advancementHistory),
                                ],
                              ),
                            ),
                            bottomTabBar,
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        flex: 5, 
                        // [FIX] Removed SingleChildScrollView for mobile to make it fit exactly
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _RankGaugeHeader(
                            currentRank: currentRank,
                            points: currentPoints,
                            cycleStartMillis: cycleStartTimeMillis,
                            allRanks: allAvailableRanks,
                            isTablet: false,
                          ),
                        ),
                      ),
                      Container(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      Expanded(
                        flex: 5, 
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _JourneyTimelineList(allRanks: allAvailableRanks, activeRankId: activeRankId, currentRp: currentPoints),
                            _HistoryLineChart(history: advancementHistory),
                          ],
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

class _RankShimmer extends StatelessWidget {
  final Widget bottomTabBar;
  final bool isTablet;
  final TabController tabController;

  const _RankShimmer({required this.bottomTabBar, required this.isTablet, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        backgroundColor: colorScheme.surface,
        title: t.rank.title_main,
        onBackClick: () => context.pop(),
        actions: [
          IconButton(icon: Icon(Symbols.info, color: colorScheme.primary), onPressed: null)
        ],
      ),
      bottomNavigationBar: isTablet ? null : bottomTabBar,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SafeArea(
            bottom: isTablet,
            child: isTablet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _buildHeaderShimmer(),
                      ),
                    ),
                    Container(width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(child: _buildListShimmer()),
                          bottomTabBar,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _buildHeaderShimmer(),
                      ),
                    ),
                    Container(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    Expanded(
                      flex: 5,
                      child: _buildListShimmer(),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        
        final double maxCircleHeight = availableHeight - 75.0; // Space for text below (24 + 18) + some padding
        final double maxCircleWidth = availableWidth - 40.0;
        
        final double diameter = math.min(maxCircleWidth, maxCircleHeight);
        
        return GymShimmer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
               GymShimmerCircle(radius: diameter / 2),
               const SizedBox(height: 24),
               const GymShimmerBlock(width: 140, height: 18, borderRadius: 8),
            ],
          ),
        );
      }
    );
  }

  Widget _buildListShimmer() {
    return TabBarView(
      controller: tabController,
      children: [
        _buildJourneyTabShimmer(),
        _buildHistoryTabShimmer(),
      ],
    );
  }

  Widget _buildJourneyTabShimmer() {
    return GymShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 40),
        itemCount: 8,
        itemBuilder: (context, index) {
          final isEven = index % 2 == 0;
          final isFirst = index == 0;
          final isLast = index == 7;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: isEven 
                    ? _buildJourneyShimmerCard(alignRight: true) 
                    : const SizedBox(),
                ),
                _buildJourneyShimmerNode(isFirst: isFirst, isLast: isLast, context: context),
                Expanded(
                  child: !isEven 
                    ? _buildJourneyShimmerCard(alignRight: false) 
                    : const SizedBox(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJourneyShimmerCard({required bool alignRight}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.only(left: alignRight ? 16 : 0, right: alignRight ? 0 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: const [
           GymShimmerBlock(width: double.infinity, height: 80, borderRadius: 16),
        ],
      ),
    );
  }

  Widget _buildJourneyShimmerNode({required bool isFirst, required bool isLast, required BuildContext context}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Expanded(child: isFirst ? const SizedBox() : Container(width: 3, color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              Expanded(child: isLast ? const SizedBox() : Container(width: 3, color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ],
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTabShimmer() {
    return GymShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1 large card (Line Chart)
            const GymShimmerBlock(width: double.infinity, height: 220, borderRadius: 20),
            const SizedBox(height: 24),
            // 4 small cards (2x2)
            Row(
              children: const [
                Expanded(child: GymShimmerBlock(height: 100, borderRadius: 16)),
                SizedBox(width: 16),
                Expanded(child: GymShimmerBlock(height: 100, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: GymShimmerBlock(height: 100, borderRadius: 16)),
                SizedBox(width: 16),
                Expanded(child: GymShimmerBlock(height: 100, borderRadius: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
