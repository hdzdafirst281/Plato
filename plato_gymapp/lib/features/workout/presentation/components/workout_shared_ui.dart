import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/core/utils/tour_keys.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';

import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import '../../../../core/database/entities.dart';
import '../bloc/active_session_cubit.dart';
import '../screens/exercise_library_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'workout_components.dart';

import 'dart:io';
import 'dart:math';
import 'package:plato_gymapp/features/workout/domain/training_load_manager.dart';
import 'package:plato_gymapp/features/workout/domain/workout_extensions.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_tour_target.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import '../../../../core/database/enums.dart';

// =====================================================================
// 1. SHARED AVATAR
// =====================================================================
class ExerciseAvatar extends StatelessWidget {
  final String displayName;
  final String? imagePath;
  final double size;

  const ExerciseAvatar({
    super.key,
    required this.displayName,
    this.imagePath,
    this.size = 48,
  });

  Widget _buildFallback(ColorScheme colorScheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        displayName.trim().isNotEmpty
            ? displayName.trim()[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imagePath != null && imagePath!.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            imagePath!,
            fit: BoxFit.contain,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
            errorBuilder: (context, error, stackTrace) =>
                _buildFallback(colorScheme),
          ),
        ),
      );
    }
    return _buildFallback(colorScheme);
  }
}

// =====================================================================
// 2. GYM SWIPE TO REVEAL (HEVY STYLE)
// =====================================================================
class GymSwipeToRevealAction extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final bool enabled;

  const GymSwipeToRevealAction({
    super.key,
    required this.child,
    required this.onDelete,
    this.enabled = true,
  });

  @override
  State<GymSwipeToRevealAction> createState() => _GymSwipeToRevealActionState();
}

