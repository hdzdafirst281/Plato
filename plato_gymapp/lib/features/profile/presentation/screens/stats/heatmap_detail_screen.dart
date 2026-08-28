import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_drawing/path_drawing.dart';
import 'dart:math' as math;
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import '../../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../../core/designsystem/theme/app_theme.dart'; 
import '../../../../../core/database/enums.dart';
import '../../../../../core/utils/search_utils.dart'; 

import '../../../../workout/data/models/workout_models.dart';
import '../../components/body_path_data.dart';
import '../../../domain/profile_chart_utils.dart';

class _MuscleRenderData {
  final MuscleGroup group;
  final Path path;
  final Rect bounds; 
  _MuscleRenderData(this.group, this.path, this.bounds);
}

class HeatmapDetailScreen extends StatefulWidget {
  final List<WorkoutSession> workouts;
  final void Function() onBack;

  const HeatmapDetailScreen({super.key, required this.workouts, required this.onBack});

  @override
  State<HeatmapDetailScreen> createState() => _HeatmapDetailScreenState();
}

class _HeatmapDetailScreenState extends State<HeatmapDetailScreen> with SingleTickerProviderStateMixin {
  HeatmapMode _activeMode = HeatmapMode.FREQUENCY;

  late AnimationController _animController;
  late Animation<double> _colorFillAnim;
  late Animation<double> _uiOpacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _uiOpacityAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));
    _colorFillAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    GymDialog.showCustom(
      context: context,
      titleWidget: Row(
        children: [
          Icon(Symbols.info, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(t.common.info, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.stats.desc_heatmap_info_general, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.stats.lbl_heatmap_info_frequency_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(t.stats.desc_heatmap_info_frequency, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 0,
              color: colorScheme.secondary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.stats.lbl_heatmap_info_intensity_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(t.stats.desc_heatmap_info_intensity, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(t.common.understood, style: const TextStyle(fontWeight: FontWeight.bold))
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now().millisecondsSinceEpoch;
    final recentWorkouts = widget.workouts.where((w) => w.startTime >= now - (30 * 24 * 60 * 60 * 1000)).toList();

    // REFACTOR: Sử dụng mốc Dynamic Scaling cho Heatmap
    final rawIntensityScores = ProfileChartUtils.calculateDetailedMuscleScores(recentWorkouts);
    final intensityStats = rawIntensityScores.map((k, v) {
      final optimalVol = ProfileChartUtils.getHeatmapOptimalVolume(k);
      double normalizedScore = (v / optimalVol).clamp(0.0, 1.0);
      return MapEntry(k, normalizedScore);
    });

    final frequencyStats = ProfileChartUtils.calculateWeeklyCoverage(widget.workouts);
    final displayStats = _activeMode == HeatmapMode.INTENSITY ? intensityStats : frequencyStats;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.stats.title_card_body_heatmap,
        onBackClick: widget.onBack,
        actions: [
          IconButton(
            icon: Icon(Symbols.info, color: colorScheme.primary), 
            onPressed: () => _showInfoDialog(context),
          )
        ],
      ),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000), 
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 300) {
                setState(() => _activeMode = HeatmapMode.FREQUENCY);
              } else if (details.primaryVelocity! < -300) {
                setState(() => _activeMode = HeatmapMode.INTENSITY);
              }
            },
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _uiOpacityAnim.value,
                  child: _BodyHeatmap(
                    muscleIntensities: displayStats,
                    mode: _activeMode,
                    onModeChanged: (m) => setState(() => _activeMode = m),
                    animationProgress: _colorFillAnim.value, 
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyHeatmap extends StatefulWidget {
  final Map<MuscleGroup, double> muscleIntensities;
  final HeatmapMode mode;
  final Function(HeatmapMode) onModeChanged;
  final double animationProgress; 

  const _BodyHeatmap({
    required this.muscleIntensities, 
    required this.mode, 
    required this.onModeChanged,
    required this.animationProgress, 
  });

  @override
  State<_BodyHeatmap> createState() => _BodyHeatmapState();
}

class _BodyHeatmapState extends State<_BodyHeatmap> {
  MuscleGroup? _selectedMuscle;
  
  late final Path frontBorderPath;
  late final Path rearBorderPath;
  late final Path frontSkinPath;
  late final Path rearSkinPath;
  late final List<_MuscleRenderData> frontMuscles;
  late final List<_MuscleRenderData> rearMuscles;
  
  late final Rect frontBounds;
  late final Rect rearBounds;
  late final double maxSvgWidth;
  late final double maxSvgHeight;

  @override
  void initState() {
    super.initState();
    frontBorderPath = parseSvgPathData(BodyPathData.frontBorder);
    rearBorderPath = parseSvgPathData(BodyPathData.rearBorder);
    frontSkinPath = parseSvgPathData(BodyPathData.frontSkin);
    rearSkinPath = parseSvgPathData(BodyPathData.rearSkin);

    frontMuscles = BodyPathData.frontMuscles.entries.map((e) {
      final p = parseSvgPathData(e.value);
      return _MuscleRenderData(e.key, p, p.getBounds());
    }).toList();

    rearMuscles = BodyPathData.backMuscles.entries.map((e) {
      final p = parseSvgPathData(e.value);
      return _MuscleRenderData(e.key, p, p.getBounds());
    }).toList();

    frontBounds = frontBorderPath.getBounds();
    rearBounds = rearBorderPath.getBounds();
    maxSvgWidth = math.max(frontBounds.width, rearBounds.width);
    maxSvgHeight = math.max(frontBounds.height, rearBounds.height);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscapeOrTablet = orientation == Orientation.landscape || MediaQuery.of(context).size.width > 600;

        // CHẾ ĐỘ LANDSCAPE: An toàn do không dùng cơ chế cuộn ép intrinsics
        if (isLandscapeOrTablet) {
          return Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest, 
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]
                        ),
                        child: _BetterSegmentedControl(currentMode: widget.mode, onModeChanged: widget.onModeChanged)
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: Text(
                        _selectedMuscle?.getLocalizedName() ?? t.stats.lbl_heatmap_select_muscle_prompt, 
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: _selectedMuscle != null ? colorScheme.primary : colorScheme.onSurfaceVariant
                        )
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HeatmapLegend(mode: widget.mode),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.mode == HeatmapMode.INTENSITY 
                            ? t.stats.lbl_heatmap_timeframe_intensity 
                            : t.stats.lbl_heatmap_timeframe_frequency,
                        key: ValueKey(widget.mode),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _MuscleSelectorSection(selected: _selectedMuscle, onSelect: (m) => setState(() => _selectedMuscle = m)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(child: _buildCanvas(isFront: true)),
                    Expanded(child: _buildCanvas(isFront: false)),
                  ],
                ),
              )
            ],
          );
        }

        // CHẾ ĐỘ PORTRAIT: FIX CRASH - Sử dụng SingleChildScrollView thay cho SliverFillRemaining
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest, 
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]
                  ),
                  child: _BetterSegmentedControl(currentMode: widget.mode, onModeChanged: widget.onModeChanged)
                ),
              ),
              SizedBox(
                height: 30,
                child: Text(
                  _selectedMuscle?.getLocalizedName() ?? t.stats.lbl_heatmap_select_muscle_prompt, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: _selectedMuscle != null ? colorScheme.primary : colorScheme.onSurfaceVariant
                  )
                ),
              ),
              
              // Sử dụng SizedBox giới hạn chiều cao tĩnh, không bị vướng intrinsic calculations
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Row(
                  children: [
                    Expanded(child: _buildCanvas(isFront: true)),
                    Expanded(child: _buildCanvas(isFront: false)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _HeatmapLegend(mode: widget.mode, key: ValueKey(widget.mode)),
              ),
              
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.mode == HeatmapMode.INTENSITY 
                      ? t.stats.lbl_heatmap_timeframe_intensity 
                      : t.stats.lbl_heatmap_timeframe_frequency,
                  key: ValueKey('timeframe_${widget.mode}'),
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.only(bottom: 24), 
                child: _MuscleSelectorSection(selected: _selectedMuscle, onSelect: (m) => setState(() => _selectedMuscle = m)),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCanvas({required bool isFront}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;

        final scaleX = canvasWidth / maxSvgWidth;
        final scaleY = canvasHeight / maxSvgHeight;
        final finalDrawScale = math.min(scaleX, scaleY);

        final targetBounds = isFront ? frontBounds : rearBounds;
        final canvasTranslateX = (canvasWidth / 2) - (targetBounds.center.dx * finalDrawScale);
        final canvasTranslateY = (canvasHeight / 2) - (targetBounds.center.dy * finalDrawScale);

        final musclesToRender = isFront ? frontMuscles : rearMuscles;

        return GestureDetector(
          onTapDown: (details) {
            final unscaledSvgX = (details.localPosition.dx - canvasTranslateX) / finalDrawScale;
            final unscaledSvgY = (details.localPosition.dy - canvasTranslateY) / finalDrawScale;
            final tapPoint = Offset(unscaledSvgX, unscaledSvgY);

            final hitMuscles = musclesToRender.where((m) => m.path.contains(tapPoint));
            final hitMuscle = hitMuscles.isNotEmpty ? hitMuscles.first : null;
            
            if (hitMuscle != null) {
              setState(() => _selectedMuscle = _selectedMuscle == hitMuscle.group ? null : hitMuscle.group);
            } else {
              setState(() => _selectedMuscle = null);
            }
          }, 
          child: CustomPaint(
            painter: _HeatmapPainter(
              borderPath: isFront ? frontBorderPath : rearBorderPath,
              skinPath: isFront ? frontSkinPath : rearSkinPath,
              muscles: musclesToRender,
              intensities: widget.muscleIntensities,
              mode: widget.mode,
              selected: _selectedMuscle,
              colorScheme: Theme.of(context).colorScheme,
              gymColors: Theme.of(context).gymColors, 
              scale: finalDrawScale,
              dx: canvasTranslateX,
              dy: canvasTranslateY,
              animationProgress: widget.animationProgress, 
            ),
            size: Size.infinite,
          ),
        );
      }
    );
  }
}

