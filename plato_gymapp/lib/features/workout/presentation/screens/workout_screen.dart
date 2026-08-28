import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_shake_wrapper.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_shimmer.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_tour_target.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/features/profile/presentation/components/body_path_data.dart';
import 'package:plato_gymapp/features/workout/domain/workout_extensions.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:showcaseview/showcaseview.dart';
import '../../../../core/utils/tour_keys.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../data/models/workout_models.dart';
import '../bloc/workout_cubit.dart';
import '../bloc/editor_cubit.dart';
import '../bloc/active_session_cubit.dart';
import '../components/workout_components.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  Timer? _verticalScrollTimer;
  Timer? _tourDelayTimer;
  final bool forceShowTour = false; // Debug flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerWorkoutTour();
    });
  }

  @override
  void dispose() {
    if (_tourDelayTimer?.isActive ?? false) {
      _tourDelayTimer?.cancel();
      AppRouter.isTourActive.value = false;
    }
    _stopVerticalScroll();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  // 3. Logic cuộn dọc mượt mà 60fps
  void _startVerticalScroll(double dy) {
    if (_verticalScrollTimer != null) return;
    _verticalScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      final newOffset = (currentOffset + dy).clamp(0.0, maxScroll);

      _scrollController.jumpTo(newOffset);

      if (newOffset == 0.0 && dy < 0) _stopVerticalScroll();
      if (newOffset == maxScroll && dy > 0) _stopVerticalScroll();
    });
  }

  void _stopVerticalScroll() {
    _verticalScrollTimer?.cancel();
    _verticalScrollTimer = null;
  }

  void _triggerWorkoutTour() {
    if (!mounted || AppRouter.isTourActive.value) return;

    final tourCubit = context.read<TourCubit>();
    if (tourCubit.state.hasSeenWorkout && !forceShowTour) return;

    AppRouter.isTourActive.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tourDelayTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) {
          AppRouter.isTourActive.value = false;
          return;
        }
        _startTourSafely(tourCubit);
      });
    });
  }

  void _startTourSafely(TourCubit tourCubit) {
    if (!mounted) {
      AppRouter.isTourActive.value = false;
      return;
    }

    final workoutState = context.read<WorkoutCubit>().state;
    final hasFolders =
        workoutState.folderOrder.isNotEmpty ||
        workoutState.userCustomRoutinesList.isNotEmpty;

    final tourKeys = [
      TourKeys.workoutExploreBtn,
      TourKeys.workoutRecoveryChart,
      TourKeys.workoutFolderAddBtn,
      if (hasFolders) TourKeys.workoutFolderHeader,
    ];

    AppRouter.startTour(
      context,
      tourKeys,
      onCompleted: () {
        tourCubit.completeWorkoutTour();
      },
    );
  }

  void _showProgramReorderDialog(List<String> sortedFolders) {
    showDialog(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: GymReorderDialog<String>(
          title: t.workout.title_routine_create_reorder,
          description: t.workout.desc_reorder_instruction,
          initialItems: sortedFolders,
          itemNameSelector: (item) => t.translateDynamic(item),
          idSelector: (item) => item,
          onSave: (reordered) {
            context.read<WorkoutCubit>().saveFolderOrder(reordered);
          },
        ),
      ),
    );
  }

  void _showRoutineReorderDialog(
    String folderKey,
    List<WorkoutSession> folderRoutines,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: GymReorderDialog<WorkoutSession>(
          title: t.workout.title_routine_create_reorder,
          description: t.workout.desc_reorder_instruction,
          initialItems: folderRoutines,
          itemNameSelector: (item) => t.translateDynamic(item.name),
          idSelector: (item) => item.id,
          onSave: (reordered) {
            final rawRoutinesMap = {
              for (var r
                  in context.read<WorkoutCubit>().state.userCustomRoutinesList)
                r.id: r,
            };
            final currentRoutines = List<WorkoutSession>.from(
              context.read<WorkoutCubit>().state.userCustomRoutinesList,
            );

            currentRoutines.removeWhere((r) {
              final rProgram = r.programName?.trim() ?? "";
              return rProgram == folderKey;
            });

            final reorderedOriginals = reordered
                .map((r) => rawRoutinesMap[r.id] ?? r)
                .toList();
            currentRoutines.addAll(reorderedOriginals);
            context.read<WorkoutCubit>().updateGlobalRoutines(currentRoutines);
          },
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    bool hasError = false;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final isTablet = screenWidth > 600;
        final maxWidth = isTablet ? 450.0 : double.infinity;

        return StatefulBuilder(
          builder: (context, setState) {
            final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

            return Dialog(
              backgroundColor: colorScheme.surface,
              insetPadding: isTablet
                  ? EdgeInsets.only(
                      left: 40.0,
                      right: 40.0,
                      top: isKeyboardOpen ? 0.0 : 24.0,
                      bottom: 0.0,
                    )
                  : const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 24.0,
                    ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Symbols.create_new_folder,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              t.workout.title_create_folder,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GymShakeWrapper(
                        hasError: hasError,
                        child: TextField(
                          controller: nameController,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: t.workout.lbl_folder_name_input,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: hasError
                                ? t.workout.msg_err_folder_name_empty
                                : null,
                          ),
                          onChanged: (v) {
                            if (hasError && v.trim().isNotEmpty) {
                              setState(() => hasError = false);
                            }
                          },
                          onSubmitted: (v) {
                            if (v.trim().isEmpty) {
                              setState(() => hasError = true);
                            } else {
                              context.read<WorkoutCubit>().createFolder(
                                v.trim(),
                              );
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(t.common.cancel),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            onPressed: () {
                              final text = nameController.text.trim();
                              if (text.isEmpty) {
                                setState(() {
                                  hasError = false;
                                });
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (ctx.mounted) {
                                    setState(() => hasError = true);
                                  }
                                });
                              } else {
                                context.read<WorkoutCubit>().createFolder(text);
                                Navigator.pop(ctx);
                              }
                            },
                            child: Text(t.common.create),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final colorScheme = Theme.of(context).colorScheme;

    // [FIX PERF 1]: Thay vì watch toàn bộ state, chỉ lắng nghe đúng các list cần thiết
    // Điều này ngăn chặn màn hình bị rebuild khi Cubit emit các trạng thái không liên quan
    final rawRoutines = context.select(
      (WorkoutCubit cubit) => cubit.state.userCustomRoutinesList,
    );

    // [i18n Dynamic Resolution] Xử lý trùng tên động dựa trên ngôn ngữ hiện hành
    final routines = <WorkoutSession>[];
    final nameCounts = <String, int>{};
    for (final routine in rawRoutines) {
      final rawDisplayName = t.translateDynamic(routine.name);
      if (nameCounts.containsKey(rawDisplayName)) {
        nameCounts[rawDisplayName] = nameCounts[rawDisplayName]! + 1;
        routines.add(
          routine.copyWith(
            name: '$rawDisplayName (${nameCounts[rawDisplayName]})',
          ),
        );
      } else {
        nameCounts[rawDisplayName] = 0;
        routines.add(routine.copyWith(name: rawDisplayName));
      }
    }
    final folderOrder = context.select(
      (WorkoutCubit cubit) => cubit.state.folderOrder,
    );

    final groupedRoutines = <String, List<WorkoutSession>>{};

    // Chỉ khởi tạo các folder có trong folderOrder
    for (var folder in folderOrder) {
      groupedRoutines[folder] = [];
    }

    // Phân loại Routine vào các Folder tương ứng
    for (var r in routines) {
      final folderKey = r.programName?.trim() ?? "";
      final actualKey = folderKey.isNotEmpty
          ? folderKey
          : t.workout.lbl_default_folder.trim();

      if (!groupedRoutines.containsKey(actualKey)) {
        groupedRoutines[actualKey] = [];
      }
      groupedRoutines[actualKey]!.add(r);
    }

    final sortedFolders = List<String>.from(folderOrder);

    // Thêm các folder có routine nhưng chưa nằm trong folderOrder (như sample programs)
    for (var folderKey in groupedRoutines.keys) {
      if (!sortedFolders.contains(folderKey)) {
        sortedFolders.add(folderKey);
      }
    }

    Widget mainList = _buildMainList(
      context: context,
      sortedFolders: sortedFolders,
      groupedRoutines: groupedRoutines,
      colorScheme: colorScheme,
      isTablet: isTablet,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: 16,
        title: Image.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'assets/logo/logo_themedark.png'
              : 'assets/logo/logo_themelight.png',
          key: ValueKey(Theme.of(context).brightness),
          height: 36,
          fit: BoxFit.contain,
        ).animate().fade(duration: 400.ms),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildDashboardPanel(context, colorScheme),
                          ),
                          const SizedBox(width: 24),
                          Expanded(flex: 6, child: mainList),
                        ],
                      )
                    : mainList,
              ),
            ),
          ),

          // 2. VÙNG CẢM BIẾN CUỘN LÊN (Đỉnh màn hình)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DragTarget<String>(
              // Trả về false để xuyên thấu xuống dưới, không chiếm quyền nhận data
              onWillAcceptWithDetails: (_) {
                _startVerticalScroll(-12.0);
                return false;
              },
              onLeave: (_) => _stopVerticalScroll(),
              builder: (context, _, _) => const SizedBox.expand(),
            ),
          ),

          // 3. VÙNG CẢM BIẾN CUỘN XUỐNG (Đáy màn hình)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 160,
            child: DragTarget<String>(
              onWillAcceptWithDetails: (_) {
                _startVerticalScroll(12.0);
                return false;
              },
              onLeave: (_) => _stopVerticalScroll(),
              builder: (context, _, _) => const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedTopPanel(BuildContext context, ColorScheme colorScheme) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    Widget startBtn = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: () {
        handleStartWorkoutConflict(
          context: context,
          activeSessionCubit: context.read<ActiveSessionCubit>(),
          onConfirmStart: () {
            context.read<ActiveSessionCubit>().startNewEmptyWorkout();
            AppRouter.expandWorkoutScreenNotifier.value = true;
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.add, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              t.workout.btn_start_new.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
            ),
          ),
        ],
      ),
    );

    Widget exploreBtn = GymTourTarget(
      isActive:
          !context.read<TourCubit>().state.hasSeenWorkout || forceShowTour,
      tourKey: TourKeys.workoutExploreBtn,
      title: t.explore.title_main.trim(),
      description: t.tour.workout_explore_desc.trim(),
      tooltipPosition: isTablet ? TooltipPosition.top : null,
      borderRadius: 16.0,
      targetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            minimumSize: const Size(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () =>
              context.push('/workout/${AppRoutes.explorePrograms}'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.explore, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.workout.btn_explore.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // FIX UX: Tự động đảo chiều Layout cho phù hợp không gian
    Widget buttonsLayout;
    if (isTablet) {
      buttonsLayout = Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Bắt nút giãn dài tràn viền Flex 4
        children: [startBtn, const SizedBox(height: 12), exploreBtn],
      );
    } else {
      buttonsLayout = Row(
        children: [
          Expanded(flex: 6, child: startBtn),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: exploreBtn),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buttonsLayout
            .animate()
            .fade(duration: 400.ms)
            .slideY(begin: -0.1, end: 0),

        const SizedBox(height: 24),

        GymTourTarget(
          isActive:
              !context.read<TourCubit>().state.hasSeenWorkout || forceShowTour,
          tourKey: TourKeys.workoutRecoveryChart,
          title: t.workout.title_recovery_status.trim(),
          description: t.tour.workout_recovery_desc.trim(),
          borderRadius: 16.0,
          targetPadding: EdgeInsets.zero,
          tooltipPosition: isTablet ? TooltipPosition.right : null,
          child: Builder(
            builder: (context) {
              final recoveryData = context.select(
                (WorkoutCubit cubit) => cubit.state.recoveryUIDataList,
              );
              return recoveryData.isNotEmpty
                  ? RecoveryBarChart(
                      recoveryDataList: recoveryData,
                    ).animate().fade(duration: 500.ms)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          t.workout.msg_warn_no_data,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardPanel(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: _buildSharedTopPanel(context, colorScheme),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Icon(
              Symbols.info,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                final emptyStr = t.workout.folder_empty;
                final parts = emptyStr.split('+');

                final baseStyle = TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                );

                if (parts.length == 2) {
                  return RichText(
                    text: TextSpan(
                      style: baseStyle,
                      children: [
                        TextSpan(text: parts[0]),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Icon(
                              Symbols.create_new_folder,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        TextSpan(text: parts[1]),
                      ],
                    ),
                  );
                }

                return Text(emptyStr, style: baseStyle);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainList({
    required BuildContext context,
    required List<String> sortedFolders,
    required Map<String, List<WorkoutSession>> groupedRoutines,
    required ColorScheme colorScheme,
    required bool isTablet,
  }) {
    final int extraTopItems = isTablet ? 1 : 2;
    final bool isEmptyFolders = sortedFolders.isEmpty;
    final int itemCount =
        extraTopItems + (isEmptyFolders ? 1 : sortedFolders.length);

    final double cardWidth = ResponsiveValue<double>(
      context,
      defaultValue: 280.0,
      conditionalValues: [Condition.largerThan(name: MOBILE, value: 350.0)],
    ).value;

    final double listHeight = ResponsiveValue<double>(
      context,
      defaultValue: 360.0,
      conditionalValues: [Condition.largerThan(name: MOBILE, value: 240.0)],
    ).value;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (!isTablet && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildSharedTopPanel(context, colorScheme),
          );
        }

        final globalHeaderIndex = isTablet ? 0 : 1;
        if (index == globalHeaderIndex) {
          return _GlobalFolderHeader(
            folderCount: sortedFolders.length,
            onAddFolder: () => _showCreateFolderDialog(context),
            forceShowTour: forceShowTour,
          );
        }

        if (isEmptyFolders) {
          return _buildEmptyState(context, colorScheme);
        }

        final folderIndex = index - extraTopItems;
        final folderKey = sortedFolders[folderIndex];
        final folderRoutines = groupedRoutines[folderKey] ?? [];

        Widget headerWidget = _FolderHeader(
          title: folderKey,
          count: folderRoutines.length,
          onAddRoutine: () {
            context.read<EditorCubit>().setRoutineToEdit(
              null,
              targetProgramName: folderKey,
            );
            context.push('/workout/${AppRoutes.createRoutine}');
          },
          onRename: () => _showRenameDialog(context, folderKey),
          onDelete: () async {
            final confirm = await GymDialog.showDestructive(
              context: context,
              title: t.workout.title_delete_confirm.trim(),
              message: t.workout.msg_delete_irreversible.trim(),
            );
            if (confirm == true && context.mounted) {
              context.read<WorkoutCubit>().deleteFolder(folderKey);
            }
          },
          onDialogReorderProgram: () =>
              _showProgramReorderDialog(sortedFolders),
        );

        if (folderIndex == 0) {
          headerWidget = GymTourTarget(
            isActive:
                !context.read<TourCubit>().state.hasSeenWorkout ||
                forceShowTour,
            tourKey: TourKeys.workoutFolderHeader,
            title: t.tour.workout_folder_title.trim(),
            description: t.tour.workout_folder_desc.trim(),
            tooltipPosition: isTablet ? null : TooltipPosition.top,
            borderRadius: 8.0,
            targetPadding: const EdgeInsets.all(4),
            child: headerWidget,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            headerWidget,

            if (folderRoutines.isNotEmpty)
              SizedBox(
                height: listHeight,
                child: _AutoScrollRoutineRow(
                  key: ValueKey('row_$folderKey'),
                  folderName: folderKey,
                  defaultFolderName: "",
                  folderRoutines: folderRoutines,
                  cardWidth: cardWidth,
                  listHeight: listHeight,
                  isTablet: isTablet,
                  colorScheme: colorScheme,
                  onRequestDelete: (routineId) async {
                    final confirm = await GymDialog.showDestructive(
                      context: context,
                      title: t.workout.title_delete_confirm.trim(),
                      message: t.workout.msg_delete_irreversible.trim(),
                    );
                    if (confirm == true && context.mounted) {
                      context.read<WorkoutCubit>().deleteRoutine(routineId);
                    }
                  },
                  onRequestReorderDialog: () =>
                      _showRoutineReorderDialog(folderKey, folderRoutines),
                  onAddRoutine: () {
                    context.read<EditorCubit>().setRoutineToEdit(
                      null,
                      targetProgramName: folderKey,
                    );
                    context.push('/workout/${AppRoutes.createRoutine}');
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      Symbols.add,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    label: Text(
                      t.workout.title_routine_create_new.trim(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    onPressed: () {
                      context.read<EditorCubit>().setRoutineToEdit(
                        null,
                        targetProgramName: folderKey,
                      );
                      context.push('/workout/${AppRoutes.createRoutine}');
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

// =========================================
// COMPONENTS CON CỦA WORKOUT SCREEN
// =========================================

class _GlobalFolderHeader extends StatelessWidget {
  final int folderCount;
  final VoidCallback onAddFolder;
  final bool forceShowTour;

  const _GlobalFolderHeader({
    required this.folderCount,
    required this.onAddFolder,
    this.forceShowTour = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                t.workout.lbl_default_folder.trim(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$folderCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          GymTourTarget(
            isActive:
                !context.read<TourCubit>().state.hasSeenWorkout ||
                forceShowTour,
            tourKey: TourKeys.workoutFolderAddBtn,
            title: t.tour.workout_folder_add_btn_title.trim(),
            description: t.tour.workout_folder_smart_empty_desc.trim(),
            tooltipPosition: isTablet ? null : TooltipPosition.top,
            borderRadius: 24.0,
            targetPadding: const EdgeInsets.all(4),
            child: IconButton(
              icon: Icon(
                Symbols.create_new_folder,
                color: colorScheme.primary,
                size: 28,
              ),
              onPressed: onAddFolder,
              tooltip: t.workout.btn_create_empty_folder,
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onAddRoutine;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onDialogReorderProgram;

  const _FolderHeader({
    required this.title,
    required this.count,
    required this.onAddRoutine,
    required this.onRename,
    required this.onDelete,
    required this.onDialogReorderProgram,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget titleWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Symbols.folder, color: colorScheme.primary, size: 22, fill: 1.0),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            t.translateDynamic(title).trim(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            softWrap: true,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "$count",
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: titleWidget),
          ),

          PopupMenuButton<String>(
            icon: Icon(Symbols.more_vert, color: colorScheme.onSurfaceVariant),
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            elevation: 4,
            onSelected: (v) {
              if (v == 'reorder_dialog') onDialogReorderProgram();
              if (v == 'rename') onRename();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reorder_dialog',
                child: Row(
                  children: [
                    Icon(Symbols.drag_handle, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.workout.title_routine_create_reorder.trim(),
                        style: TextStyle(color: colorScheme.onSurface),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Symbols.edit, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.workout.menu_rename_folder.trim(),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Symbols.delete, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.common.delete.trim(),
                        style: TextStyle(color: colorScheme.error),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================
// 1. BENTO GRID ENGINE (Đồng bộ % & Chống tràn)
// =========================================

class RoutineMuscleBento extends StatelessWidget {
  final Map<MajorMuscleGroup, double>
  distribution; // Chứa % chuẩn xác (Pure percentage)
  final double? fixedHeight;

  const RoutineMuscleBento({
    super.key,
    required this.distribution,
    this.fixedHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final rects = _calculateBentoLayout(
          Size(constraints.maxWidth, constraints.maxHeight),
          distribution,
        );

        return Stack(
          children: distribution.keys.map((group) {
            final rect = rects[group]!;
            final purePercent = distribution[group]!; // Text % lấy số thật

            return AnimatedPositioned(
              key: ValueKey(group),
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              // Truyền % thật xuống cho Box in chữ
              child: _BentoBox(group: group, percent: purePercent),
            );
          }).toList(),
        );
      },
    );

    if (fixedHeight != null) {
      return SizedBox(height: fixedHeight, child: content);
    }
    return content;
  }

  Map<MajorMuscleGroup, Rect> _calculateBentoLayout(
    Size size,
    Map<MajorMuscleGroup, double> dist,
  ) {
    final items = dist.entries.map((e) {
      double layoutWeight = math.max(e.value, 8.0);

      return _BentoNode(e.key, e.value, layoutWeight);
    }).toList();

    // Vẫn sort theo % thật để các thẻ to luôn ưu tiên nằm trước/trên cùng
    items.sort((a, b) => b.realPercent.compareTo(a.realPercent));

    final result = <MajorMuscleGroup, Rect>{};
    _slice(items, Rect.fromLTWH(0, 0, size.width, size.height), result);
    return result;
  }

  void _slice(
    List<_BentoNode> items,
    Rect bounds,
    Map<MajorMuscleGroup, Rect> result,
  ) {
    if (items.isEmpty) return;
    if (items.length == 1) {
      result[items.first.group] = bounds;
      return;
    }

    double totalWeight = items.fold(0, (s, i) => s + i.weight);
    double currentWeight = 0;
    double minDiff = double.infinity;
    int splitIdx = 1;

    for (int i = 0; i < items.length - 1; i++) {
      currentWeight += items[i].weight;
      double remaining = totalWeight - currentWeight;
      double diff = (currentWeight - remaining).abs();
      if (diff < minDiff) {
        minDiff = diff;
        splitIdx = i + 1;
      }
    }

    final groupA = items.sublist(0, splitIdx);
    final groupB = items.sublist(splitIdx);
    final weightA = groupA.fold(0.0, (s, i) => s + i.weight);
    final ratio = weightA / totalWeight;

    const spacing = 4.0;
    Rect rectA, rectB;

    if (bounds.width > bounds.height) {
      double splitW = (bounds.width - spacing) * ratio;
      rectA = Rect.fromLTWH(bounds.left, bounds.top, splitW, bounds.height);
      rectB = Rect.fromLTWH(
        bounds.left + splitW + spacing,
        bounds.top,
        bounds.width - splitW - spacing,
        bounds.height,
      );
    } else {
      double splitH = (bounds.height - spacing) * ratio;
      rectA = Rect.fromLTWH(bounds.left, bounds.top, bounds.width, splitH);
      rectB = Rect.fromLTWH(
        bounds.left,
        bounds.top + splitH + spacing,
        bounds.width,
        bounds.height - splitH - spacing,
      );
    }

    _slice(groupA, rectA, result);
    _slice(groupB, rectB, result);
  }
}

class _BentoNode {
  final MajorMuscleGroup group;
  final double realPercent;
  final double weight;
  _BentoNode(this.group, this.realPercent, this.weight);
}

// =========================================
// 2. SMART BENTO BOX (Tối ưu Padding, Icon Scale & Visual Hierarchy)
// =========================================

class _BentoBox extends StatelessWidget {
  final MajorMuscleGroup group;
  final double percent;

  const _BentoBox({required this.group, required this.percent});

  @override
  Widget build(BuildContext context) {
    // UX CẢI TIẾN: Auto-dimming cho các thẻ % quá nhỏ để giảm nhiễu thị giác
    final bool isMinor = percent < 5.0;
    final double opacityModifier = isMinor ? 0.6 : 1.0;

    final baseColor = BodyPathData.getColor(group, context);
    // Thẻ nhỏ có màu chữ mờ hơn một chút, thẻ to giữ nguyên
    final color = baseColor.withValues(alpha: opacityModifier);
    // Thẻ to nền sáng (0.15), thẻ nhỏ nền chìm đi (0.08)
    final bgColor = baseColor.withValues(alpha: isMinor ? 0.08 : 0.15);

    final key = BodyPathData.getName(group);
    final name = t.translateDynamic(key);
    final pct = '${percent.toInt()}%';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      // CẢI TIẾN 1: Giảm padding để mở rộng không gian
      padding: const EdgeInsets.all(6.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final isWide = w > h * 1.35;

          const double minIcon = 16.0;
          // CẢI TIẾN 2: Nâng giới hạn Max Size lên cao để Hero Card bung xõa
          const double maxIcon = 96.0;
          const double gap = 4.0;
          const double fullTextHeight = 32.0;
          const double pctOnlyHeight = 16.0;

          bool willOverflow = false;

          if (isWide) {
            if (w < 85 || h < 35) willOverflow = true;
          } else {
            if (h < (minIcon + gap + fullTextHeight)) {
              willOverflow = true;
            }
          }

          final bool showName = !willOverflow;

          double iconSize;
          if (isWide) {
            // Thẻ ngang: Cho phép icon chiếm đến 95% chiều cao khả dụng
            iconSize = math.max(minIcon, math.min(maxIcon, h * 0.95));
          } else {
            double reservedSpace = showName ? fullTextHeight : pctOnlyHeight;
            double availableHForIcon = h - reservedSpace - gap;

            // CẢI TIẾN 3: Đổi từ w * 0.65 thành w * 0.9
            // Icon được phép rộng gần chạm padding 2 bên
            iconSize = math.max(
              minIcon,
              math.min(maxIcon, math.min(w * 0.9, availableHForIcon)),
            );
          }

          if (isWide) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showName) ...[
                        Text(
                          name,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        pct,
                        style: TextStyle(
                          color: color,
                          fontSize: showName ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: gap),
                  GymMuscleIcon(group: group, color: color, size: iconSize),
                ],
              ),
            );
          }

          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GymMuscleIcon(group: group, color: color, size: iconSize),
                SizedBox(height: gap),
                if (showName) ...[
                  Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  pct,
                  style: TextStyle(
                    color: color,
                    fontSize: showName ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =========================================
// 2. ROUTINE CARD (StatefulWidget để hỗ trợ Caching)
// =========================================

class _RoutineCard extends StatefulWidget {
  final WorkoutSession routine;
  final double cardWidth;
  final bool isWideLayout;
  final VoidCallback onStart;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onDialogReorderRoutine;

  static const bool _debugForceShimmer = false;

  const _RoutineCard({
    required this.routine,
    required this.cardWidth,
    required this.isWideLayout,
    required this.onStart,
    required this.onView,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onDialogReorderRoutine,
  });

  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard> {
  Map<MajorMuscleGroup, double>? _cachedDistribution;
  List<Exercise>? _prevGlobalExercises;
  WorkoutSession? _prevRoutine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final globalExercises = context.select(
      (ExerciseLibraryCubit cubit) => cubit.state.exercises,
    );

    // THUẬT TOÁN CACHING
    bool shouldRecompute =
        _cachedDistribution == null ||
        _prevRoutine?.id != widget.routine.id ||
        _prevRoutine?.updatedAt != widget.routine.updatedAt ||
        !identical(_prevGlobalExercises, globalExercises);

    if (shouldRecompute) {
      _prevRoutine = widget.routine;
      _prevGlobalExercises = globalExercises;

      if (globalExercises.isNotEmpty) {
        final enrichedExercises = widget.routine.exercises.map((workoutEx) {
          final fullExercise = globalExercises.firstWhere(
            (e) => e.id == workoutEx.exercise.id,
            orElse: () => workoutEx.exercise,
          );
          return workoutEx.copyWith(exercise: fullExercise);
        }).toList();

        _cachedDistribution = enrichedExercises.calculateMuscleDistribution(
          onlyCompletedSets: false,
        );
      } else {
        _cachedDistribution = null;
      }
    }

    final bool isDataLoading =
        _RoutineCard._debugForceShimmer || globalExercises.isEmpty;

    return Container(
      width: widget.cardWidth,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onView,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 10.0,
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
            ),
            child: widget.isWideLayout
                ? _buildWideLayout(
                    colorScheme,
                    _cachedDistribution,
                    isDataLoading,
                  )
                : _buildTallLayout(
                    colorScheme,
                    _cachedDistribution,
                    isDataLoading,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTallLayout(
    ColorScheme colorScheme,
    Map<MajorMuscleGroup, double>? distribution,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(colorScheme),
        const SizedBox(height: 6),
        Expanded(
          child: Center(
            child: isLoading || distribution == null
                ? const GymBentoShimmer(fixedHeight: null)
                : RoutineMuscleBento(
                    distribution: distribution,
                    fixedHeight: null,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        _buildStartButton(colorScheme),
      ],
    );
  }

  Widget _buildWideLayout(
    ColorScheme colorScheme,
    Map<MajorMuscleGroup, double>? distribution,
    bool isLoading,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: isLoading || distribution == null
              ? const GymBentoShimmer(fixedHeight: null)
              : RoutineMuscleBento(
                  distribution: distribution,
                  fixedHeight: null,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorScheme),
              const Spacer(),
              _buildStartButton(colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final titleWidget = Text(
      t.translateDynamic(widget.routine.name).trim(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        height: 1.3,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: widget.isWideLayout ? 2 : 1,
    );

    final countBadgeWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.exercise, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '${widget.routine.exercises.length}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    final menuWidget = PopupMenuButton<String>(
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      icon: Icon(Symbols.more_horiz, color: colorScheme.onSurfaceVariant),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      elevation: 4,
      onSelected: (v) {
        if (v == 'reorder_dialog') widget.onDialogReorderRoutine();
        if (v == 'edit') widget.onEdit();
        if (v == 'duplicate') widget.onDuplicate();
        if (v == 'delete') widget.onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'reorder_dialog',
          child: Row(
            children: [
              Icon(Symbols.drag_handle, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.workout.title_routine_create_reorder.trim(),
                  style: TextStyle(color: colorScheme.onSurface),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Symbols.edit, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.common.edit.trim(),
                  style: TextStyle(color: colorScheme.onSurface),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Symbols.content_copy, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.workout.menu_routine_duplicate.trim(),
                  style: TextStyle(color: colorScheme.onSurface),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Symbols.delete, color: colorScheme.error),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.common.delete.trim(),
                  style: TextStyle(color: colorScheme.error),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.isWideLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget,
                const SizedBox(height: 8),
                countBadgeWidget,
              ],
            ),
          ),
          const SizedBox(width: 4),
          Transform.translate(offset: const Offset(8, -8), child: menuWidget),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: titleWidget),
                const SizedBox(width: 8),
                countBadgeWidget,
              ],
            ),
          ),
          Transform.translate(offset: const Offset(12, 0), child: menuWidget),
        ],
      );
    }
  }

  Widget _buildStartButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        onPressed: widget.onStart,
        icon: const Icon(Symbols.play_arrow, size: 20, fill: 1.0),
        label: Text(
          t.common.start.trim(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

void _showRenameDialog(BuildContext context, String initialName) {
  final controller = TextEditingController(
    text: t.translateDynamic(initialName),
  );
  GymDialog.showCustom(
    context: context,
    titleWidget: Text(
      t.workout.menu_rename_folder,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    content: TextField(
      controller: controller,
      autofocus: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        child: Text(t.common.cancel),
      ),
      FilledButton(
        onPressed: () {
          if (controller.text.trim().isNotEmpty) {
            context.read<WorkoutCubit>().renameFolder(
              initialName,
              controller.text.trim(),
            );
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        child: Text(t.common.save),
      ),
    ],
  );
}

class _AutoScrollRoutineRow extends StatefulWidget {
  final String folderName;
  final String defaultFolderName;
  final List<WorkoutSession> folderRoutines;
  final double cardWidth;
  final double listHeight;
  final bool isTablet;
  final ColorScheme colorScheme;
  final ValueChanged<String> onRequestDelete;
  final VoidCallback onRequestReorderDialog;
  final VoidCallback onAddRoutine; // <-- ADD THIS

  const _AutoScrollRoutineRow({
    super.key,
    required this.folderName,
    required this.defaultFolderName,
    required this.folderRoutines,
    required this.cardWidth,
    required this.listHeight,
    required this.isTablet,
    required this.colorScheme,
    required this.onRequestDelete,
    required this.onRequestReorderDialog,
    required this.onAddRoutine, // <-- ADD THIS
  });

  @override
  State<_AutoScrollRoutineRow> createState() => _AutoScrollRoutineRowState();
}

class _AutoScrollRoutineRowState extends State<_AutoScrollRoutineRow> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll(double dx) {
    if (_autoScrollTimer != null) return;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      final newOffset = (currentOffset + dx).clamp(0.0, maxScroll);

      _scrollController.jumpTo(
        newOffset,
      ); // Jump không animation để đảm bảo 60fps mượt mà

      if (newOffset == 0.0 && dx < 0) _stopAutoScroll();
      if (newOffset == maxScroll && dx > 0) _stopAutoScroll();
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. DANH SÁCH CUỘN CHÍNH SỬ DỤNG LISTVIEW.BUILDER (LAZY LOADING)
        ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          itemCount:
              widget.folderRoutines.length +
              1, // +1 cho thẻ Add (Dropzone) ở cuối
          itemBuilder: (context, index) {
            // KHU VỰC THẢ Ở CUỐI (END DROPZONE)
            if (index == widget.folderRoutines.length) {
              return DragTarget<String>(
                key: const ValueKey('end_dropzone_target'),
                onWillAcceptWithDetails: (details) => true,
                onAcceptWithDetails: (details) {
                  context.read<WorkoutCubit>().moveAndReorderRoutine(
                    details.data,
                    widget.folderName,
                    widget.folderRoutines.length,
                    widget.defaultFolderName,
                  );
                },
                builder: (context, candidateData, _) {
                  final isHovered = candidateData.isNotEmpty;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isHovered ? widget.cardWidth : 60,
                    height: widget.listHeight,
                    margin: const EdgeInsets.only(
                      right: 16,
                    ), // Margin đặt ở ngoài cùng
                    decoration: BoxDecoration(
                      color: isHovered
                          ? widget.colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isHovered
                            ? widget.colorScheme.primary.withValues(alpha: 0.5)
                            : widget.colorScheme.outline.withValues(alpha: 0.3),
                        width: isHovered ? 2 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: widget.onAddRoutine,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Icon(
                            Symbols.add,
                            color: isHovered
                                ? widget.colorScheme.primary
                                : widget.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            // THẺ ROUTINE BÌNH THƯỜNG
            final routine = widget.folderRoutines[index];
            final rIndex = index;

            return DragTarget<String>(
              key: ValueKey('drag_target_${routine.id}'),
              onWillAcceptWithDetails: (details) => details.data != routine.id,
              onAcceptWithDetails: (details) {
                context.read<WorkoutCubit>().moveAndReorderRoutine(
                  details.data,
                  widget.folderName,
                  rIndex,
                  widget.defaultFolderName,
                );
              },
              builder: (context, candidateData, _) {
                final isHovered = candidateData.isNotEmpty;
                final draggedId = isHovered ? candidateData.first : null;
                bool isDraggingRight = false;

                if (draggedId != null) {
                  final sourceIndex = widget.folderRoutines.indexWhere(
                    (r) => r.id == draggedId,
                  );
                  if (sourceIndex != -1 && sourceIndex < rIndex) {
                    isDraggingRight = true;
                  }
                }

                final highlightGap = AnimatedContainer(
                  key: ValueKey('gap_${routine.id}'),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: isHovered ? widget.cardWidth : 0.0,
                  height: widget.listHeight,
                  margin: EdgeInsets.only(
                    left: (isHovered && isDraggingRight) ? 8 : 0,
                    right: (isHovered && !isDraggingRight) ? 8 : 0,
                  ),
                  decoration: isHovered
                      ? BoxDecoration(
                          color: widget.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                            width: 2,
                          ),
                        )
                      : null,
                );

                return Container(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isDraggingRight) highlightGap,

                      LongPressDraggable<String>(
                        key: ValueKey('draggable_${routine.id}'),
                        data: routine.id,
                        delay: const Duration(milliseconds: 400),
                        onDragStarted: () => HapticFeedback.heavyImpact(),
                        onDragEnd: (_) => HapticFeedback.lightImpact(),

                        feedback: Material(
                          color: Colors.transparent,
                          child: Transform.scale(
                            scale: 0.85,
                            child: Transform.rotate(
                              angle: 0.02,
                              child: Container(
                                width: widget.cardWidth,
                                height: widget.listHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  // Tối ưu UI: Giảm thiểu Shadow và bỏ Opacity (tránh saveLayer) để đạt 60fps khi kéo thả
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _RoutineCard(
                                  routine: routine,
                                  cardWidth: widget.cardWidth,
                                  isWideLayout: widget.isTablet,
                                  onStart: () {},
                                  onView: () {},
                                  onEdit: () {},
                                  onDuplicate: () {},
                                  onDelete: () {},
                                  onDialogReorderRoutine: () {},
                                ),
                              ),
                            ),
                          ),
                        ),

                        childWhenDragging: Container(
                          width: widget.cardWidth,
                          height: widget.listHeight,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: widget.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Symbols.drag_handle,
                              color: widget.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                              size: 32,
                            ),
                          ),
                        ),

                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: widget.cardWidth,
                          height: widget.listHeight,
                          child: _RoutineCard(
                            routine: routine,
                            cardWidth: widget.cardWidth,
                            isWideLayout: widget.isTablet,
                            onStart: () {
                              handleStartWorkoutConflict(
                                context: context,
                                activeSessionCubit: context
                                    .read<ActiveSessionCubit>(),
                                onConfirmStart: () {
                                  final originalRoutine = context
                                      .read<WorkoutCubit>()
                                      .state
                                      .userCustomRoutinesList
                                      .firstWhere(
                                        (r) => r.id == routine.id,
                                        orElse: () => routine,
                                      );
                                  context
                                      .read<ActiveSessionCubit>()
                                      .startRoutine(originalRoutine);
                                  AppRouter.expandWorkoutScreenNotifier.value =
                                      true;
                                },
                              );
                            },
                            onView: () {
                              final originalRoutine = context
                                  .read<WorkoutCubit>()
                                  .state
                                  .userCustomRoutinesList
                                  .firstWhere(
                                    (r) => r.id == routine.id,
                                    orElse: () => routine,
                                  );
                              context.read<EditorCubit>().setRoutineToEdit(
                                originalRoutine,
                                targetProgramName:
                                    originalRoutine.programName ??
                                    widget.defaultFolderName,
                              );
                              context.push(
                                '/workout/${AppRoutes.createRoutine}',
                                extra: true,
                              );
                            },
                            onEdit: () {
                              final originalRoutine = context
                                  .read<WorkoutCubit>()
                                  .state
                                  .userCustomRoutinesList
                                  .firstWhere(
                                    (r) => r.id == routine.id,
                                    orElse: () => routine,
                                  );
                              context.read<EditorCubit>().setRoutineToEdit(
                                originalRoutine,
                              );
                              context.push(
                                '/workout/${AppRoutes.createRoutine}',
                                extra: false,
                              );
                            },
                            onDuplicate: () => context
                                .read<WorkoutCubit>()
                                .duplicateRoutine(routine.id),
                            onDelete: () => widget.onRequestDelete(routine.id),
                            onDialogReorderRoutine:
                                widget.onRequestReorderDialog,
                          ),
                        ),
                      ),

                      if (isDraggingRight) highlightGap,
                    ],
                  ),
                );
              },
            );
          },
        ),

        // 2. VÙNG CẢM BIẾN CUỘN LÙI
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 32,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (_) {
              _startAutoScroll(-12.0);
              return false;
            },
            onLeave: (_) => _stopAutoScroll(),
            builder: (context, _, _) => const SizedBox.expand(),
          ),
        ),

        // 3. VÙNG CẢM BIẾN CUỘN TỚI
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 32,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (_) {
              _startAutoScroll(12.0);
              return false;
            },
            onLeave: (_) => _stopAutoScroll(),
            builder: (context, _, _) => const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
