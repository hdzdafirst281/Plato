part of '../screens/rank_screen.dart';

// ================= GAUGE CHART HEADER (FIXED OVERFLOW) =================

class _RankGaugeHeader extends StatelessWidget {
  final RankLevel currentRank;
  final int points;
  final int cycleStartMillis;
  final List<RankLevel> allRanks;
  final bool isTablet;

  const _RankGaugeHeader({required this.currentRank, required this.points, required this.cycleStartMillis, required this.allRanks, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final int maxRankId = allRanks.map((e) => e.id).reduce(math.max);
    final bool isMaxRank = currentRank.id == maxRankId;
    
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    final rankColor = _getRankColor(context, currentRank.id);

    final double maxRenderRP = isMaxRank ? (currentRank.maintainPoints * 1.5) : (currentRank.promotePoints * 1.2);
    final double maintainRatio = maxRenderRP > 0 ? (currentRank.maintainPoints / maxRenderRP).clamp(0.0, 1.0) : 0.0;
    final double promoteRatio = maxRenderRP > 0 ? (currentRank.promotePoints / maxRenderRP).clamp(0.0, 1.0) : 0.0;
    final double targetRatio = maxRenderRP > 0 ? (points / maxRenderRP).clamp(0.0, 1.0) : 0.0;

    final startDate = DateFormat("dd/MM/yyyy").format(DateTime.fromMillisecondsSinceEpoch(cycleStartMillis));
    final endDateMillis = cycleStartMillis + (RankConfig.rollingWindowDays * 24 * 60 * 60 * 1000);
    final endDate = DateFormat("dd/MM/yyyy").format(DateTime.fromMillisecondsSinceEpoch(endDateMillis));

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // [FIX 1] Khoảng không gian DÀNH RIÊNG cho phần text phía dưới (để không cấn vào đồ thị)
        const double bottomTextSpace = 65.0; 
        const double baseStroke = 20.0;
        
        // 1. Tính max radius theo CHIỀU NGANG
        final double maxRadiusW = (availableWidth - baseStroke) / 2;
        
        // 2. Tính max radius theo CHIỀU DỌC
        // Đồ thị vòng cung bắt đầu từ 0.8 pi đến 2.2 pi. 
        // Điểm thấp nhất của 2 đầu vòng cung (tại 36 độ) có khoảng cách Y từ tâm là: radius * sin(36°) ≈ radius * 0.588
        // Tổng chiều cao lý thuyết của Arc = radius (phần trên tâm) + radius * 0.588 (phần dưới tâm) = radius * 1.588
        // Trừ đi không gian cho text, độ dày viền và padding an toàn (8px)
        final double maxRadiusH = (availableHeight - bottomTextSpace - baseStroke - 8.0) / 1.588;

        // 3. Chốt Radius an toàn nhất (Fit hoàn hảo không bao giờ tràn viền)
        final double optimalRadius = math.max(60.0, math.min(maxRadiusW, maxRadiusH));
        
        // 4. Tính lại tỉ lệ thu phóng (Scale) cho Badge/Stroke/Text bên trong
        final double scaleFactor = (optimalRadius / 134.0).clamp(0.6, 1.3);
        final double strokeWidthScaled = baseStroke * scaleFactor;

        // 5. [FIX 2] TOẠ ĐỘ BẮT ĐẦU CHÍNH XÁC (Tránh cắt xén Top)
        // Điểm cao nhất của vòng cung là (centerY - radius - stroke/2). 
        // Để nó vừa chạm đỉnh vùng không gian (>= 0), phương trình là:
        final double centerY = optimalRadius + (strokeWidthScaled / 2) + 4.0; // 4.0 là safe padding nhẹ trên đỉnh
        
        // 6. [FIX 3] Chiều cao và Rộng CHÍNH XÁC của vùng vẽ chứa Arc
        final double chartHeight = centerY + (optimalRadius * 0.588) + (strokeWidthScaled / 2) + 4.0;
        final double chartWidth = (optimalRadius * 2) + strokeWidthScaled;

        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // [FIX 4] Tự động dàn đều không gian
            children: [
              SizedBox(
                width: chartWidth,
                height: chartHeight,
                child: Stack(
                  clipBehavior: Clip.none, 
                  alignment: Alignment.center,
                  children: [
                    Animate(key: ValueKey(points)).custom(
                      duration: 1500.ms,
                      curve: Curves.easeOutCubic,
                      end: targetRatio,
                      builder: (context, value, child) {
                        return CustomPaint(
                          size: Size(chartWidth, chartHeight),
                          painter: _GaugeChartPainter(
                            currentRatio: value,
                            maintainRatio: maintainRatio,
                            promoteRatio: promoteRatio,
                            maintainPoints: currentRank.maintainPoints,
                            promotePoints: currentRank.promotePoints,
                            isRank1: currentRank.id == 1,
                            isMaxRank: isMaxRank,
                            colorDemotion: colorScheme.error,
                            colorMaintain: gymColors.goldRank,
                            colorPromote: gymColors.success,
                            colorIndicator: colorScheme.primary,
                            surfaceColor: colorScheme.surface,
                            baseTrackColor: colorScheme.onSurfaceVariant, 
                            outlineVariantColor: colorScheme.outlineVariant, 
                            rpLabelColor: colorScheme.primary,
                            strokeWidth: strokeWidthScaled,
                            radius: optimalRadius,
                            safeCenterY: centerY, 
                          ),
                        );
                      },
                    ),
                    
                    Positioned(
                      top: centerY - (90 * scaleFactor), 
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.only(bottom: 8 * scaleFactor), 
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: rankColor.withValues(alpha: 0.35), blurRadius: 28 * scaleFactor, spreadRadius: -6)
                              ],
                            ),
                            child: Image.asset(
                              _getBadgeAssetPath(currentRank.id),
                              width: 100 * scaleFactor, 
                              height: 100 * scaleFactor,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Text(
                            _translateRankName(currentRank.nameKey),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant, 
                              fontWeight: FontWeight.w600, 
                              letterSpacing: 0.5, 
                              height: 1.0, 
                              fontSize: 16 * scaleFactor,
                            ),
                          ),
                          SizedBox(height: 10 * scaleFactor),
                          _RPTypography(
                            text: t.rank.format_rp(arg1: points.toString()), 
                            fontSize: 40.0 * scaleFactor, 
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Container bọc text ở dưới cùng để quản lý không gian
              SizedBox(
                height: bottomTextSpace,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      t.rank.format_cycle_duration(arg1: startDate, arg2: endDate), 
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.normal)
                    ),
                    const SizedBox(height: 6),
                    _MiniSeasonCountdownBadge(cycleStartMillis: cycleStartMillis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugeChartPainter extends CustomPainter {
  final double currentRatio;
  final double maintainRatio;
  final double promoteRatio;
  final int maintainPoints;
  final int promotePoints;
  final bool isRank1;
  final bool isMaxRank;
  final Color colorDemotion;
  final Color colorMaintain;
  final Color colorPromote;
  final Color colorIndicator;
  final Color surfaceColor;
  final Color baseTrackColor;
  final Color outlineVariantColor;
  final Color rpLabelColor;
  final double strokeWidth;
  final double radius;
  final double safeCenterY; 

  _GaugeChartPainter({
    required this.currentRatio, required this.maintainRatio, required this.promoteRatio,
    required this.maintainPoints, required this.promotePoints,
    required this.isRank1, required this.isMaxRank,
    required this.colorDemotion, required this.colorMaintain, required this.colorPromote, 
    required this.colorIndicator, required this.surfaceColor, required this.baseTrackColor, required this.outlineVariantColor, required this.rpLabelColor,
    required this.strokeWidth, required this.radius, required this.safeCenterY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, safeCenterY); 
    final rect = Rect.fromCircle(center: center, radius: radius);

    final double startAngle = math.pi * 0.8; 
    final double totalSweep = math.pi * 1.4; 

    // 1. Vẽ Empty Track
    final emptyTrackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt 
      ..color = baseTrackColor.withValues(alpha: 0.1); 
    canvas.drawArc(rect, startAngle, totalSweep, false, emptyTrackPaint);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt; 

    const double outlineStrokeWidth = 3.0;
    final double outerRadius = radius + (strokeWidth / 2) + (outlineStrokeWidth / 2);
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);

    final outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineStrokeWidth
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineStrokeWidth
      ..strokeCap = StrokeCap.butt; 

    const double gap = 0.035; 

    void drawZone(double startRatio, double endRatio, Color color) {
      if (startRatio >= endRatio) return;
      double arcStart = startAngle + (startRatio * totalSweep);
      double arcSweep = (endRatio - startRatio) * totalSweep;

      if (startRatio > 0.0) {
        arcStart += gap / 2;
        arcSweep -= gap / 2;
      }
      if (endRatio < 1.0) {
        arcSweep -= gap / 2;
      }

      outerGlowPaint.color = color;
      canvas.drawArc(outerRect, arcStart, arcSweep, false, outerGlowPaint);

      outerPaint.color = color;
      canvas.drawArc(outerRect, arcStart, arcSweep, false, outerPaint);

      bgPaint.color = color.withValues(alpha: 0.35); 
      canvas.drawArc(rect, arcStart, arcSweep, false, bgPaint);
    }

    if (isRank1) {
      drawZone(0.0, promoteRatio, colorMaintain);
      drawZone(promoteRatio, 1.0, colorPromote);
    } else if (isMaxRank) {
      drawZone(0.0, maintainRatio, colorDemotion);
      drawZone(maintainRatio, 1.0, colorMaintain);
    } else {
      drawZone(0.0, maintainRatio, colorDemotion);
      drawZone(maintainRatio, promoteRatio, colorMaintain);
      drawZone(promoteRatio, 1.0, colorPromote);
    }

    // 2. Vẽ Gauge Chart Mini & Tick mark
    final arrowAngle = startAngle + (currentRatio * totalSweep);
    _drawGlowingTick(canvas, center, radius, strokeWidth, startAngle, totalSweep, arrowAngle);
  }

  void _drawGlowingTick(Canvas canvas, Offset center, double radius, double bgStroke, double startAngle, double totalSweep, double arrowAngle) {
    final innerRadius = radius - (bgStroke / 2) - 6; 
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    
    final emptyMiniPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = outlineVariantColor.withValues(alpha: 0.3);
    canvas.drawArc(innerRect, startAngle, totalSweep, false, emptyMiniPaint);

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = colorIndicator
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4); 
      
    final currentSweep = arrowAngle - startAngle;
    if (currentSweep > 0) {
      canvas.drawArc(innerRect, startAngle, currentSweep, false, activePaint);
    }

    final tickPaint = Paint()
      ..color = colorIndicator
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6); 
      
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
      
    final lineInner = innerRadius - 2;
    final lineOuter = radius + (bgStroke / 2) + 2;
    
    final p1 = Offset(center.dx + lineInner * math.cos(arrowAngle), center.dy + lineInner * math.sin(arrowAngle));
    final p2 = Offset(center.dx + lineOuter * math.cos(arrowAngle), center.dy + lineOuter * math.sin(arrowAngle));
    
    canvas.drawLine(p1, p2, tickPaint); 
    canvas.drawLine(p1, p2, corePaint); 
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ================= JOURNEY TIMELINE =================

class _JourneyTimelineList extends StatelessWidget {
  final List<RankLevel> allRanks;
  final int activeRankId;
  final int currentRp;

  const _JourneyTimelineList({required this.allRanks, required this.activeRankId, required this.currentRp});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: allRanks.length,
      itemBuilder: (context, index) {
        final rank = allRanks[index];
        final isEven = index % 2 == 0;
        final isCurrent = rank.id == activeRankId;
        final isLocked = rank.id > activeRankId;
        final isAchieved = rank.id < activeRankId;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              Expanded(
                child: isEven 
                  ? _JourneyCard(rank: rank, isCurrent: isCurrent, isLocked: isLocked, isAchieved: isAchieved, currentRp: currentRp, alignRight: true) 
                  : const SizedBox(),
              ),
              _JourneyNode(isCurrent: isCurrent, isAchieved: isAchieved, rankColor: _getRankColor(context, rank.id), isFirst: index == 0, isLast: index == allRanks.length - 1),
              Expanded(
                child: !isEven 
                  ? _JourneyCard(rank: rank, isCurrent: isCurrent, isLocked: isLocked, isAchieved: isAchieved, currentRp: currentRp, alignRight: false) 
                  : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JourneyNode extends StatelessWidget {
  final bool isCurrent;
  final bool isAchieved;
  final Color rankColor;
  final bool isFirst;
  final bool isLast;

  const _JourneyNode({required this.isCurrent, required this.isAchieved, required this.rankColor, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final grayColor = colorScheme.outlineVariant.withValues(alpha: 0.3);
    final nodeColor = isAchieved || isCurrent ? rankColor : colorScheme.surfaceContainerHighest;
    
    final Color topLineColor = (isAchieved || isCurrent) ? rankColor.withValues(alpha: 0.8) : grayColor;
    final Color bottomLineColor = isAchieved ? rankColor.withValues(alpha: 0.8) : grayColor;

    return SizedBox(
      // [FIX] Tăng không gian bao ngoài (từ 48 lên 64) để chứa được Node lớn hơn
      width: 48, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Expanded(child: isFirst ? const SizedBox() : Container(width: 3, color: topLineColor)),
              Expanded(child: isLast ? const SizedBox() : Container(width: 3, color: bottomLineColor)),
            ],
          ),
          Container(
            width: isCurrent ? 32 : 24, 
            height: isCurrent ? 32 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              border: isCurrent ? Border.all(color: colorScheme.surface, width: 4) : Border.all(color: colorScheme.surface, width: 2),
              boxShadow: isCurrent ? [BoxShadow(color: rankColor.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)] : null,
            ),
            // Cân đối lại size icon check cho vừa với node
            child: isAchieved && !isCurrent ? Icon(Symbols.check, size: 16, color: colorScheme.surface, weight: 700) : null,
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final RankLevel rank;
  final bool isCurrent;
  final bool isLocked;
  final bool isAchieved;
  final int currentRp;
  final bool alignRight;

  const _JourneyCard({
    required this.rank, 
    required this.isCurrent, 
    required this.isLocked, 
    required this.isAchieved, 
    required this.currentRp, 
    required this.alignRight
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rankColor = _getRankColor(context, rank.id);
    
    Color bgColor = colorScheme.surface;
    Color borderColor = colorScheme.outlineVariant.withValues(alpha: 0.2);
    double cardOpacity = 1.0;

    if (isCurrent) {
      bgColor = colorScheme.surfaceContainer;
      borderColor = rankColor;
    } else if (isAchieved) {
      bgColor = rankColor.withValues(alpha: 0.15); 
      borderColor = rankColor;                     
    } else if (isLocked) {
      bgColor = colorScheme.surfaceContainerLow;
      cardOpacity = 0.5;                           
    }

    // 1. Dựng khung UI cơ bản của Card
    Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 2.0 : 1.0,
        ),
        boxShadow: isCurrent 
            ? [BoxShadow(color: rankColor.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 4))] 
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!alignRight) _buildBadgeIcon(rank, isLocked, colorScheme),
          if (!alignRight) const SizedBox(width: 12),
          
          Flexible(
            child: Column(
              crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _translateRankName(rank.nameKey), 
                  style: TextStyle(
                    color: isCurrent ? colorScheme.onSurface : colorScheme.onSurfaceVariant, 
                    fontWeight: FontWeight.bold, 
                    fontSize: isCurrent ? 14 : 13
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                if (isCurrent) ...[
                  Text(
                    "$currentRp / ${rank.promotePoints} RP", 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: rankColor, fontFeatures: const [ui.FontFeature.tabularFigures()])
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 120, 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: rank.promotePoints > 0 ? (currentRp / rank.promotePoints).clamp(0.0, 1.0) : 1.0,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: rankColor,
                        minHeight: 6,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    "${rank.promotePoints} RP", 
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontFeatures: const [ui.FontFeature.tabularFigures()])
                  ),
                ]
              ],
            ),
          ),

          if (alignRight) const SizedBox(width: 12),
          if (alignRight) _buildBadgeIcon(rank, isLocked, colorScheme),
        ],
      ),
    );

    // 2. [FIX] Chỉ thêm animation Shimmer Loop cho đúng thẻ hiện tại (isCurrent)
    if (isCurrent) {
      cardContent = cardContent
          .animate(onPlay: (controller) => controller.repeat(reverse: false)) // Ra lệnh chạy vô tận
          .shimmer(duration: 2500.ms, color: rankColor.withValues(alpha: 0.25));
    }

    // 3. Đóng gói vào Margin, Padding và Opacity chung
    return Opacity(
      opacity: cardOpacity,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: EdgeInsets.only(left: alignRight ? 16 : 0, right: alignRight ? 0 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            cardContent,
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(RankLevel rank, bool isLocked, ColorScheme colorScheme) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Center(
        child: isLocked 
            ? Icon(Symbols.lock, size: 28, color: colorScheme.onSurfaceVariant)
            : Image.asset(
                _getBadgeAssetPath(rank.id),
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}

// ======================= RANK HISTORY CHART SECTION =======================

enum RankChartTimeRange { oneYear, allTime }

class _RankChartDataPoint {
  final int timestamp;
  final int rankId;
  final int rp;
  final String labelX;

  _RankChartDataPoint({required this.timestamp, required this.rankId, required this.rp, required this.labelX});
}

class _HistoryLineChart extends StatefulWidget {
  final List<RankTimelineItem> history;

  const _HistoryLineChart({required this.history});

  @override
  State<_HistoryLineChart> createState() => _HistoryLineChartState();
}

class _HistoryLineChartState extends State<_HistoryLineChart> {
  RankChartTimeRange _selectedRange = RankChartTimeRange.oneYear;

  List<_RankChartDataPoint> _processData(String langCode) {
    if (widget.history.isEmpty) return [];

    if (_selectedRange == RankChartTimeRange.oneYear) {
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch;
      final filtered = widget.history.where((e) => e.achievedAtMillis >= oneYearAgo).toList()
        ..sort((a, b) => a.achievedAtMillis.compareTo(b.achievedAtMillis));
      
      return filtered.map((e) {
        final date = DateTime.fromMillisecondsSinceEpoch(e.achievedAtMillis);
        return _RankChartDataPoint(
          timestamp: e.achievedAtMillis,
          rankId: e.rankId,
          rp: RankConfig.getRankById(e.rankId).maintainPoints,
          labelX: DateFormat("dd/MM", langCode).format(date),
        );
      }).toList();
    } else {
      // All-time: Group by Year, get max rank
      Map<int, RankTimelineItem> yearlyMax = {};
      for (var item in widget.history) {
        final year = DateTime.fromMillisecondsSinceEpoch(item.achievedAtMillis).year;
        if (!yearlyMax.containsKey(year) || item.rankId > yearlyMax[year]!.rankId) {
          yearlyMax[year] = item;
        }
      }
      
      final sortedYears = yearlyMax.keys.toList()..sort();
      return sortedYears.map((year) {
        final item = yearlyMax[year]!;
        // Lưu timestamp gốc để hiển thị tooltip chính xác ngày đạt được kỉ lục đó
        return _RankChartDataPoint(
          timestamp: item.achievedAtMillis, 
          rankId: item.rankId,
          rp: RankConfig.getRankById(item.rankId).maintainPoints,
          labelX: year.toString(),
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final langCode = TranslationProvider.of(context).flutterLocale.languageCode;
    final chartData = _processData(langCode);

    int peakRankId = 1;
    int upCount = 0;
    int downCount = 0;
    
    // [NEW] Thêm biến tính chuỗi thăng hạng liên tiếp
    int maxStreak = 0;
    int currentStreak = 0;
    
    final sortedFull = List<RankTimelineItem>.from(widget.history)..sort((a, b) => a.achievedAtMillis.compareTo(b.achievedAtMillis));
    if (sortedFull.isNotEmpty) {
      peakRankId = sortedFull.first.rankId;
      for (int i = 1; i < sortedFull.length; i++) {
        if (sortedFull[i].rankId > peakRankId) peakRankId = sortedFull[i].rankId;
        
        if (sortedFull[i].rankId > sortedFull[i - 1].rankId) {
          upCount++;
          currentStreak++;
          if (currentStreak > maxStreak) maxStreak = currentStreak; // Cập nhật kỷ lục streak
        } else if (sortedFull[i].rankId < sortedFull[i - 1].rankId) {
          downCount++;
          currentStreak = 0; // Đứt chuỗi khi rớt hạng
        } else {
          currentStreak = 0; // Đứt chuỗi nếu chỉ giữ hạng
        }
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Bộ lọc thời gian (Toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.rank.title_history_chart, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    _TimeFilterChip(
                      label: t.stats.label_time_range_year, 
                      isSelected: _selectedRange == RankChartTimeRange.oneYear,
                      onTap: () => setState(() => _selectedRange = RankChartTimeRange.oneYear),
                    ),
                    _TimeFilterChip(
                      label: t.stats.label_time_range_all, 
                      isSelected: _selectedRange == RankChartTimeRange.allTime,
                      onTap: () => setState(() => _selectedRange = RankChartTimeRange.allTime),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (_selectedRange == RankChartTimeRange.allTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(Symbols.info, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.rank.msg_all_time_chart, style: TextStyle(color: colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
            
          // 2. Biểu đồ   
          if (chartData.isEmpty)
            Container(
              height: 220, // [FIX] Đã giảm chiều cao
              alignment: Alignment.center,
              child: Text(t.rank.msg_history_empty, style: TextStyle(color: colorScheme.onSurfaceVariant)),
            )
          else
            SizedBox(
              height: 220, // [FIX] Giảm chiều cao chart từ 280 -> 220 để fit màn hình hơn
              width: double.infinity,
              child: _RankHistoryLineChartData(dataPoints: chartData, timeRange: _selectedRange),
            ),
            
          const SizedBox(height: 32),
          // [FIX] Truyền thêm maxStreak vào component Stats
          _HistorySummaryStats(peakRankId: peakRankId, upCount: upCount, downCount: downCount, maxStreak: maxStreak),
        ],
      ),
    );
  }
}

class _TimeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeFilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ======================= RANK INTERACTIVE LINE CHART =======================

class _RankHistoryLineChartData extends StatefulWidget {
  final List<_RankChartDataPoint> dataPoints;
  final RankChartTimeRange timeRange;

  const _RankHistoryLineChartData({required this.dataPoints, required this.timeRange});

  @override
  State<_RankHistoryLineChartData> createState() => _RankHistoryLineChartDataState();
}

class _RankHistoryLineChartDataState extends State<_RankHistoryLineChartData> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _growthAnim;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _growthAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _RankHistoryLineChartData oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange || oldWidget.dataPoints.length != widget.dataPoints.length) {
      _selectedIndex = -1;
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _getAxisStep(double maxVal) {
    if (maxVal <= 0.0) return 100.0;
    final unrounded = maxVal / 4.5;
    final order = math.pow(10.0, (math.log(unrounded) / math.ln10).floorToDouble()).toDouble();
    final norm = unrounded / order;
    
    double mult;
    if (norm < 1.5) {
      mult = 1.0;
    } else if (norm < 2.5) mult = 2.0;
    else if (norm < 4.0) mult = 2.5; 
    else if (norm < 7.5) mult = 5.0;
    else mult = 10.0;
    
    double step = mult * order;
    if (step * 5 < maxVal) {
        if (mult == 1.0) {
          step = 2.0 * order;
        } else if (mult == 2.0) step = 2.5 * order;
        else if (mult == 2.5) step = 5.0 * order;
        else if (mult == 5.0) step = 10.0 * order;
    }
    return step;
  }

  // [FIX] Cập nhật logic bắt điểm 2D (Toạ độ X và Y)
  void _updateSelection(Offset localPosition, double padLeft, double w, double h, double chartHeight, double axisMax) {
    if (widget.dataPoints.isEmpty) return;

    double minDistance = double.infinity;
    int closestIndex = -1;
    
    for(int i = 0; i < widget.dataPoints.length; i++) {
      // 1. Lấy toạ độ tâm X của điểm
      double cx = widget.dataPoints.length == 1 
          ? padLeft + w / 2 
          : padLeft + (i * w / (widget.dataPoints.length - 1));
          
      // 2. Lấy toạ độ tâm Y của điểm (giả định progress đã là 1.0)
      double cy = h - ((widget.dataPoints[i].rp / axisMax) * chartHeight);
      
      // 3. Tính khoảng cách đường chéo 2D (Euclidean distance)
      final dist = math.sqrt(math.pow(localPosition.dx - cx, 2) + math.pow(localPosition.dy - cy, 2));
      
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }
    
    // [FIX] Thu nhỏ Hitbox radius xuống 24 pixels (chỉ nhận khi chạm sát vào dot)
    if (minDistance <= 24.0) { 
      if (_selectedIndex != closestIndex) {
        setState(() => _selectedIndex = closestIndex);
      }
    } else {
      // Chạm ra ngoài hitbox -> Tắt tooltip
      if (_selectedIndex != -1) {
        setState(() => _selectedIndex = -1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final langCode = TranslationProvider.of(context).flutterLocale.languageCode;
    
    const padLeft = 32.0; 
    const padRight = 8.0;
    const paddingTop = 16.0; 
    const paddingBottom = 24.0; 

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth - padLeft - padRight;
        final h = constraints.maxHeight - paddingBottom;
        final chartHeight = h - paddingTop;

        double axisMax = 100;
        double axisStep = 20;
        if (widget.dataPoints.isNotEmpty) {
          if (widget.dataPoints.length == 1) {
            final val = widget.dataPoints[0].rp.toDouble();
            axisMax = val <= 0 ? 100.0 : val * 2.0;
            axisStep = axisMax / 5.0;
          } else {
            final maxVal = widget.dataPoints.map((e) => e.rp).reduce(math.max).toDouble();
            axisStep = _getAxisStep(maxVal);
            axisMax = axisStep * 5;
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // [FIX] Bỏ các sự kiện Drag ngang, chỉ dùng onTapDown để bắt chính xác vị trí tay chạm
          onTapDown: (details) => _updateSelection(details.localPosition, padLeft, w, h, chartHeight, axisMax),
          child: AnimatedBuilder(
            animation: _growthAnim,
            builder: (context, _) {
              final progress = _growthAnim.value;
              
              List<Offset> points = [];
              for (int i = 0; i < widget.dataPoints.length; i++) {
                 double cx = widget.dataPoints.length == 1 
                    ? padLeft + w / 2 
                    : padLeft + (i * w / (widget.dataPoints.length - 1)); 
                 double cy = h - ((widget.dataPoints[i].rp / axisMax) * chartHeight) * progress; 
                 points.add(Offset(cx, cy));
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RankLineBasePainter(
                        data: widget.dataPoints, points: points,
                        axisStep: axisStep, axisMax: axisMax, progress: progress,
                        padLeft: padLeft, padRight: padRight, paddingTop: paddingTop, paddingBottom: paddingBottom,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),

                  ...List.generate(widget.dataPoints.length, (i) {
                    final p = points[i];
                    final isSelected = _selectedIndex == i;
                    final badgeSize = isSelected ? 28.0 : 20.0; 
                    
                    return Positioned(
                      left: p.dx - (badgeSize / 2),
                      top: p.dy - (badgeSize / 2),
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? colorScheme.surface : Colors.transparent,
                            boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)] : null,
                          ),
                          child: Image.asset(
                            _getBadgeAssetPath(widget.dataPoints[i].rankId),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  }),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RankTooltipPainter(
                          data: widget.dataPoints, points: points, selectedIndex: _selectedIndex, progress: progress,
                          padLeft: padLeft, padRight: padRight, langCode: langCode, colorScheme: colorScheme,
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ============== PAINTER 1: BACKGROUND & LINES ==============
class _RankLineBasePainter extends CustomPainter {
  final List<_RankChartDataPoint> data;
  final List<Offset> points;
  final double axisStep, axisMax, progress;
  final double padLeft, padRight, paddingTop, paddingBottom;
  final ColorScheme colorScheme;

  _RankLineBasePainter({
    required this.data, required this.points, required this.axisStep, required this.axisMax, required this.progress, 
    required this.padLeft, required this.padRight, required this.paddingTop, required this.paddingBottom, required this.colorScheme
  });

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0; const dashSpace = 5.0;
    double startX = start.dx;
    while (startX < end.dx) {
      canvas.drawLine(Offset(startX, start.dy), Offset(math.min(startX + dashWidth, end.dx), start.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final h = size.height - paddingBottom; 
    final chartHeight = h - paddingTop; 
    
    final paintGrid = Paint()..color = colorScheme.outlineVariant..strokeWidth = 1.0;
    final paintAxis = Paint()..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.5)..strokeWidth = 2.0;

    // Vẽ Grid ngang & Y Labels
    for (int i = 1; i <= 4; i++) {
      final val = axisStep * i;
      final y = h - ((val / axisMax) * chartHeight);
      _drawDashedLine(canvas, Offset(padLeft, y), Offset(size.width - padRight, y), paintGrid);

      if (progress > 0) { 
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: progress.clamp(0.0, 1.0)), fontSize: 10, fontFeatures: const [ui.FontFeature.tabularFigures()]))
          ..addText("${val.toInt()}");
        final p = builder.build()..layout(ui.ParagraphConstraints(width: padLeft - 8));
        canvas.drawParagraph(p, Offset(0, y - 6));
      }
    }

    // Vẽ 2 trục L và X (đáy)
    canvas.drawLine(Offset(padLeft, paddingTop), Offset(padLeft, h), paintAxis);
    canvas.drawLine(Offset(padLeft, h), Offset(size.width - padRight, h), paintAxis);

    // Vẽ Label X (Thời gian / Năm)
    final skipRate = (data.length / 6).ceil().clamp(1, 999);
    for (int i = 0; i < data.length; i++) {
      if (i % skipRate == 0) {
        final cx = points[i].dx;
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold))
          ..addText(data[i].labelX);
        final p = builder.build()..layout(const ui.ParagraphConstraints(width: 80));
        canvas.drawParagraph(p, Offset(cx - 40, h + 12));
      }
    }

    // Vẽ Gradient & Line
    if (points.length > 1) {
      final fillPath = Path()..moveTo(points.first.dx, h);
      for (var p in points) { fillPath.lineTo(p.dx, p.dy); }
      fillPath.lineTo(points.last.dx, h);
      fillPath.close(); // Tách lệnh close() ra dòng riêng

      final paintGradient = Paint()..shader = ui.Gradient.linear(
        Offset(0, paddingTop), Offset(0, h),
        [colorScheme.primary.withValues(alpha: 0.3), colorScheme.primary.withValues(alpha: 0.0)]
      );
      canvas.drawPath(fillPath, paintGradient);

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) { linePath.lineTo(points[i].dx, points[i].dy); }
      
      final paintLine = Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, paintLine);
    }
  }
  @override
  bool shouldRepaint(covariant _RankLineBasePainter old) => old.progress != progress;
}

// ============== PAINTER 2: TOOLTIP ==============
class _RankTooltipPainter extends CustomPainter {
  final List<_RankChartDataPoint> data;
  final List<Offset> points;
  final int selectedIndex;
  final double progress, padLeft, padRight;
  final String langCode;
  final ColorScheme colorScheme;

  _RankTooltipPainter({
    required this.data, required this.points, required this.selectedIndex, required this.progress, 
    required this.padLeft, required this.padRight, required this.langCode, required this.colorScheme
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndex < 0 || selectedIndex >= data.length || progress < 0.99) return;
    
    final p = points[selectedIndex];
    final item = data[selectedIndex];
    final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
    
    String dateStr = DateFormat("dd MMM yyyy", langCode).format(date);
    String rpStr = "${item.rp} RP";
    String rankName = _translateRankName(RankConfig.getRankById(item.rankId).nameKey);
    
    // Format Tooltip: "15 Oct 2026 \n 150 RP - Đồng II"
    final textSpan = TextSpan(
      children: [
        TextSpan(text: "$dateStr\n", style: TextStyle(color: colorScheme.surface.withValues(alpha: 0.8), fontSize: 11)),
        TextSpan(text: "$rpStr - $rankName", style: TextStyle(color: colorScheme.surface, fontSize: 13, fontWeight: FontWeight.w900)),
      ]
    );
    final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center)..layout();
    
    double tooltipX = p.dx;
    final boxWidth = textPainter.width + 24;
    // Chặn chống tràn mép màn hình
    if (tooltipX - boxWidth / 2 < padLeft) tooltipX = padLeft + boxWidth / 2;
    if (tooltipX + boxWidth / 2 > size.width - padRight) tooltipX = size.width - padRight - boxWidth / 2;

    // Đẩy tooltip lên cao hơn một chút để không che khuất cái Badge (ảnh)
    final tooltipBottomY = p.dy - 24; 
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX - boxWidth / 2, tooltipBottomY - textPainter.height - 12, boxWidth, textPainter.height + 12),
      const Radius.circular(8)
    );
    
    canvas.drawShadow(Path()..addRRect(boxRect), Colors.black, 6, false);
    canvas.drawRRect(boxRect, Paint()..color = colorScheme.onSurface);
    
    textPainter.paint(canvas, Offset(tooltipX - (textPainter.width / 2), tooltipBottomY - textPainter.height - 6));
  }
  @override
  bool shouldRepaint(covariant _RankTooltipPainter old) => old.selectedIndex != selectedIndex || old.progress != progress;
}

class _HistorySummaryStats extends StatelessWidget {
  final int peakRankId;
  final int upCount;
  final int downCount;
  final int maxStreak;

  const _HistorySummaryStats({
    required this.peakRankId, 
    required this.upCount, 
    required this.downCount,
    required this.maxStreak,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    
    // Giảm khoảng cách (spacing) giữa các card từ 12 xuống 8
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              title: t.rank.stat_peak_rank, 
              value: _translateRankName(RankConfig.getRankById(peakRankId).nameKey), 
              icon: Symbols.crown, 
              color: gymColors.goldRank 
            )),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(
              title: t.rank.stat_max_streak, 
              value: "$maxStreak", 
              icon: Symbols.local_fire_department, 
              color: gymColors.fireHexagon
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatCard(
              title: t.rank.stat_promotions, 
              value: "$upCount", 
              icon: Symbols.trending_up, 
              color: gymColors.success
            )),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(
              title: t.rank.stat_demotions, 
              value: "$downCount", 
              icon: Symbols.trending_down, 
              color: colorScheme.error
            )),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // [FIX] Chuyển đổi sang Layout Ngang (Row) để tiết kiệm tối đa chiều cao
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Background mờ cho Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Cột Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value, 
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title, 
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= COMPONENT PHỤ =================

String _getBadgeAssetPath(int rankId) {
  switch (rankId) {
    case 1: return 'assets/badges/bronze1.webp';
    case 2: return 'assets/badges/bronze2.webp';
    case 3: return 'assets/badges/silver1.webp';
    case 4: return 'assets/badges/silver2.webp';
    case 5: return 'assets/badges/gold1.webp';
    case 6: return 'assets/badges/gold2.webp';
    case 7: return 'assets/badges/gold3.webp';
    case 8: return 'assets/badges/diamond.webp';
    default: return 'assets/badges/bronze1.webp';
  }
}

class _RPTypography extends StatelessWidget {
  final String text;
  final double fontSize;

  const _RPTypography({required this.text, this.fontSize = 18.0});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Text(
      text,
      style: TextStyle(
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        color: primary,
        shadows: [Shadow(color: primary.withValues(alpha: 0.6), blurRadius: 16, offset: const Offset(0, 0))], 
      ),
    );
  }
}


Color _getRankColor(BuildContext context, int rankId) {
  final gymColors = Theme.of(context).gymColors;
  if (rankId <= 2) return gymColors.rankBronze;
  if (rankId <= 4) return gymColors.rankSilver;
  if (rankId <= 7) return gymColors.rankGold;
  return gymColors.rankDiamond;
}

String _translateRankName(String rankKey) {
  return t.translateDynamic(rankKey);
}

class _MiniSeasonCountdownBadge extends StatelessWidget {
  final int cycleStartMillis;

  const _MiniSeasonCountdownBadge({required this.cycleStartMillis});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final endDateMillis = cycleStartMillis + (RankConfig.rollingWindowDays * 24 * 60 * 60 * 1000);

    return GymCountdownText(
      targetMillis: endDateMillis,
      style: const TextStyle(), // Không dùng vì đã override trong builder
      builder: (context, duration) {
        final bool isExpired = duration.inSeconds <= 0;
        final bool isLastDay = duration.inHours < 24;
        
        // [FIX] Đổi màu error khi vào ngày cuối cùng
        final Color textColor = isLastDay ? colorScheme.error : colorScheme.onSurface;

        if (isExpired) {
          return Text(
            t.rank.msg_season_ended,
            style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold),
          );
        }

        final days = duration.inDays;
        final hours = duration.inHours.remainder(24);
        final minutes = duration.inMinutes.remainder(60);

        String text;
        if (days > 0) {
          // [FIX] Cập nhật localization theo yêu cầu, nhớ khai báo namedArgs để truyền số liệu
          text = t.common.time_days_hours_minutes(
            days: days.toString(),
            hours: hours.toString(),
            minutes: minutes.toString(),
          ); 
        } else {
          // [FIX] Cập nhật localization ngày cuối
          text = t.common.time_hours_minutes(
            hours: hours.toString(),
            minutes: minutes.toString(),
          ); 
        }

        return Text(
          text,
          style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}