class _GymSwipeToRevealActionState extends State<GymSwipeToRevealAction>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _sizeController;
  final double _actionWidth = 80.0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      upperBound: double.infinity,
    );
    _sizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _isDeleting) return;
    final delta = -(details.primaryDelta! / _actionWidth);
    final newValue = _controller.value + delta;
    _controller.value = newValue < 0 ? 0.0 : newValue;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enabled || _isDeleting) return;
    if (_controller.value > 0.5 || details.primaryVelocity! < -300) {
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 150));
    } else {
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 150));
    }
  }

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    HapticFeedback.heavyImpact();

    final screenWidth = MediaQuery.of(context).size.width;
    final targetValue = screenWidth / _actionWidth;

    await _controller.animateTo(
      targetValue,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
    await _sizeController.reverse();
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizeTransition(
      sizeFactor: _sizeController,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (_controller.value == 0.0) return const SizedBox.shrink();
                  return SizedBox(
                    width: (_controller.value * _actionWidth) + 24,
                    child: child,
                  );
                },
                child: Material(
                  color: colorScheme.error,
                  child: InkWell(
                    onTap: _handleDelete,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: _actionWidth,
                          child: Center(
                            child: Icon(
                              Symbols.delete,
                              color: colorScheme.onError,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_controller.value * _actionWidth, 0),
                child: child,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 3. WORKOUT EXPANDABLE ACTION FAB (Đem từ components sang)
// =====================================================================
class WorkoutExpandableActionFab extends StatefulWidget {
  final double fabRightOffset;
  final double fabBottomOffset;
  final bool isKeyboardOpen;

  final VoidCallback onAdd;
  final VoidCallback onReorder;
  final VoidCallback onCancel;

  final String? cancelLabel;
  final IconData? cancelIcon;

  final GlobalKey? fabTourKey;
  final String? fabTourTitle;
  final String? fabTourDesc;

  const WorkoutExpandableActionFab({
    super.key,
    required this.fabRightOffset,
    required this.fabBottomOffset,
    required this.isKeyboardOpen,
    required this.onAdd,
    required this.onReorder,
    required this.onCancel,
    this.cancelLabel,
    this.cancelIcon,
    this.fabTourKey,
    this.fabTourTitle,
    this.fabTourDesc,
  });

  @override
  State<WorkoutExpandableActionFab> createState() =>
      _WorkoutExpandableActionFabState();
}

class _WorkoutExpandableActionFabState extends State<WorkoutExpandableActionFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didUpdateWidget(covariant WorkoutExpandableActionFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isKeyboardOpen && !oldWidget.isKeyboardOpen && _isOpen) _close();
  }

  void _toggle() => _isOpen ? _close() : _open();
  void _open() {
    setState(() => _isOpen = true);
    _animController.forward();
  }

  void _close() => _animController.reverse().then((_) {
    if (mounted) setState(() => _isOpen = false);
  });

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
              shadows: [
                Shadow(
                  color: colorScheme.surface,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 50,
            height: 50,
            child: FloatingActionButton(
              heroTag: null,
              shape: CircleBorder(
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: color,
              elevation: 2,
              onPressed: () {
                _close();
                onTap();
              },
              child: Icon(icon),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget mainFab = FloatingActionButton(
      heroTag: null,
      shape: const CircleBorder(),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 6,
      onPressed: _toggle,
      child: AnimatedRotation(
        turns: _isOpen ? 0.125 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: const Icon(Symbols.add, size: 28),
      ),
    );

    if (widget.fabTourKey != null &&
        widget.fabTourTitle != null &&
        widget.fabTourDesc != null) {
      mainFab = GymTourTarget(
        tourKey: widget.fabTourKey!,
        title: widget.fabTourTitle!,
        description: widget.fabTourDesc!,
        customShapeBorder: const CircleBorder(),
        targetPadding: EdgeInsets.zero,
        child: mainFab,
      );
    }

    return Stack(
      children: [
        if (_isOpen || _animController.isAnimating)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5 * _animController.value,
                    sigmaY: 5 * _animController.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.2 * _animController.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          bottom: widget.fabBottomOffset,
          right: widget.fabRightOffset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizeTransition(
                sizeFactor: _animController,
                axisAlignment: 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildOption(
                      context: context,
                      label: t.workout.btn_log_add_exercise,
                      icon: Symbols.add,
                      color: colorScheme.primary,
                      onTap: widget.onAdd,
                    ),
                    _buildOption(
                      context: context,
                      label: t.workout.title_routine_create_reorder,
                      icon: Symbols.swap_vert,
                      color: colorScheme.primary,
                      onTap: widget.onReorder,
                    ),
                    _buildOption(
                      context: context,
                      label:
                          widget.cancelLabel ?? t.workout.btn_log_cancel,
                      icon: widget.cancelIcon ?? Icons.close,
                      color: colorScheme.error,
                      onTap: widget.onCancel,
                    ),
                  ],
                ),
              ),
              mainFab,
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// 4. SET TYPE HELPERS (DIALOG & BOTTOM SHEET)
// =====================================================================
class GymSetTypeHelper {
  static void showSetTypeInfoDialog(
    BuildContext context,
    String label,
    String titleKey,
    String descKey,
    Color themeColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    GymDialog.showCustom(
      context: context,
      titleWidget: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.translateDynamic(titleKey),
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        t.translateDynamic(descKey),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 15,
          height: 1.5,
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: themeColor == colorScheme.onSurfaceVariant ? colorScheme.primary : themeColor,
            foregroundColor: colorScheme.surface,
          ),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(
            t.common.understood,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static void showSetTypeBottomSheet(
    BuildContext context,
    SetType currentType,
    int setIndex,
    Function(SetType) onTypeSelected,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildOption(
      SetType type,
      String label,
      String titleKey,
      String descKey,
      Color color,
    ) {
      final isSelected = currentType == type;
      return Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    onTypeSelected(type);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            t.translateDynamic(titleKey),
                            style: TextStyle(
                              color: isSelected ? color : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                height: 56,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => showSetTypeInfoDialog(
                    context,
                    label,
                    titleKey,
                    descKey,
                    color,
                  ),
                  child: Icon(
                    Symbols.info,
                    color: isSelected
                        ? color
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  t.workout.title_select_set_type(set: '${setIndex + 1}'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                height: 1,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildOption(
                        SetType.NORMAL,
                        '${setIndex + 1}',
                        'workout.type_normal',
                        'workout.desc_normal',
                        colorScheme.onSurfaceVariant,
                      ),
                      buildOption(
                        SetType.WARMUP,
                        'W',
                        'workout.type_warmup',
                        'workout.desc_warmup',
                        Theme.of(context).gymColors.warning,
                      ),
                      buildOption(
                        SetType.DROPSET,
                        'D',
                        'workout.type_dropset',
                        'workout.desc_dropset',
                        Theme.of(context).gymColors.accentPurple,
                      ),
                      buildOption(
                        SetType.FAILURE,
                        'F',
                        'workout.type_failure',
                        'workout.desc_failure',
                        colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                    ],
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

// =====================================================================
// 5. GYM TIMER HELPER (FORMAT & PICKER)
// =====================================================================
class GymTimerHelper {
  static String formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final formattedMS =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return h > 0 ? '$h:$formattedMS' : formattedMS;
  }

  static String formatCardioTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatRestTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s == 0) return '${m}m';
    if (m > 0) {
      return t.common.time_m_s(m: m.toString(), s: s.toString());
    }
    return t.common.time_s(s: s.toString());
  }

  static void showRestTimePicker(
    BuildContext context,
    int currentRest,
    ValueChanged<int> onSave,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final options = List.generate(21, (i) => i * 15);
    int selectedIndex = options.indexOf(currentRest);
    if (selectedIndex == -1) selectedIndex = 0;
    int tempSelected = options[selectedIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 250,
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        t.common.cancel,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      t.workout.title_rest_time,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onSave(tempSelected);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        t.common.save,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                height: 1,
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) =>
                        tempSelected = options[index],
                    children: options
                        .map(
                          (sec) => Center(
                            child: Text(
                              sec == 0
                                  ? t.workout.label_rest_off
                                  : formatRestTime(sec),
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showDurationPicker({
    required BuildContext context,
    required int currentDuration,
    required bool isWarmupEx,
    required String? Function(int) validator,
    required ValueChanged<int> onSave,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    final colorScheme = Theme.of(context).colorScheme;
    Duration initialTimer = Duration(seconds: currentDuration);

    if (isWarmupEx && initialTimer.inHours > 0) {
      initialTimer = Duration(
        minutes: initialTimer.inMinutes % 60,
        seconds: initialTimer.inSeconds % 60,
      );
    }

    bool hasInteracted = false;

    // Helper for composite picker
    Widget buildPickerColumn(
      String label,
      int itemCount,
      int initialItem,
      ValueChanged<int> onChanged,
      String Function(int) textMapper,
    ) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: initialItem),
                itemExtent: 40,
                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                  background: colorScheme.primary.withValues(alpha: 0.1),
                ),
                onSelectedItemChanged: onChanged,
                children: List.generate(itemCount, (index) {
                  return Center(
                    child: Text(
                      textMapper(index),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          String? currentError = validator(initialTimer.inSeconds);
          bool isOpeningWithZeroTime =
              (!hasInteracted && initialTimer.inSeconds == 0);
          bool showRedError = (currentError != null && !isOpeningWithZeroTime);
          
          bool isMobile = ResponsiveBreakpoints.of(ctx).smallerOrEqualTo('MOBILE');

          Widget content = SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          t.common.cancel,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        t.workout.title_select_time,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: currentError != null
                            ? null
                            : () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                onSave(initialTimer.inSeconds);
                                Navigator.pop(ctx);
                              },
                        child: Text(
                          t.common.save,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentError != null
                                ? colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  )
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  height: 1,
                ),
                if (showRedError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.error_outline,
                          color: colorScheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentError,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ).animate().fade().slideY(begin: -0.2, end: 0),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: SizedBox(
                    height: 150, // Strict height to avoid excessive padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isWarmupEx)
                          buildPickerColumn(
                            'h',
                            24,
                            initialTimer.inHours,
                            (val) => setModalState(() {
                              hasInteracted = true;
                              initialTimer = Duration(
                                hours: val,
                                minutes: initialTimer.inMinutes % 60,
                                seconds: initialTimer.inSeconds % 60,
                              );
                            }),
                            (val) => '$val', // Removes leading zero
                          ),
                        buildPickerColumn(
                          'm',
                          60,
                          initialTimer.inMinutes % 60,
                          (val) => setModalState(() {
                            hasInteracted = true;
                            initialTimer = Duration(
                              hours: !isWarmupEx ? initialTimer.inHours : 0,
                              minutes: val,
                              seconds: initialTimer.inSeconds % 60,
                            );
                          }),
                          (val) => val.toString().padLeft(2, '0'),
                        ),
                        buildPickerColumn(
                          's',
                          60,
                          initialTimer.inSeconds % 60,
                          (val) => setModalState(() {
                            hasInteracted = true;
                            initialTimer = Duration(
                              hours: !isWarmupEx ? initialTimer.inHours : 0,
                              minutes: initialTimer.inMinutes % 60,
                              seconds: val,
                            );
                          }),
                          (val) => val.toString().padLeft(2, '0'),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(delay: 50.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutCubic),
                SizedBox(height: isMobile ? 48 : 16),
              ],
            ).animate().fade(duration: 250.ms),
          );

          if (ResponsiveBreakpoints.of(ctx).equals('NARROW_MOBILE')) {
            content = ResponsiveScaledBox(
              width: 360,
              child: content,
            );
          }

          return SafeArea(
            bottom: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: content,
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// 6. WORKOUT SUPERSET BOTTOM SHEET (SHARED)
// =====================================================================
class WorkoutSupersetBottomSheet extends StatefulWidget {
  final List<WorkoutExercise> allExercises;
  final WorkoutExercise baseExercise;
  final Function(List<String> selectedIds) onSave;

  const WorkoutSupersetBottomSheet({
    super.key,
    required this.allExercises,
    required this.baseExercise,
    required this.onSave,
  });

  @override
  State<WorkoutSupersetBottomSheet> createState() =>
      _WorkoutSupersetBottomSheetState();
}

class _WorkoutSupersetBottomSheetState
    extends State<WorkoutSupersetBottomSheet> {
  late final List<WorkoutExercise> _baseExercises;
  late final Map<String, List<WorkoutExercise>> _groupedTargets;

  final List<String> _selectedIds = [];
  String? _targetMergeSupersetId;
  String _warningMsg = "";

  @override
  void initState() {
    super.initState();
    _baseExercises = widget.baseExercise.supersetId != null
        ? widget.allExercises
              .where((e) => e.supersetId == widget.baseExercise.supersetId)
              .toList()
        : [widget.baseExercise];

    _groupedTargets = {};
    for (var ex in widget.allExercises) {
      if (_baseExercises.any((base) => base.id == ex.id)) continue;
      final key = ex.supersetId ?? ex.id;
      _groupedTargets.putIfAbsent(key, () => []).add(ex);
    }
  }

  String _formatNames(List<WorkoutExercise> exs) {
    return exs
        .map(
          (e) => t.translateDynamic(e.exercise.name),
        )
        .join(' & ');
  }

  // [FIX CHÍNH]: Hỗ trợ Multi-select và Cộng dồn Limit
  void _handleSelectGroup(List<WorkoutExercise> groupExs) {
    HapticFeedback.lightImpact();
    final isCurrentlySelected = _selectedIds.contains(groupExs.first.id);

    if (isCurrentlySelected) {
      // Bá» chá»n (Unselect)
      setState(() {
        _selectedIds.removeWhere((id) => groupExs.any((e) => e.id == id));
        // Nếu bỏ chọn chính cái nhóm superset đang định gộp, thì clear target id
        if (groupExs.first.supersetId != null &&
            _targetMergeSupersetId == groupExs.first.supersetId) {
          _targetMergeSupersetId = null;
        }
        _warningMsg = "";
      });
    } else {
      // Proactive Validation: Cộng dồn Base + Đã chọn + Sắp chọn
      if (_baseExercises.length + _selectedIds.length + groupExs.length > 3) {
        HapticFeedback.heavyImpact();
        setState(
          () => _warningMsg = t.workout.msg_superset_limit_proactive,
        );
        return;
      }

      // Chọn thêm (Select/Accumulate)
      setState(() {
        _selectedIds.addAll(groupExs.map((e) => e.id));
        if (groupExs.first.supersetId != null) {
          _targetMergeSupersetId = groupExs.first.supersetId;
        }
        _warningMsg = "";
      });
    }
  }

  Widget _buildDynamicTitle(ColorScheme colorScheme) {
    final bool baseIsGroup = _baseExercises.length > 1;
    final String baseStr = _formatNames(_baseExercises);

    String titleKey;

    // Xác định Title Key dựa trên State
    if (_selectedIds.isEmpty) {
      titleKey = baseIsGroup
          ? 'workout.title_expand_superset'
          : 'workout.title_create_superset';
    } else {
      final bool targetIsGroup = _targetMergeSupersetId != null;
      if (!baseIsGroup && !targetIsGroup) {
        titleKey = 'workout.title_superset_create_new';
      } else if (!baseIsGroup && targetIsGroup) {
        titleKey = 'workout.title_superset_add_to_group';
      } else {
        titleKey = 'workout.title_superset_expand_base';
      }
    }

    // 1. Lấy chuỗi raw từ JSON (chưa được thay thế tham số)
    final String rawTemplate = t.translateDynamic(titleKey);

    final selectedExs = widget.allExercises
        .where((e) => _selectedIds.contains(e.id))
        .toList();
    final String targetStr = _formatNames(selectedExs);

    // 2. Định nghĩa Styles
    final defaultStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.4,
    );
    final highlightStyle = TextStyle(
      color: Theme.of(context).gymColors.accentTeal,
      fontSize: 16,
      fontWeight: FontWeight.w900,
      height: 1.4,
    );

    List<TextSpan> spans = [];

    // 3. Mini Parser: Tìm và tách chính xác {base} và {targets} để tô màu
    rawTemplate.splitMapJoin(
      RegExp(r'(\{base\}|\{targets\})'),
      onMatch: (Match match) {
        final token = match.group(0);
        if (token == '{base}') {
          spans.add(TextSpan(text: baseStr, style: highlightStyle));
        } else if (token == '{targets}') {
          spans.add(TextSpan(text: targetStr, style: highlightStyle));
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        if (nonMatch.isNotEmpty) {
          spans.add(TextSpan(text: nonMatch, style: defaultStyle));
        }
        return '';
      },
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t.common.cancel,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildDynamicTitle(colorScheme),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            widget.onSave(_selectedIds);
                            Navigator.pop(context);
                          },
                    child: Text(
                      t.common.save,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedIds.isEmpty
                            ? colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              )
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              height: 1,
            ),

            if (_warningMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.error, color: colorScheme.error, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _warningMsg,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.2, end: 0),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _groupedTargets.length,
                itemBuilder: (context, i) {
                  final groupKey = _groupedTargets.keys.elementAt(i);
                  final groupExs = _groupedTargets[groupKey]!;

                  final bool isSelected = _selectedIds.contains(
                    groupExs.first.id,
                  );
                  final bool hasSuperset = groupExs.length > 1;

                  // [FIX CHÍNH]: Validation Opacity cũng phải tính toán cộng dồn
                  final bool exceedsLimit =
                      (_baseExercises.length +
                              _selectedIds.length +
                              groupExs.length >
                          3) &&
                      !isSelected;

                  final Color cardBg = isSelected
                      ? Theme.of(
                          context,
                        ).gymColors.accentTeal.withValues(alpha: 0.1)
                      : colorScheme.surface;
                  final Color cardBorder = isSelected
                      ? Theme.of(context).gymColors.accentTeal
                      : (hasSuperset
                            ? Theme.of(
                                context,
                              ).gymColors.accentTeal.withValues(alpha: 0.3)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.2,
                              ));

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: exceedsLimit ? 0.4 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _handleSelectGroup(groupExs),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              border: Border.all(
                                color: cardBorder,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (hasSuperset)
                                  Container(
                                    width: 6,
                                    height: groupExs.length * 40.0,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).gymColors.accentTeal,
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                            left: Radius.circular(10),
                                          ),
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: groupExs.map((ex) {
                                        final isLast = ex == groupExs.last;
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: isLast ? 0 : 8.0,
                                          ),
                                          child: Text(
                                            t.translateDynamic(ex.exercise.name),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                              fontSize: 15,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  // Hiển thị dạng Checkbox linh hoạt cho cả single và multi select
                                  child: isSelected
                                      ? Icon(
                                          Symbols.check_box,
                                          color: Theme.of(
                                            context,
                                          ).gymColors.accentTeal,
                                          size: 24,
                                          fill: 1.0,
                                        )
                                      : Icon(
                                          hasSuperset
                                              ? Symbols.link
                                              : Symbols.check_box_outline_blank,
                                          color: hasSuperset
                                              ? Theme.of(
                                                  context,
                                                ).gymColors.accentTeal
                                              : colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.5),
                                          size: 24,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// MOVED FROM LOG WORKOUT SCREEN
// =====================================================================

class ActiveExerciseCard extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final int exerciseIndex;
  final ActiveSessionCubit activeSessionCubit;
  final bool isReorderMode;

  const ActiveExerciseCard({
    super.key, 
    required this.workoutExercise, 
    required this.exerciseIndex, 
    required this.activeSessionCubit,
    required this.isReorderMode,
  });

  @override
  State<ActiveExerciseCard> createState() => ActiveExerciseCardState();
}

class ActiveExerciseCardState extends State<ActiveExerciseCard> with AutomaticKeepAliveClientMixin {
  List<ExerciseSet> _pastSetsForThisEx = [];
  List<ExerciseSet> _allPastSetsForThisEx = [];
  SafetyCheckResult? _proactiveSafetyResult;
  
  static bool _isPRPopupShowing = false;
  final Map<String, String> _setErrors = {};

  final Map<String, int> _liveTimerValues = {};
  final Map<String, bool> _liveTimerRunning = {};
  final Map<String, bool> _previousCompletionState = {};
  final Map<String, List<ExerciseMetric>> _previousPRs = {};
  final Map<String, List<ExerciseMetric>> _cachedPRs = {};

  late TextEditingController _noteController;
  late FocusNode _noteFocusNode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _computeHistoryAndSafety();

    final initialNote = widget.workoutExercise.note ?? widget.workoutExercise.exercise.userNote ?? '';
    _noteController = TextEditingController(text: initialNote);
    _noteFocusNode = FocusNode();

    _noteFocusNode.addListener(() {
      if (!_noteFocusNode.hasFocus) {
        String finalNote = _noteController.text;

        if (finalNote.trim().isEmpty) {
          finalNote = "";
          if (_noteController.text.isNotEmpty) {
            _noteController.text = "";
          }
        } else {
          finalNote = finalNote.trim();
          if (_noteController.text != finalNote) {
            _noteController.text = finalNote;
          }
        }

        if (finalNote != (widget.workoutExercise.note ?? '')) {
          widget.activeSessionCubit.updateExerciseNote(widget.workoutExercise.id, finalNote);
        }
      }
    });

    for (var s in widget.workoutExercise.sets) {
      _previousCompletionState[s.id] = s.isCompleted;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _checkAndShowPRAsync(String setId) {
    Future.microtask(() {
      if (!mounted) return;
      
      final latestSession = widget.activeSessionCubit.state.activeWorkout;
      final latestEx = latestSession?.exercises.where((e) => e.id == widget.workoutExercise.id).firstOrNull;
      final latestSet = latestEx?.sets.where((s) => s.id == setId).firstOrNull;
      
      if (latestEx == null || latestSet == null) return;
      
      final achievedPRMetrics = latestEx.getAchievedPRsForSet(_allPastSetsForThisEx, setId);
      final bool wasCompleted = _previousCompletionState[setId] ?? false;
      
      // Cập nhật state nội bộ
      _previousCompletionState[setId] = true;

      if (achievedPRMetrics.isNotEmpty) {
        setState(() => _cachedPRs[setId] = achievedPRMetrics);
        
        final List<ExerciseMetric> pastPRs = _previousPRs[setId] ?? [];
        final bool hasNewPRType = achievedPRMetrics.any((metric) => !pastPRs.contains(metric));
        
        if (!wasCompleted || hasNewPRType) {
           // 1. Ép ẩn bàn phím ngay lập tức để bắt đầu animation IME rút xuống
           FocusManager.instance.primaryFocus?.unfocus();
           
           // 2. [FIX PERF]: Tách biệt hoàn toàn luồng UI.
           // Đợi 450ms để animation của bàn phím (thường mất 300ms) kết thúc HOÀN TOÀN.
                      // Điều này giúp CPU rảnh rỗi để render Lottie mượt mà, triệt tiêu lỗi J<IME_INSETS_ANIMATION>.
           Future.delayed(const Duration(milliseconds: 450), () {
             if (mounted) {
               _showPRPopup(context, achievedPRMetrics); 
             }
           });
        }
        _previousPRs[setId] = List.from(achievedPRMetrics);
      } else {
        if (_cachedPRs.containsKey(setId)) setState(() => _cachedPRs.remove(setId));
      }
    });
  }

  // 🚀 BỔ SUNG: Render avatar linh hoạt cho bài tập thường và Custom Exercise
  Widget _buildExerciseImage(Exercise exercise, double size, String displayName, ColorScheme colorScheme) {
    if (exercise.isCustom && exercise.localImagePath != null && exercise.localImagePath!.trim().isNotEmpty) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
        child: ClipOval(
          child: Image.file(
            File(exercise.localImagePath!),
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
            errorBuilder: (context, error, stackTrace) => _buildFallbackText(size, colorScheme, displayName),
          ),
        ),
      );
    }

    if (exercise.image != null && exercise.image!.trim().isNotEmpty) {
      return Container(
        width: size, height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: ClipOval(
          child: Image.asset(
            exercise.image!,
            fit: BoxFit.contain,
            cacheWidth: (size * 3).round(),
            errorBuilder: (context, error, stackTrace) => _buildFallbackText(size, colorScheme, displayName),
          ),
        ),
      );
    }

    return _buildFallbackText(size, colorScheme, displayName);
  }

  Widget _buildFallbackText(double size, ColorScheme colorScheme, String displayName) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?', 
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.45, color: colorScheme.onSurfaceVariant)
      ),
    );
  }

  String _getMetricLabel(ExerciseMetric metric) {
    switch (metric) {
      case ExerciseMetric.BEST_WEIGHT: return t.stats.label_model_metric_best_weight;
      case ExerciseMetric.ONE_RM: return t.stats.label_model_metric_one_rm;
      case ExerciseMetric.BEST_SET_VOL: return t.stats.label_model_metric_best_set_vol;
      case ExerciseMetric.BEST_TIME: return t.stats.label_model_metric_best_time;
      case ExerciseMetric.BEST_STEPS: return t.stats.label_model_metric_best_steps;
      case ExerciseMetric.LONGEST_DISTANCE: return t.stats.label_model_metric_longest_distance;
      case ExerciseMetric.BEST_REPS: return t.stats.label_model_metric_best_reps;
      case ExerciseMetric.PACE: return t.stats.label_model_metric_pace;
      default: return '';
    }
  }

  bool _handleSetDataChange(String setId, ExerciseType exType, bool currentIsCompleted, {double? weight, int? reps, double? distance, int? steps, int? time, TimerMode? timerMode, bool isCheckAction = false}) {
    final latestSession = widget.activeSessionCubit.state.activeWorkout;
    if (latestSession == null) return false;
    
    // [FIX CRASH]: Thay firstWhere bằng where().firstOrNull để tránh Exception
    final latestEx = latestSession.exercises.where((e) => e.id == widget.workoutExercise.id).firstOrNull;
    final latestSet = latestEx?.sets.where((s) => s.id == setId).firstOrNull;
    
    if (latestSet == null) return false;

    double fillWeight = weight ?? latestSet.weight;
    int fillReps = reps ?? latestSet.reps;
    double fillDistance = distance ?? latestSet.distanceInKm;
    int fillSteps = steps ?? latestSet.steps;
    int fillTime = time ?? latestSet.durationTimeSeconds;

    bool isValid = true;
    String errorValidationKey = "";
    bool isWarmupEx = widget.workoutExercise.exercise.id == 'd85332c1-01e4-4845-9d1d-bb814e36f7d2';

    // 1. DI DỜI VALIDATION VÀO ĐÂY: Chỉ kiểm tra lỗi thời gian khi ấn Checkmark hoặc set đã Done
    if (isCheckAction || currentIsCompleted) {
        int globalWorkoutTimer = widget.activeSessionCubit.state.workoutTimerSeconds;
        int accumulatedOtherTime = 0;
        for (var ex in latestSession.exercises) {
            bool isTimeBased = ex.exercise.type == ExerciseType.TIME_ONLY || ex.exercise.type == ExerciseType.CARDIO_DISTANCE || ex.exercise.type == ExerciseType.CARDIO_STEPS;
            if (!isTimeBased) continue;
            for (var s in ex.sets) {
                if (s.id == setId) continue; 
                if (s.isCompleted && s.durationTimeSeconds > 0) accumulatedOtherTime += s.durationTimeSeconds;
            }
        }
        int maxAllowedTime = globalWorkoutTimer - accumulatedOtherTime;
        if (maxAllowedTime < 0) maxAllowedTime = 0;

        if (exType == ExerciseType.TIME_ONLY || exType == ExerciseType.CARDIO_DISTANCE || exType == ExerciseType.CARDIO_STEPS) {
            // KIỂM TRA TIMER = 0
            if (fillTime <= 0) {
                isValid = false; 
                errorValidationKey = t.workout.err_time_zero; // KEY MỚI
            } 
            // KIỂM TRA ANTI-CHEAT
            else if (fillTime > maxAllowedTime && !isWarmupEx) {
                isValid = false; 
                errorValidationKey = t.workout.err_time_exceed_global; // KEY MỚI
            }
        }
    }

    int globalWorkoutTimer = widget.activeSessionCubit.state.workoutTimerSeconds;
    int accumulatedOtherTime = 0;
    for (var ex in latestSession.exercises) {
        bool isTimeBased = ex.exercise.type == ExerciseType.TIME_ONLY || ex.exercise.type == ExerciseType.CARDIO_DISTANCE || ex.exercise.type == ExerciseType.CARDIO_STEPS;
        if (!isTimeBased) continue;
        for (var s in ex.sets) {
            if (s.id == setId) continue; 
            if (s.durationTimeSeconds > 0) accumulatedOtherTime += s.durationTimeSeconds;
        }
    }
    int maxAllowedTime = globalWorkoutTimer - accumulatedOtherTime;
    if (maxAllowedTime < 0) maxAllowedTime = 0;

    if (exType == ExerciseType.WEIGHT_REPS) {
        if (fillReps <= 0) { isValid = false; errorValidationKey = t.workout.err_invalid_reps; } 
        else if (fillReps > 999) { isValid = false; errorValidationKey = t.workout.err_invalid_reps_max; } 
        else if (fillWeight < 0) { isValid = false; errorValidationKey = t.workout.err_invalid_weight; } 
        else if (fillWeight > 2000.0) { isValid = false; errorValidationKey = t.workout.err_invalid_weight_max; }
    } else if (exType == ExerciseType.REPS_ONLY) {
        if (fillReps <= 0) { isValid = false; errorValidationKey = t.workout.err_invalid_reps; } 
        else if (fillReps > 999) { isValid = false; errorValidationKey = t.workout.err_invalid_reps_max; }
    } else if (exType == ExerciseType.TIME_ONLY) {
        if (fillTime <= 0) { isValid = false; errorValidationKey = t.workout.err_time_zero; }
        else if (isWarmupEx && fillTime >= 3600) { isValid = false; errorValidationKey = t.workout.err_warmup_time_max; }
        else if (fillTime > maxAllowedTime) { isValid = false; errorValidationKey = t.workout.err_time_exceed_global; } 
    } else if (exType == ExerciseType.CARDIO_DISTANCE) {
        if (fillDistance <= 0 || fillTime <= 0) { isValid = false; errorValidationKey = t.workout.err_invalid_distance_time; } 
        else if (fillTime > maxAllowedTime) { isValid = false; errorValidationKey = t.workout.err_time_exceed_global; }
        else {
            double speedKmH = fillDistance / (fillTime / 3600.0);
            if (speedKmH >= 45.0) { isValid = false; errorValidationKey = t.workout.err_invalid_speed_max; }
        }
    } else if (exType == ExerciseType.CARDIO_STEPS) {
        if (fillSteps <= 0 || fillTime <= 0) { isValid = false; errorValidationKey = t.workout.err_invalid_steps_time; }
        else if (fillTime > maxAllowedTime) { isValid = false; errorValidationKey = t.workout.err_time_exceed_global; }
    }

    if (isCheckAction) {
        if (!isValid) {
            setState(() => _setErrors[setId] = errorValidationKey);
            widget.activeSessionCubit.updateSet(widget.workoutExercise.id, setId, false, weight: fillWeight, reps: fillReps, distance: fillDistance, steps: fillSteps, time: fillTime, timerMode: timerMode);
            return false;
        } else {
            _clearError(setId);
            widget.activeSessionCubit.updateSet(widget.workoutExercise.id, setId, true, weight: fillWeight, reps: fillReps, distance: fillDistance, steps: fillSteps, time: fillTime, timerMode: timerMode);
            return true;
        }
    } else {
        if (currentIsCompleted) {
            if (!isValid) {
                setState(() => _setErrors[setId] = errorValidationKey);
                widget.activeSessionCubit.updateSet(
                  widget.workoutExercise.id, setId, false,
                  weight: fillWeight, reps: fillReps, distance: fillDistance, steps: fillSteps, time: fillTime, timerMode: timerMode
                );
                return false;
            } else {
                _clearError(setId);
                widget.activeSessionCubit.updateSet(
                  widget.workoutExercise.id, setId, true, 
                  weight: fillWeight, reps: fillReps, distance: fillDistance, steps: fillSteps, time: fillTime, timerMode: timerMode
                );
                return true;
            }
        } else {
            if (isValid) _clearError(setId);
            
            widget.activeSessionCubit.updateSet(
              widget.workoutExercise.id, setId, false, 
              weight: fillWeight, reps: fillReps, distance: fillDistance, steps: fillSteps, time: fillTime, timerMode: timerMode
            );
            return isValid;
        }
    }
  }

  @override
  void didUpdateWidget(covariant ActiveExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workoutExercise.exercise.id != widget.workoutExercise.exercise.id) {
      _computeHistoryAndSafety();
    }
  }

  void _computeHistoryAndSafety() {
    Future.microtask(() {
      if (!mounted) return;
      final historySessions = context.read<WorkoutCubit>().state.historicalWorkoutSessionsList;
      
      final sortedSessions = List<WorkoutSession>.from(historySessions)
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      List<ExerciseSet> recentSets = [];
      List<ExerciseSet> allPastSets = [];
      bool foundRecent = false;

      for (var session in sortedSessions) {
        final ex = session.exercises.where((e) => e.exercise.id == widget.workoutExercise.exercise.id).firstOrNull;
        if (ex != null) {
          final completedSets = ex.sets.where((s) => s.isCompleted).toList();
          
          if (!foundRecent) {
            recentSets = completedSets;
            foundRecent = true;
          }
          allPastSets.addAll(completedSets); 
        }
      }

      final safety = TrainingLoadManager.calculateProactiveSafetyThreshold(
        exerciseId: widget.workoutExercise.exercise.id,
        workoutHistory: historySessions,
      );

      if (mounted) {
        setState(() {
          _pastSetsForThisEx = recentSets;
          _allPastSetsForThisEx = allPastSets;
          _proactiveSafetyResult = safety;

          // [FIX TÍNH NĂNG]: Quét lại PR cho các set đã hoàn thành khi khởi tạo/load draft
          for (var set in widget.workoutExercise.sets) {
            if (set.isCompleted) {
              final achievedPRs = widget.workoutExercise.getAchievedPRsForSet(_allPastSetsForThisEx, set.id);
              if (achievedPRs.isNotEmpty) {
                _cachedPRs[set.id] = achievedPRs;
                _previousPRs[set.id] = List.from(achievedPRs);
              }
            }
          }
        });
      }
    });
  }

  void _clearError(String setId) {
    if (_setErrors.containsKey(setId)) {
      setState(() => _setErrors.remove(setId));
    }
  }

  String _fmtDouble(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

  String _formatHistoryString(ExerciseSet? previousSet, ExerciseType exType) {
    if (previousSet == null) return "-";
    
    final w = _fmtDouble(previousSet.weight);
    final r = previousSet.reps.toString();
    final d = _fmtDouble(previousSet.distanceInKm);
    final st = previousSet.steps.toString();
    final timeStr = GymTimerHelper.formatCardioTime(previousSet.durationTimeSeconds);

    switch (exType) {
      case ExerciseType.WEIGHT_REPS:
        if (previousSet.weight == 0 && previousSet.reps == 0) return "-";
        return "${w}kg x $r";
      case ExerciseType.REPS_ONLY:
        if (previousSet.reps == 0) return "-";
        return "x $r";
      case ExerciseType.TIME_ONLY:
        if (previousSet.durationTimeSeconds == 0) return "-";
        return timeStr;
      case ExerciseType.CARDIO_DISTANCE:
        if (previousSet.distanceInKm == 0 && previousSet.durationTimeSeconds == 0) return "-";
        return t.workout.format_detail_set_distance_time(arg1: d, arg2: timeStr);
      case ExerciseType.CARDIO_STEPS:
        if (previousSet.steps == 0 && previousSet.durationTimeSeconds == 0) return "-";
        return t.workout.format_detail_set_steps_time(arg1: st, arg2: timeStr);
      
    }
  }

  void _showSupersetBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = widget.activeSessionCubit.state.activeWorkout!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))
      ),
      builder: (ctx) => WorkoutSupersetBottomSheet(
        allExercises: session.exercises,
        baseExercise: widget.workoutExercise,
        onSave: (selectedIds) {
          widget.activeSessionCubit.linkToSuperset(widget.workoutExercise.id, selectedIds);
        },
      ),
    );
  }

  List<String> _generatePRMessages(ExerciseSet setData, List<ExerciseMetric> achievedPRMetrics, ExerciseType exType) {
    List<String> prDialogMsgs = [];
    if (exType == ExerciseType.WEIGHT_REPS) {
      double maxPastWeight = _allPastSetsForThisEx.isEmpty ? 0.0 : _allPastSetsForThisEx.map((s) => s.weight).reduce(max);
      if (achievedPRMetrics.contains(ExerciseMetric.BEST_WEIGHT)) {
        prDialogMsgs.add(t.workout.pr_best_weight(arg1: _fmtDouble(setData.weight), arg2: _fmtDouble(setData.weight - maxPastWeight)));
      }
      double maxPast1RM = _allPastSetsForThisEx.isEmpty ? 0.0 : _allPastSetsForThisEx.map((s) => s.weight * (1 + s.reps / 30.0)).reduce(max);
      double current1RM = setData.weight * (1 + setData.reps / 30.0);
      if (achievedPRMetrics.contains(ExerciseMetric.ONE_RM)) {
        prDialogMsgs.add(t.workout.pr_best_1rm(arg1: _fmtDouble(current1RM), arg2: _fmtDouble(current1RM - maxPast1RM)));
      }
      double maxPastVol = _allPastSetsForThisEx.isEmpty ? 0.0 : _allPastSetsForThisEx.map((s) => s.weight * s.reps).reduce(max);
      double currentVol = setData.weight * setData.reps;
      if (achievedPRMetrics.contains(ExerciseMetric.BEST_SET_VOL)) {
        prDialogMsgs.add(t.workout.pr_best_volume(arg1: _fmtDouble(currentVol), arg2: _fmtDouble(currentVol - maxPastVol)));
      }
    } else if (exType == ExerciseType.REPS_ONLY) {
      int maxPastReps = _allPastSetsForThisEx.isEmpty ? 0 : _allPastSetsForThisEx.map((s) => s.reps).reduce(max);
      if (achievedPRMetrics.contains(ExerciseMetric.BEST_REPS)) {
        prDialogMsgs.add(t.workout.pr_best_reps(arg1: setData.reps.toString(), arg2: (setData.reps - maxPastReps).toString()));
      }
    } else if (exType == ExerciseType.TIME_ONLY) {
      int maxPastTime = _allPastSetsForThisEx.isEmpty ? 0 : _allPastSetsForThisEx.map((s) => s.durationTimeSeconds).reduce(max);
      if (achievedPRMetrics.contains(ExerciseMetric.BEST_TIME)) {
        prDialogMsgs.add(t.workout.pr_longest_time(arg1: GymTimerHelper.formatCardioTime(setData.durationTimeSeconds), arg2: GymTimerHelper.formatCardioTime(setData.durationTimeSeconds - maxPastTime)));
      }
    } else if (exType == ExerciseType.CARDIO_DISTANCE) {
      double maxPastDist = _allPastSetsForThisEx.isEmpty ? 0.0 : _allPastSetsForThisEx.map((s) => s.distanceInKm).reduce(max);
      if (achievedPRMetrics.contains(ExerciseMetric.LONGEST_DISTANCE)) {
        prDialogMsgs.add(t.workout.pr_longest_distance(arg1: _fmtDouble(setData.distanceInKm), arg2: _fmtDouble(setData.distanceInKm - maxPastDist)));
      }
      int maxPastTimeDist = _allPastSetsForThisEx.isEmpty ? 0 : _allPastSetsForThisEx.map((s) => s.durationTimeSeconds).reduce(max);
      if (achievedPRMetrics.contains(ExerciseMetric.BEST_TIME)) {
        prDialogMsgs.add(t.workout.pr_longest_time(arg1: GymTimerHelper.formatCardioTime(setData.durationTimeSeconds), arg2: GymTimerHelper.formatCardioTime(setData.durationTimeSeconds - maxPastTimeDist)));
      }
      if (achievedPRMetrics.contains(ExerciseMetric.PACE)) {
        double currentPace = setData.distanceInKm / (setData.durationTimeSeconds / 3600.0);
        double maxPastPace = 0.0;
        for (var s in _allPastSetsForThisEx) {
          if (s.durationTimeSeconds > 0 && s.distanceInKm > 0) {
            double p = s.distanceInKm / (s.durationTimeSeconds / 3600.0);
            if (p > maxPastPace) maxPastPace = p;
          }
        }
        prDialogMsgs.add(t.workout.pr_best_pace(arg1: _fmtDouble(currentPace), arg2: _fmtDouble(currentPace - maxPastPace)));
      }
    } else if (exType == ExerciseType.CARDIO_STEPS) {
      int maxPastSteps = _allPastSetsForThisEx.isEmpty ? 0 : _allPastSetsForThisEx.map((s) => s.steps).reduce(max);
      if (achievedPRMetrics.contains(ExerciseMetric.BEST_STEPS)) {
        prDialogMsgs.add(t.workout.pr_most_steps(arg1: setData.steps.toString(), arg2: (setData.steps - maxPastSteps).toString()));
      }
      int maxPastTimeSteps = _allPastSetsForThisEx.isEmpty ? 0 : _allPastSetsForThisEx.map((s) => s.durationTimeSeconds).reduce(max);
      if (achievedPRMetrics.contains(ExerciseMetric.BEST_TIME)) {
        prDialogMsgs.add(t.workout.pr_longest_time(arg1: GymTimerHelper.formatCardioTime(setData.durationTimeSeconds), arg2: GymTimerHelper.formatCardioTime(setData.durationTimeSeconds - maxPastTimeSteps)));
      }
    }
    return prDialogMsgs;
  }

  void _showPRPopup(BuildContext context, List<ExerciseMetric> metrics) async {
    
    if (_isPRPopupShowing) return;
    _isPRPopupShowing = true;
    
    final colorScheme = Theme.of(context).colorScheme;
    
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());

    await showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: 8,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/trophy.json', 
                  width: 160,
                  height: 160,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 4),
                Text(
                  t.workout.title_pr_congrats.toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).gymColors.goldRank,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ...metrics.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.star, color: Theme.of(context).gymColors.goldRank, size: 20, fill:1.0),
                      const SizedBox(width: 8),
                      Text(
                        _getMetricLabel(m),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).gymColors.goldRank,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t.workout.btn_pr_awesome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        ),
      ),
    );
    _isPRPopupShowing = false;
  }

  void _showPRDialog(BuildContext context, List<String> prs) {
    final colorScheme = Theme.of(context).colorScheme;
    
    GymDialog.showCustom(
      context: context,
      titleWidget: Row(
        children: [
          Icon(Symbols.trophy, color: Theme.of(context).gymColors.goldRank, size: 28, fill: 1.0),
          const SizedBox(width: 16), 
          Expanded(child: Text(t.workout.title_pr_congrats, style: TextStyle(color: Theme.of(context).gymColors.goldRank, fontWeight: FontWeight.bold))),
        ]
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: prs.isNotEmpty 
          ? prs.map((pr) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0), 
                    child: Icon(
                      Symbols.check_circle, 
                      color: Theme.of(context).gymColors.success, 
                      size: 18, 
                      fill: 1.0
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pr, 
                      style: TextStyle(
                        color: colorScheme.onSurface, 
                        fontSize: 15,
                        height: 1.4, 
                      )
                    )
                  ),
                ]
              )
            )).toList()
          : [Text(t.workout.msg_new_pr_generic, style: TextStyle(color: colorScheme.onSurface))]
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).gymColors.goldRank, foregroundColor: Colors.black),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(t.workout.btn_pr_awesome, style: const TextStyle(fontWeight: FontWeight.bold))
        )
      ],
    );
  }

  void _openTimePickerSafely(String setId, bool isCompleted, bool isWarmupEx, int ghostTime) {
    FocusManager.instance.primaryFocus?.unfocus();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final latestSession = widget.activeSessionCubit.state.activeWorkout;
      if (latestSession == null) return;
      
      final targetEx = latestSession.exercises.firstWhere((e) => e.id == widget.workoutExercise.id);
      final targetSet = targetEx.sets.firstWhere((s) => s.id == setId);
      
      int initTime = (targetSet.durationTimeSeconds == 0 && !isCompleted) ? ghostTime : targetSet.durationTimeSeconds;
      
      GymTimerHelper.showDurationPicker(
        context: context, 
        currentDuration: initTime, 
        isWarmupEx: isWarmupEx, 
        validator: (fillTime) {
            if (isWarmupEx && fillTime >= 3600) return t.workout.err_warmup_time_max;
            
            if (widget.workoutExercise.exercise.type == ExerciseType.CARDIO_DISTANCE && targetSet.distanceInKm > 0 && fillTime > 0) {
                double speedKmH = targetSet.distanceInKm / (fillTime / 3600.0);
                if (speedKmH >= 45.0) return t.workout.err_invalid_speed_max;
            }
            return null;
        }, 
        onSave: (finalTime) {
            _clearError(setId);
            TimerMode inferredMode = finalTime > 0 ? TimerMode.COUNTDOWN : TimerMode.STOPWATCH;
            _handleSetDataChange(
                setId, widget.workoutExercise.exercise.type, isCompleted, 
                time: finalTime, 
                timerMode: inferredMode
            );
        }
      );
    });
  }

  Widget _buildCompactHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = t.translateDynamic(widget.workoutExercise.exercise.name);
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6))
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
            child: _buildExerciseImage(widget.workoutExercise.exercise, 36.0, displayName, colorScheme),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Text(
                displayName, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Icon(Symbols.drag_handle, color: colorScheme.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final exType = widget.workoutExercise.exercise.type;
    final currentRest = widget.workoutExercise.sets.firstOrNull?.restTimeSeconds ?? 90;
    
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    final double setRowHorizontalPadding = ResponsiveValue<double>(context, defaultValue: 16.0, conditionalValues: [
      Condition.smallerThan(name: TABLET, value: 12.0),
      Condition.smallerThan(name: MOBILE, value: 4.0), 
    ]).value;
    
    final bool isWarmupEx = widget.workoutExercise.exercise.id == 'd85332c1-01e4-4845-9d1d-bb814e36f7d2';
    
    final displayName = t.translateDynamic(widget.workoutExercise.exercise.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, 
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final globalExercises = context.read<ExerciseLibraryCubit>().state.exercises;
                    final fullExercise = globalExercises.firstWhere((e) => e.id == widget.workoutExercise.exercise.id, orElse: () => widget.workoutExercise.exercise);
                    context.pushNamed('exercise_details', extra: fullExercise);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildExerciseImage(widget.workoutExercise.exercise, 48.0, displayName, colorScheme),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayName, 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
              
            Builder(
              builder: (context) {
                final popupMenuWidget = PopupMenuButton<String>(
                  icon: Icon(Symbols.more_vert, color: colorScheme.onSurfaceVariant),
                  color: colorScheme.surface,
                  elevation: 4, 
                  padding: const EdgeInsets.all(4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      widget.activeSessionCubit.removeExercise(widget.exerciseIndex);
                    } else if (value == 'replace') {
                      final globalExercises = context.read<ExerciseLibraryCubit>().state.exercises;
                      final fullExercise = globalExercises.firstWhere(
                        (e) => e.id == widget.workoutExercise.exercise.id, 
                        orElse: () => widget.workoutExercise.exercise
                      );

                      final currentSession = widget.activeSessionCubit.state.activeWorkout;
                      final existingIds = currentSession?.exercises.map((e) => e.exercise.id).toList() ?? [];
                        
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (!context.mounted) return;
                        context.pushNamed('exercise_library', extra: {
                          'mode': LibraryMode.singleSelect,
                          'suggestedMuscle': fullExercise.primaryMuscle,
                          'preSelectedIds': existingIds,
                          'onSelected': (List<Exercise> exs) {
                            if (exs.isNotEmpty) widget.activeSessionCubit.replaceExercise(widget.exerciseIndex, exs.first);
                          }
                        });
                      });
                    } else if (value == 'reorder') {
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (_) => GymReorderDialog<WorkoutExercise>(
                            title: t.workout.title_routine_create_reorder,
                            description: t.workout.desc_reorder_instruction,
                            initialItems: widget.activeSessionCubit.state.activeWorkout!.exercises,
                            itemNameSelector: (item) => t.translateDynamic(item.exercise.name),
                            idSelector: (item) => item.id,
                            onSave: (reordered) {
                              widget.activeSessionCubit.reorderExercises(reordered);
                            },
                          ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0)
                        );
                      });
                    } else if (value == 'superset_add') {
                      _showSupersetBottomSheet(context);
                    } else if (value == 'superset_remove') {
                      widget.activeSessionCubit.removeFromSuperset(widget.workoutExercise.id);
                    }
                  },
                  itemBuilder: (context) {
                    final allExercises = widget.activeSessionCubit.state.activeWorkout?.exercises ?? [];
                    final bool canCreateSuperset = allExercises.length > 1;

                    return [
                      PopupMenuItem(value: 'reorder', child: Row(children: [Icon(Symbols.drag_handle, color: colorScheme.onSurface), const SizedBox(width: 8), Text(t.workout.title_routine_create_reorder, style: TextStyle(color: colorScheme.onSurface))])),
                      PopupMenuItem(value: 'replace', child: Row(children: [Icon(Symbols.swap_horiz, color: colorScheme.onSurface), const SizedBox(width: 8), Text(t.workout.menu_routine_create_replace, style: TextStyle(color: colorScheme.onSurface))])),

                      if (canCreateSuperset && (widget.workoutExercise.supersetId == null || allExercises.where((e) => e.supersetId == widget.workoutExercise.supersetId).length < 3))
                        PopupMenuItem(value: 'superset_add', child: Row(children: [Icon(Symbols.link, color: Theme.of(context).gymColors.accentTeal), const SizedBox(width: 8), Text(t.workout.btn_superset_add, style: TextStyle(color: Theme.of(context).gymColors.accentTeal, fontWeight: FontWeight.bold))])),
                      if (widget.workoutExercise.supersetId != null)
                        PopupMenuItem(value: 'superset_remove', child: Row(children: [Icon(Symbols.link_off, color: Theme.of(context).gymColors.warning), const SizedBox(width: 8), Text(t.workout.btn_superset_remove, style: TextStyle(color: Theme.of(context).gymColors.warning, fontWeight: FontWeight.bold))])),

                      PopupMenuItem(value: 'delete', child: Row(children: [Icon(Symbols.delete, color: colorScheme.error), const SizedBox(width: 8), Text(t.common.delete, style: TextStyle(color: colorScheme.error))])),
                    ];
                  },
                );

                if (widget.exerciseIndex == 0) {
                  return GymTourTarget(
                    tourKey: TourKeys.logWorkoutExerciseOptionsBtn,
                    title: t.tour.log_exercise_options_title,
                    description: t.tour.log_exercise_options_desc,
                    customShapeBorder: const CircleBorder(),
                    targetPadding: EdgeInsets.zero,
                    child: popupMenuWidget,
                  );
                }
                return popupMenuWidget;
              }
            )
          ],
        ),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          GymTimerHelper.showRestTimePicker(
                            context, 
                            currentRest, 
                            (val) => widget.activeSessionCubit.updateExerciseRestTime(widget.workoutExercise.id, val)
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                currentRest == 0 ? Symbols.timer_off : Symbols.timer, 
                                size: 14, 
                                color: colorScheme.primary
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentRest == 0 
                                  ? t.workout.label_rest_off 
                                  : t.workout.format_routine_create_rest_time(arg1: GymTimerHelper.formatRestTime(currentRest)), 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (widget.workoutExercise.supersetId != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).gymColors.accentTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => GymSetTypeHelper.showSetTypeInfoDialog(
                            context, 'S', 'workout.type_superset', 'workout.desc_superset', Theme.of(context).gymColors.accentTeal
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Symbols.link, size: 14, color: Theme.of(context).gymColors.accentTeal),
                                const SizedBox(width: 6),
                                Text(t.workout.label_superset_badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).gymColors.accentTeal)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (_proactiveSafetyResult != null && _proactiveSafetyResult?.dangerWeightThreshold != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).gymColors.warning.withValues(alpha: 0.15), 
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final threshold = _proactiveSafetyResult!.dangerWeightThreshold?.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') ?? '-';
                            GymDialog.showInfo(
                              context: context,
                              title: t.workout.title_safety_warning,
                              message: t.workout.msg_safety_threshold_desc(arg1: threshold),
                              icon: Symbols.health_and_safety,
                              iconColor: Theme.of(context).gymColors.warning,
                              buttonText: t.common.understood,
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Symbols.warning_amber_rounded, size: 14, color: Theme.of(context).gymColors.warning), 
                                const SizedBox(width: 8),
                                Text(
                                  t.workout.label_danger_limit(
                                    weight: _proactiveSafetyResult!.dangerWeightThreshold!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
                                  ), 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).gymColors.warning) 
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
                ],
              )
            ),

            TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              scrollPadding: isTablet ? const EdgeInsets.all(20.0) : const EdgeInsets.only(bottom: 130.0),
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
              maxLines: null, 
              
              keyboardType: TextInputType.multiline, 
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: t.workout.label_note_input,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(Symbols.edit_note, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 26, 
                    minHeight: 20,
                  ),
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),

            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: setRowHorizontalPadding, vertical: 8), 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  SizedBox(width: 32, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(t.workout.col_routine_create_set.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 0.5), textAlign: TextAlign.center))),
                  const SizedBox(width: 16), 
                  
                  Expanded(flex: 3, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(t.workout.col_routine_history, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 0.5), textAlign: TextAlign.center))),
                  const SizedBox(width: 16),

                  if (exType == ExerciseType.TIME_ONLY)
                    Expanded(flex: 4, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(t.workout.col_routine_create_time.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 0.5), textAlign: TextAlign.center)))
                  else ...[
                    if (exType != ExerciseType.REPS_ONLY) ...[
                      Expanded(flex: (exType == ExerciseType.CARDIO_DISTANCE || exType == ExerciseType.CARDIO_STEPS) ? 2 : 3, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(
                        exType == ExerciseType.CARDIO_DISTANCE ? t.workout.col_routine_create_km : 
                        exType == ExerciseType.CARDIO_STEPS ? t.workout.col_routine_create_steps : 
                        t.workout.col_routine_create_kg,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 0.5), textAlign: TextAlign.center
                      ))),
                      const SizedBox(width: 8),
                    ],
                    Expanded(flex: (exType == ExerciseType.CARDIO_DISTANCE || exType == ExerciseType.CARDIO_STEPS) ? 4 : 3, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(
                      (exType == ExerciseType.CARDIO_DISTANCE || exType == ExerciseType.CARDIO_STEPS) ? t.workout.col_routine_create_time.toUpperCase() : t.workout.col_routine_create_reps, 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 0.5), textAlign: TextAlign.center
                    ))),
                  ],
                  const SizedBox(width: 12), 
                  SizedBox(width: 36, child: Icon(Symbols.done_all, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
                ],
              ),
            ),

            ...widget.workoutExercise.sets.map((setData) {
              final setIndex = widget.workoutExercise.sets.indexOf(setData);
              final isCompleted = setData.isCompleted;

              final ExerciseSet? actualHistorySet = _pastSetsForThisEx.length > setIndex ? _pastSetsForThisEx[setIndex] : null;

              ExerciseSet? ghostingSet;
              if (widget.workoutExercise.previousSets.isNotEmpty && setIndex < widget.workoutExercise.previousSets.length) {
                ghostingSet = widget.workoutExercise.previousSets[setIndex];
              } else {
                ghostingSet = actualHistorySet;
              }

              String ghostWeight = "-";
              String ghostReps = "-";
              String ghostDistance = "-";
              String ghostSteps = "-";
              int ghostTime = 0;

              if (ghostingSet != null) {
                ghostWeight = _fmtDouble(ghostingSet.weight);
                ghostReps = ghostingSet.reps > 0 ? ghostingSet.reps.toString() : "-";
                ghostDistance = ghostingSet.distanceInKm > 0 ? _fmtDouble(ghostingSet.distanceInKm) : "-";
                ghostSteps = ghostingSet.steps > 0 ? ghostingSet.steps.toString() : "-";
                ghostTime = ghostingSet.durationTimeSeconds;
              }

              final List<ExerciseMetric> achievedPRMetrics = _cachedPRs[setData.id] ?? [];
              final bool isNewPR = achievedPRMetrics.isNotEmpty;
              final bool isPR = isCompleted && isNewPR;
              
              _previousCompletionState[setData.id] = isCompleted;

              if (!isCompleted && _proactiveSafetyResult?.dangerWeightThreshold != null && exType == ExerciseType.WEIGHT_REPS) {
                // Safety check logic intentionally left but not assigning to unused var
              }

              Color defaultPillColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
              Color finalBgColor = isPR ? Theme.of(context).gymColors.goldRank.withValues(alpha: 0.15) 
                                 : isCompleted ? Theme.of(context).gymColors.success.withValues(alpha: 0.1) 
                                 : defaultPillColor;

              final bool hasError = _setErrors.containsKey(setData.id);
              final String? errorKey = _setErrors[setData.id];

              Border? finalBorder;
              if (hasError) {
                finalBorder = Border.all(color: colorScheme.error, width: 1.5);
              } else if (isPR) {
                finalBorder = Border.all(color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.4), width: 1.5);
              } else if (isCompleted) {
                finalBorder = Border.all(color: Theme.of(context).gymColors.success.withValues(alpha: 0.3), width: 1.5);
              } else {
                finalBorder = Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1.5);
              }

              Widget setCardNode = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GymSwipeToRevealAction(
                        key: ValueKey('swipe_${setData.id}'),
                        enabled: widget.workoutExercise.sets.length > 1, 
                        onDelete: () => widget.activeSessionCubit.removeSet(widget.workoutExercise.id, setData.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: finalBgColor, 
                            borderRadius: BorderRadius.circular(16), 
                            border: finalBorder,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: setRowHorizontalPadding, vertical: 6), 
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Center(
                                    child: Builder(
                                      builder: (context) {
                                        String setTypeLabel = "${setIndex + 1}";
                                        Color setTypeTextColor = colorScheme.onSurfaceVariant;
                                        Color setTypeBgColor = Colors.transparent; 
                                        
                                        switch (setData.type) {
                                          case SetType.WARMUP: 
                                            setTypeLabel = "W"; 
                                            setTypeTextColor = Theme.of(context).gymColors.warning; 
                                            setTypeBgColor = Theme.of(context).gymColors.warning.withValues(alpha: 0.2);
                                            break;
                                          case SetType.DROPSET: 
                                            setTypeLabel = "D"; 
                                            setTypeTextColor = Theme.of(context).gymColors.accentPurple; 
                                            setTypeBgColor = Theme.of(context).gymColors.accentPurple.withValues(alpha: 0.2);
                                            break;
                                          case SetType.FAILURE: 
                                            setTypeLabel = "F"; 
                                            setTypeTextColor = colorScheme.error; 
                                            setTypeBgColor = colorScheme.error.withValues(alpha: 0.2);
                                            break;
                                          case SetType.NORMAL:
                                          default:
                                            setTypeLabel = "${setIndex + 1}";
                                            setTypeTextColor = isCompleted ? Theme.of(context).gymColors.success : colorScheme.onSurfaceVariant;
                                            break;
                                        }

                                        return Container(
                                          width: 32, height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isPR 
                                                 ? Theme.of(context).gymColors.goldRank.withValues(alpha: 0.2) 
                                                 : (isCompleted && setData.type == SetType.NORMAL) 
                                                      ? Theme.of(context).gymColors.success.withValues(alpha: 0.15) 
                                                      : (setTypeBgColor != Colors.transparent ? setTypeBgColor : colorScheme.surface),
                                            shape: BoxShape.circle,
                                          ),
                                          child: isPR 
                                            ? Material(
                                                color: Colors.transparent,
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  customBorder: const CircleBorder(),
                                                  onTap: () {
                                                    final prDialogMsgs = _generatePRMessages(setData, achievedPRMetrics, exType);
                                                    _showPRDialog(context, prDialogMsgs); 
                                                  },
                                                  child: Center(child: Icon(Symbols.trophy, color: Theme.of(context).gymColors.goldRank, size: 16, fill: 1.0)),
                                                ),
                                              )
                                            : Material(
                                                color: Colors.transparent,
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  customBorder: const CircleBorder(),
                                                  onTap: () => GymSetTypeHelper.showSetTypeBottomSheet(
                                                    context, 
                                                    setData.type, 
                                                    setIndex, 
                                                    (newType) {
                                                      widget.activeSessionCubit.updateSet(
                                                        widget.workoutExercise.id, setData.id, setData.isCompleted, type: newType
                                                      );
                                                    }
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      setTypeLabel, 
                                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: setTypeTextColor) 
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        );
                                      }
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16), 
                                
                                Expanded(
                                  flex: 3,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatHistoryString(actualHistorySet, exType),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                    ),
                                  )
                                ),
                                const SizedBox(width: 16),
                                
                                if (exType == ExerciseType.TIME_ONLY) ...[
                                  Expanded(
                                    flex: 4, 
                                    child: CardioTimerRow(
                                      setId: setData.id, exerciseId: widget.workoutExercise.id,
                                      exerciseName: t.translateDynamic(widget.workoutExercise.exercise.name),
                                      initialSeconds: setData.durationTimeSeconds, 
                                      ghostSeconds: ghostTime,
                                      isCompleted: isCompleted, 
                                      isWarmupEx: isWarmupEx,
                                      currentMode: setData.timerMode, // <- Data truyền vào
                                      activeSessionCubit: widget.activeSessionCubit, 
                                      formatTime: GymTimerHelper.formatCardioTime,
                                      onInteraction: () => _clearError(setData.id), 
                                      onTimeTap: () => _openTimePickerSafely(setData.id, isCompleted, isWarmupEx, ghostTime),
                                      onTimerUpdate: (isRunning, seconds, mode) {
                                        _liveTimerRunning[setData.id] = isRunning;
                                        _liveTimerValues[setData.id] = seconds;
                                        // Có thể bổ sung _liveTimerMode nếu cần
                                      },
                                      onTimerComplete: () {
                                        // Tự động kiểm tra Cheat & Tick hoàn thành
                                        HapticFeedback.heavyImpact(); // Rung báo hiệu
                                        bool success = _handleSetDataChange(
                                            setData.id, exType, false, 
                                            weight: setData.weight, reps: setData.reps, 
                                            distance: setData.distanceInKm, steps: setData.steps, 
                                            time: setData.durationTimeSeconds, // Pass target time
                                            timerMode: TimerMode.COUNTDOWN,
                                            isCheckAction: true // ÉP CHẠY VALIDATION ANTI-CHEAT
                                        );
                                        if (success) _checkAndShowPRAsync(setData.id);
                                      },
                                    )
                                  )
                                ] else ...[
                                  if (exType != ExerciseType.REPS_ONLY) ...[
                                    Expanded(
                                      flex: (exType == ExerciseType.CARDIO_DISTANCE || exType == ExerciseType.CARDIO_STEPS) ? 2 : 3,
                                        child: GymExcelCell(
                                          initialValue: exType == ExerciseType.CARDIO_STEPS 
                                              ? (setData.steps > 0 || isCompleted ? setData.steps.toString() : "")
                                              : exType == ExerciseType.CARDIO_DISTANCE
                                                ? (setData.distanceInKm > 0 || isCompleted ? _fmtDouble(setData.distanceInKm) : "")
                                                : ((setData.weight > 0 || isCompleted) ? _fmtDouble(setData.weight) : ""),
                                          placeholder: exType == ExerciseType.CARDIO_STEPS ? ghostSteps
                                              : exType == ExerciseType.CARDIO_DISTANCE ? ghostDistance : ghostWeight,
                                          isInteger: exType == ExerciseType.CARDIO_STEPS,
                                          onChanged: (val) {
                                            if (exType == ExerciseType.CARDIO_STEPS) {
                                              final parsed = int.tryParse(val);
                                              _handleSetDataChange(setData.id, exType, isCompleted, steps: (val.isNotEmpty && parsed == null) ? -1 : (parsed ?? 0));
                                            } else if (exType == ExerciseType.CARDIO_DISTANCE) {
                                              final parsed = double.tryParse(val);
                                              _handleSetDataChange(setData.id, exType, isCompleted, distance: (val.isNotEmpty && parsed == null) ? -1.0 : (parsed ?? 0.0));
                                            } else {
                                              final parsed = double.tryParse(val);
                                              _handleSetDataChange(setData.id, exType, isCompleted, weight: (val.isNotEmpty && parsed == null) ? -1.0 : (parsed ?? 0.0));
                                            }
                                          },
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    flex: (exType == ExerciseType.CARDIO_DISTANCE || exType == ExerciseType.CARDIO_STEPS) ? 4 : 3,
                                    child: (exType == ExerciseType.CARDIO_DISTANCE || exType == ExerciseType.CARDIO_STEPS)
                                    ? CardioTimerRow(
                                        setId: setData.id, exerciseId: widget.workoutExercise.id,
                                        exerciseName: t.translateDynamic(widget.workoutExercise.exercise.name),
                                        initialSeconds: setData.durationTimeSeconds, 
                                        ghostSeconds: ghostTime,
                                        isCompleted: isCompleted, 
                                        isWarmupEx: isWarmupEx,
                                        currentMode: setData.timerMode, // <- Data truyền vào
                                        activeSessionCubit: widget.activeSessionCubit, 
                                        formatTime: GymTimerHelper.formatCardioTime,
                                        onInteraction: () => _clearError(setData.id), 
                                        onTimeTap: () => _openTimePickerSafely(setData.id, isCompleted, isWarmupEx, ghostTime),
                                        onTimerUpdate: (isRunning, seconds, mode) {
                                          _liveTimerRunning[setData.id] = isRunning;
                                          _liveTimerValues[setData.id] = seconds;
                                          // Có thể bổ sung _liveTimerMode nếu cần
                                        },
                                        onTimerComplete: () {
                                          // Tự động kiểm tra Cheat & Tick hoàn thành
                                          HapticFeedback.heavyImpact(); // Rung báo hiệu
                                          bool success = _handleSetDataChange(
                                              setData.id, exType, false, 
                                              weight: setData.weight, reps: setData.reps, 
                                              distance: setData.distanceInKm, steps: setData.steps, 
                                              time: setData.durationTimeSeconds, // Pass target time
                                              timerMode: TimerMode.COUNTDOWN,
                                              isCheckAction: true // ÉP CHẠY VALIDATION ANTI-CHEAT
                                          );
                                          if (success) _checkAndShowPRAsync(setData.id);
                                        },
                                      )
                                    : GymExcelCell(
                                        initialValue: (setData.reps > 0 || isCompleted) ? setData.reps.toString() : "",
                                        placeholder: ghostReps, 
                                        isInteger: true,
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val);
                                          _handleSetDataChange(setData.id, exType, isCompleted, reps: (val.isNotEmpty && parsed == null) ? -1 : (parsed ?? 0));
                                        },
                                      ),
                                  ),
                                ],
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 36,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.heavyImpact(); 
                                        if (isCompleted) {
                                          _clearError(setData.id);
                                          widget.activeSessionCubit.updateSet(
                                            widget.workoutExercise.id, setData.id, false, 
                                            weight: setData.weight, reps: setData.reps, 
                                            distance: setData.distanceInKm, steps: setData.steps, time: setData.durationTimeSeconds
                                          );
                                          if (_cachedPRs.containsKey(setData.id)) {
                                            setState(() => _cachedPRs.remove(setData.id));
                                          }
                                        } else {
                                          FocusManager.instance.primaryFocus?.unfocus();
                                          Future.delayed(const Duration(milliseconds: 150), () {
                                            if (!context.mounted) return;
                                            final latestSession = widget.activeSessionCubit.state.activeWorkout;
                                            if (latestSession == null) return;
                                            final latestSet = latestSession.exercises.firstWhere((e) => e.id == widget.workoutExercise.id).sets.firstWhere((s) => s.id == setData.id);
                                            double fillWeight = latestSet.weight; int fillReps = latestSet.reps;
                                            double fillDistance = latestSet.distanceInKm; int fillSteps = latestSet.steps; 
                                            
                                            bool isRunning = _liveTimerRunning[setData.id] ?? false;
                                            int liveTime = _liveTimerValues[setData.id] ?? 0;
                                            int fillTime = isRunning ? liveTime : latestSet.durationTimeSeconds;
                                            if (ghostingSet != null) {
                                              if (exType == ExerciseType.WEIGHT_REPS) {
                                                if (latestSet.weight == 0) fillWeight = ghostingSet.weight;
                                                if (latestSet.reps == 0) fillReps = ghostingSet.reps;
                                              } else if (exType == ExerciseType.REPS_ONLY) {
                                                if (latestSet.reps == 0) fillReps = ghostingSet.reps;
                                              } else if (exType == ExerciseType.CARDIO_DISTANCE) {
                                                if (latestSet.distanceInKm == 0) fillDistance = ghostingSet.distanceInKm;
                                                if (fillTime == 0 && !isRunning) fillTime = ghostingSet.durationTimeSeconds;
                                              } else if (exType == ExerciseType.CARDIO_STEPS) {
                                                if (latestSet.steps == 0) fillSteps = ghostingSet.steps;
                                                if (fillTime == 0 && !isRunning) fillTime = ghostingSet.durationTimeSeconds;
                                              } else if (exType == ExerciseType.TIME_ONLY) {
                                                if (fillTime == 0 && !isRunning) fillTime = ghostingSet.durationTimeSeconds;
                                              }
                                            }
                                            bool success = _handleSetDataChange(
                                                setData.id, exType, false, 
                                                weight: fillWeight, reps: fillReps, distance: fillDistance, steps: fillSteps, time: fillTime, 
                                                timerMode: latestSet.timerMode, // <-- TRUYỀN timerMode ĐỂ KHÔNG BỊ MẤT
                                                isCheckAction: true
                                            );
                                            if (!success) { 
                                                HapticFeedback.vibrate();
                                            } else {
                                                // Truyền ID để hàm tự lấy data mới nhất
                                                _checkAndShowPRAsync(setData.id);
                                            }
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                        width: 32, height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isPR ? Theme.of(context).gymColors.goldRank : isCompleted ? Theme.of(context).gymColors.success : colorScheme.surface,
                                          shape: BoxShape.circle,
                                          border: !isCompleted ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)) : null,
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            Symbols.check, 
                                            key: ValueKey(isCompleted),
                                            color: isCompleted ? colorScheme.onError : Colors.transparent, 
                                            size: 20
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 16),
                      child: Row(
                        children: [
                          Icon(Symbols.error_outline, color: colorScheme.error, size: 14),
                          const SizedBox(width: 4),
                          Text(t.translateDynamic(errorKey!), style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ).animate().fade().slideY(begin: -0.2, end: 0),
                ],
              ).animate(key: ValueKey(setData.id), delay: (setIndex * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

              if (widget.exerciseIndex == 0 && setIndex == 0) {
                return GymTourTarget(
                  tourKey: TourKeys.logWorkoutSetRow,
                  title: t.tour.log_set_row_title,
                  description: t.tour.log_set_row_desc,
                  tooltipPosition: isTablet ? TooltipPosition.top : null,
                  borderRadius: 16.0,
                  targetPadding: EdgeInsets.zero,
                  child: setCardNode,
                );
              }
              
              return setCardNode;
            }),

            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                    foregroundColor: colorScheme.primary,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16) 
                  ),
                  onPressed: () {
                    // RATE LIMIT CHECKS
                    final currentSession = widget.activeSessionCubit.state.activeWorkout;
                    if (currentSession != null) {
                      int totalSessionSets = currentSession.exercises.fold(0, (sum, ex) => sum + ex.sets.length);
                      if (totalSessionSets >= 100) {
                        GymSnackbar.show(
                          context, 
                          message: t.workout.err_max_sets_session,
                          icon: Symbols.error,
                          accentColor: Theme.of(context).colorScheme.error,
                        );
                        return;
                      }
                    }

                    if (widget.workoutExercise.sets.length >= 30) {
                      GymSnackbar.show(
                        context, 
                        message: t.workout.err_max_sets_exercise,
                        icon: Symbols.error,
                        accentColor: Theme.of(context).colorScheme.error,
                      );
                      return;
                    }

                    widget.activeSessionCubit.addSetToExercise(widget.workoutExercise.id);
                  },
                  icon: const Icon(Symbols.add, size: 18),
                  label: Text(t.workout.btn_routine_create_add_set, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            )
          ],
        )
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: widget.isReorderMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: _buildCompactHeader(context),
        secondChild: _buildFullCard(context),
      ),
    );
  }
}