class _BetterSegmentedControl extends StatelessWidget {
  final HeatmapMode currentMode; 
  final Function(HeatmapMode) onModeChanged;

  const _BetterSegmentedControl({required this.currentMode, required this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final modes = [HeatmapMode.FREQUENCY, HeatmapMode.INTENSITY];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((mode) {
          final isSelected = currentMode == mode;
          final label = mode == HeatmapMode.INTENSITY 
              ? t.stats.lbl_heatmap_mode_intensity 
              : t.stats.lbl_heatmap_mode_frequency;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                onTap: () => onModeChanged(mode),
                borderRadius: BorderRadius.circular(50),
                child: Center(
                  child: Text(
                    label, 
                    style: TextStyle(
                      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                      fontSize: 13
                    )
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SmoothHorizontalScrollbar extends StatelessWidget {
  final ScrollController controller;

  const _SmoothHorizontalScrollbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double progress = 0.0;
        try {
          if (controller.hasClients && controller.position.hasContentDimensions) {
            final maxExtent = controller.position.maxScrollExtent;
            if (maxExtent > 0) {
              progress = (controller.position.pixels / maxExtent).clamp(0.0, 1.0);
            }
          }
        } catch (_) {}

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              if (trackWidth.isInfinite || trackWidth <= 0) return const SizedBox.shrink();

              final thumbWidth = trackWidth * 0.3;
              final maxOffset = trackWidth - thumbWidth;
              final currentOffset = maxOffset * progress;

              return Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
                child: Stack(
                  children: [
                    Positioned(
                      left: currentOffset.isNaN ? 0 : currentOffset,
                      child: Container(
                        width: thumbWidth.isNaN ? 0 : thumbWidth,
                        height: 4,
                        decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MuscleSelectorSection extends StatefulWidget {
  final MuscleGroup? selected;
  final Function(MuscleGroup?) onSelect;

  const _MuscleSelectorSection({required this.selected, required this.onSelect});

  @override
  State<_MuscleSelectorSection> createState() => _MuscleSelectorSectionState();
}

class _MuscleSelectorSectionState extends State<_MuscleSelectorSection> {
  final _frontScrollCtrl = ScrollController();
  final _backScrollCtrl = ScrollController();

  @override
  void dispose() {
    _frontScrollCtrl.dispose();
    _backScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frontList = BodyPathData.frontMuscles.keys.toList();
    final backList = BodyPathData.backMuscles.keys.toList(); 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16), 
          child: Text(t.stats.lbl_heatmap_front_body, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))
        ),
        SingleChildScrollView(
          controller: _frontScrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, right: 0, top: 4, bottom: 4),
          child: Row(children: frontList.map((m) => _MuscleChip(m, widget.selected == m, () => widget.onSelect(widget.selected == m ? null : m))).toList()),
        ),
        _SmoothHorizontalScrollbar(controller: _frontScrollCtrl),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4), 
          child: Text(t.stats.lbl_heatmap_back_body, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))
        ),
        SingleChildScrollView(
          controller: _backScrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, right: 0, top: 4, bottom: 4),
          child: Row(children: backList.map((m) => _MuscleChip(m, widget.selected == m, () => widget.onSelect(widget.selected == m ? null : m))).toList()),
        ),
        _SmoothHorizontalScrollbar(controller: _backScrollCtrl),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final MuscleGroup muscle;
  final bool isSelected;
  final VoidCallback onClick;

  const _MuscleChip(this.muscle, this.isSelected, this.onClick);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => onClick(),
        label: Text(muscle.getLocalizedName(), style: TextStyle(fontSize: 11, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  final HeatmapMode mode;

  const _HeatmapLegend({required this.mode, super.key});

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors; 
    
    if (mode == HeatmapMode.INTENSITY) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(gymColors.heatmapUnused, t.stats.lbl_heatmap_legend_unused),
          const SizedBox(width: 12),
          _LegendItem(gymColors.heatmapLow, t.stats.lbl_heatmap_legend_low),
          const SizedBox(width: 12),
          _LegendItem(gymColors.heatmapMed, t.stats.lbl_heatmap_legend_medium),
          const SizedBox(width: 12),
          _LegendItem(gymColors.heatmapHigh, t.stats.lbl_heatmap_legend_high),
          const SizedBox(width: 12),
          _LegendItem(gymColors.heatmapExtreme, t.stats.lbl_heatmap_legend_extreme),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(gymColors.heatmapUnused, t.stats.lbl_heatmap_legend_unused),
        const SizedBox(width: 16),
        _LegendItem(gymColors.heatmapFreqDone, t.stats.lbl_heatmap_legend_done),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem(this.color, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final Path borderPath;
  final Path skinPath;
  final List<_MuscleRenderData> muscles;
  final Map<MuscleGroup, double> intensities;
  final HeatmapMode mode;
  final MuscleGroup? selected;
  final ColorScheme colorScheme;
  final GymColors gymColors; 
  final double scale;
  final double dx;
  final double dy;
  final double animationProgress; 

  _HeatmapPainter({
    required this.borderPath, 
    required this.skinPath, 
    required this.muscles, 
    required this.intensities, 
    required this.mode, 
    required this.selected, 
    required this.colorScheme,
    required this.gymColors,
    required this.scale,
    required this.dx,
    required this.dy,
    required this.animationProgress, 
  });

  Color _getAnimatedColor(Color targetColor, Color unusedColor) {
    return Color.lerp(unusedColor, targetColor, animationProgress) ?? unusedColor;
  }

  Color _getIntensityColor(double val) {
    if (val <= 0) return Colors.transparent;
    if (val < 0.25) return gymColors.heatmapLow;
    if (val < 0.5) return gymColors.heatmapMed;
    if (val < 0.75) return gymColors.heatmapHigh;
    return gymColors.heatmapExtreme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    canvas.drawPath(borderPath, Paint()..color = gymColors.heatmapBase..style = PaintingStyle.fill);
    canvas.drawPath(borderPath, Paint()..color = gymColors.heatmapBorder..style = PaintingStyle.stroke..strokeWidth = 1 / scale);
    canvas.drawPath(skinPath, Paint()..color = colorScheme.surface..style = PaintingStyle.stroke..strokeWidth = 1 / scale..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    for (var m in muscles) {
      final val = intensities[m.group] ?? 0.0;
      final isSel = selected == m.group;

      Color fill;
      if (val > 0) {
        final targetColor = mode == HeatmapMode.INTENSITY ? _getIntensityColor(val) : gymColors.heatmapFreqDone;
        fill = _getAnimatedColor(targetColor, gymColors.heatmapUnused);
      } else {
        fill = gymColors.heatmapUnused;
      }

      canvas.drawPath(m.path, Paint()..color = fill..style = PaintingStyle.fill);
      canvas.drawPath(m.path, Paint()..color = colorScheme.surface..style = PaintingStyle.stroke..strokeWidth = 1 / scale..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

      if (isSel) {
        canvas.drawPath(
          m.path, 
          Paint()
            ..color = gymColors.heatmapSelected 
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 / scale 
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.mode != mode || 
           oldDelegate.selected != selected || 
           oldDelegate.scale != scale ||
           oldDelegate.animationProgress != animationProgress; 
  }
}