final ValueNotifier<String?> globalActiveCardioTimerId = ValueNotifier<String?>(null);

class CardioTimerRow extends StatefulWidget {
  final String setId;
  final String exerciseId;
  final String exerciseName;
  final int initialSeconds;
  final int ghostSeconds; 
  final bool isCompleted;
  final bool isWarmupEx; 
  final TimerMode currentMode; 
  final ActiveSessionCubit activeSessionCubit;
  final String Function(int) formatTime;
  final VoidCallback onInteraction;
  final void Function(bool isRunning, int currentSeconds, TimerMode mode) onTimerUpdate;
  final VoidCallback? onTimeTap;
  final VoidCallback onTimerComplete; 

  const CardioTimerRow({
    super.key,
    required this.setId, required this.exerciseId, required this.exerciseName,
    required this.initialSeconds, required this.ghostSeconds, required this.isCompleted, 
    required this.isWarmupEx, required this.currentMode,
    required this.activeSessionCubit, required this.formatTime, required this.onInteraction,
    required this.onTimerUpdate, this.onTimeTap, required this.onTimerComplete,
  });

  @override
  State<CardioTimerRow> createState() => CardioTimerRowState();
}

class CardioTimerRowState extends State<CardioTimerRow> {
  Timer? _timer;
  late ValueNotifier<int> _secondsNotifier;
  bool _isRunning = false;
  late TimerMode _activeMode;
  late int _targetSecondsForCountdown;
  
  // Cờ để gắn Key động khi click (tránh lỗi Duplicate GlobalKey)
  bool _isTourTarget = false;
  
  // Cờ để gắn Key tĩnh khi load lần đầu (cho LogWorkout Screen Tour)
  bool _isInitialTourTarget = false;

  @override
  void initState() {
    super.initState();
    int startVal = (widget.initialSeconds == 0 && widget.ghostSeconds > 0) ? widget.ghostSeconds : widget.initialSeconds;
    _secondsNotifier = ValueNotifier(startVal);
    _activeMode = widget.currentMode;
    _targetSecondsForCountdown = startVal;
    
    globalActiveCardioTimerId.addListener(_onGlobalTimerChanged);
    _checkInitialTourTarget();
  }

  void _checkInitialTourTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = widget.activeSessionCubit.state.activeWorkout;
      if (session != null) {
        for (var ex in session.exercises) {
          final t = ex.exercise.type;
          if (t == ExerciseType.TIME_ONLY || t == ExerciseType.CARDIO_DISTANCE || t == ExerciseType.CARDIO_STEPS) {
            if (ex.id == widget.exerciseId && ex.sets.isNotEmpty && ex.sets.first.id == widget.setId) {
               setState(() => _isInitialTourTarget = true);
            }
            break;
          }
        }
      }
    });
  }

  void _onGlobalTimerChanged() {
    if (globalActiveCardioTimerId.value != widget.setId && _isRunning) {
      _stopTimer(); 
    }
  }

  @override
  void didUpdateWidget(covariant CardioTimerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMode != widget.currentMode) _activeMode = widget.currentMode;
    if (widget.isCompleted && _isRunning) _stopTimer(); 
    if (!_isRunning && oldWidget.initialSeconds != widget.initialSeconds) {
      _secondsNotifier.value = widget.initialSeconds;
      _targetSecondsForCountdown = widget.initialSeconds; 
    }
  }

  // [NEW]: Hàm bao bọc mọi action để check Tour trước khi thực thi
  void _handleTourTrigger(VoidCallback onActionComplete) {
    final tourCubit = context.read<TourCubit>();
    
    final forceShowTour = false; // [DEBUG FLAG]
    if (!tourCubit.state.hasSeenTimerPlayBtn || forceShowTour) {
      // 1. Gắn Key cho riêng Row này
      setState(() => _isTourTarget = true);
      
      // 2. Đợi 150ms để UI (đặc biệt là ShowcaseWidget bên trong GymTourTarget) render và đăng ký Key xong
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        AppRouter.startTour(
          context,
          [TourKeys.logWorkoutTimerPlayBtn],
          onCompleted: () {
            // 3. Chạy xong thì tháo Key, cập nhật Cubit và gọi Action
            if (mounted) setState(() => _isTourTarget = false);
            tourCubit.completeTimerPlayBtnTour();
            onActionComplete();
          }
        );
      });
    } else {
      // Đã xem rồi thì thực thi action ngay lập tức
      onActionComplete();
    }
  }

  void _toggleTimer() {
    if (widget.isCompleted) return;

    // [NEW]: Gắn luồng Tour vào đây
    _handleTourTrigger(() {
      if (_isRunning) {
        _stopTimer();
      } else {
        globalActiveCardioTimerId.value = widget.setId;
        widget.onInteraction(); 
        _isRunning = true;

        widget.onTimerUpdate(true, _secondsNotifier.value, _activeMode);
        
        if (_activeMode == TimerMode.COUNTDOWN) {
           widget.activeSessionCubit.syncCardioCountdownNotification(_secondsNotifier.value, widget.exerciseName, t.workout.status_working);
        }
        
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_activeMode == TimerMode.COUNTDOWN) {
             _secondsNotifier.value--;
             if (_secondsNotifier.value <= 0) {
                _secondsNotifier.value = 0;
                _stopTimer();
                widget.onTimerComplete(); 
                Future.delayed(const Duration(milliseconds: 500), () {
                   if (mounted) _secondsNotifier.value = _targetSecondsForCountdown;
                });
             }
          } else {
             if (widget.isWarmupEx && _secondsNotifier.value >= 3599) {
                 _secondsNotifier.value = 3599;
                 _stopTimer();
                 return;
             }
             _secondsNotifier.value++;
          }
          widget.onTimerUpdate(true, _secondsNotifier.value, _activeMode);
        });
        setState(() {});
      }
    });
  }

  void _stopTimer() {
    if (!_isRunning) return;
    if (globalActiveCardioTimerId.value == widget.setId) globalActiveCardioTimerId.value = null;
    _timer?.cancel();
    _isRunning = false;
    widget.onTimerUpdate(false, _secondsNotifier.value, _activeMode);
    
    setState(() {});
    widget.activeSessionCubit.updateSet(widget.exerciseId, widget.setId, widget.isCompleted, time: _secondsNotifier.value, timerMode: _activeMode);
    widget.activeSessionCubit.syncBackgroundNotification();
  }

  @override
  void dispose() {
    globalActiveCardioTimerId.removeListener(_onGlobalTimerChanged);
    if (globalActiveCardioTimerId.value == widget.setId) globalActiveCardioTimerId.value = null;
    if (_isRunning) widget.activeSessionCubit.updateSet(widget.exerciseId, widget.setId, widget.isCompleted, time: _secondsNotifier.value);
    _timer?.cancel();
    _secondsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // [NEW]: Gom chung Text và Button vào một Row với MainAxisSize.min
    Widget rowContent = Row(
      mainAxisSize: MainAxisSize.min, // Cực kỳ quan trọng để viền Tour ôm khít
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Vùng text đếm giờ (Gắn Tour Trigger)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // [NEW]: Gắn luồng Tour vào hành động Edit Timer
              _handleTourTrigger(() {
                if (_isRunning) _stopTimer();
                widget.onTimeTap?.call();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: ValueListenableBuilder<int>(
                valueListenable: _secondsNotifier,
                builder: (context, val, child) {
                  return Text(
                    widget.formatTime(val), 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)
                  );
                }
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 2. Vùng nút Play (Đã gắn Tour Trigger ở _toggleTimer)
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRunning ? colorScheme.error.withValues(alpha: 0.1) : colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _toggleTimer,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8), 
                child: Icon(
                  _isRunning ? Symbols.pause : Symbols.play_arrow, 
                  size: 20,
                  color: widget.isCompleted ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : (_isRunning ? colorScheme.error : colorScheme.primary),
                  fill: 1.0
                ),
              ),
            ),
          ),
        )
      ],
    );

    // Bọc GymTourTarget. Bọc khi là mục tiêu của initial tour hoặc khi user tap.
    if (_isTourTarget || _isInitialTourTarget) {
      rowContent = GymTourTarget(
        tourKey: TourKeys.logWorkoutTimerPlayBtn,
        title: t.tour.log_timer_play_title,
        description: t.tour.log_timer_play_desc,
        borderRadius: 24.0, // Bo góc cong mượt ôm toàn bộ Row (theo hình minh họa)
        targetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding nhẹ để viền đẹp hơn
        child: rowContent,
      );
    }

    // Đặt FittedBox ngoài cùng để tránh lỗi scale tọa độ của ShowcaseView
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: rowContent,
    );
  }
}

class RestTimerOverlay extends StatelessWidget {
  final int seconds;
  final ActiveSessionCubit activeSessionCubit;

  const RestTimerOverlay({super.key, required this.seconds, required this.activeSessionCubit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final Color barBgColor = colorScheme.onSurface.withValues(alpha: 0.03);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 3), blurRadius: 8)
        ],
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.3), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), 
          child: Container(
            color: barBgColor, 
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    activeSessionCubit.adjustRestTimer(-15);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: colorScheme.surface.withValues(alpha: 0.5),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text('-15s', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                ),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Symbols.timer, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(timeStr, style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)), 
                  ],
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        activeSessionCubit.adjustRestTimer(15);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: colorScheme.surface.withValues(alpha: 0.5),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 40),
                      ),
                      child: Text('+15s', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        activeSessionCubit.skipRestTimer();
                      },
                      icon: const Icon(Symbols.skip_next, size: 24, fill: 1.0),
                      color: colorScheme.onPrimary,
                      style: IconButton.styleFrom(backgroundColor: colorScheme.primary, shape: const CircleBorder()),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}



