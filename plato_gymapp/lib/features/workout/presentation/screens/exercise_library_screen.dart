import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_tour_target.dart';
import 'package:plato_gymapp/core/utils/tour_keys.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/designsystem/components/gym_search_bar.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';

import '../bloc/workout_cubit.dart';
import 'create_custom_exercise_screen.dart';

enum LibraryMode { view, singleSelect, multiSelect }

class ExerciseLibraryScreen extends StatefulWidget {
  final LibraryMode mode;
  final Function(List<Exercise>)? onExercisesSelected;
  final List<String> preSelectedIds;
  final MuscleGroup? suggestedMuscle;

  const ExerciseLibraryScreen({
    super.key,
    this.mode = LibraryMode.view,
    this.onExercisesSelected,
    this.preSelectedIds = const [],
    this.suggestedMuscle,
  });

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _searchQuery = "";
  Timer? _debouncer;

  final List<MuscleGroup> _filterMuscles = [];
  final List<Equipment> _filterEquipments = [];

  final List<Exercise> _selectedExercises = [];

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showScrollToTop = ValueNotifier(false);

  Timer? _tourDelayTimer;
  ShowCaseWidgetState? _showcaseState;
  final bool forceShowTour = false; // Debug flag

  bool get _isSelectionMode => widget.mode != LibraryMode.view;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerTour();
    });
  }

  void _triggerTour() {
    if (!mounted || AppRouter.isTourActive.value) return;

    final tourCubit = context.read<TourCubit>();
    if (tourCubit.state.hasSeenExerciseLibrary && !forceShowTour) return;

    AppRouter.isTourActive.value = true;

    _tourDelayTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) {
        AppRouter.isTourActive.value = false;
        return;
      }
      AppRouter.startTour(context, [TourKeys.libraryAddCustomBtn], onCompleted: () {
        tourCubit.completeExerciseLibraryTour();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      // ignore: deprecated_member_use
      _showcaseState = ShowCaseWidget.of(context);
    } catch (_) {}
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    // CRITIC FIX: Offset responsive dựa trên 50% chiều cao màn hình hiện tại
    final responsiveThreshold = MediaQuery.of(context).size.height * 0.5;

    final shouldShow = _scrollController.offset > responsiveThreshold;
    if (_showScrollToTop.value != shouldShow) {
      _showScrollToTop.value = shouldShow;
    }
  }

  @override
  void dispose() {
    _tourDelayTimer?.cancel();
    // ignore: deprecated_member_use
    _showcaseState?.dismiss();
    _debouncer?.cancel();
    // Hủy đăng ký để tránh memory leak
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _showScrollToTop.dispose();
    super.dispose();
  }

  String _translateMuscle(MuscleGroup m) => m.getLocalizedName();
  String _translateEquipment(Equipment e) =>
      t.translateDynamic('equipment.${e.name.toLowerCase()}');

  void _handleExerciseSelection(Exercise ex) {
    setState(() {
      if (widget.mode == LibraryMode.multiSelect) {
        if (_selectedExercises.contains(ex)) {
          _selectedExercises.remove(ex);
        } else {
          // RATE LIMIT CHECK: Max 50 unique exercises per routine/session
          int currentTotalUniqueExercises =
              widget.preSelectedIds.length + _selectedExercises.length;

          if (currentTotalUniqueExercises >= 50) {
            GymSnackbar.show(
              context,
              message: t.explore.err_max_unique_exercises,
              icon: Symbols.error,
              accentColor: Theme.of(context).colorScheme.error,
            );
            return; // Chặn không cho add tiếp
          }

          _selectedExercises.add(ex);
        }
      } else if (widget.mode == LibraryMode.singleSelect) {
        widget.onExercisesSelected?.call([ex]);
        context.pop();
      }
    });
  }

  void _navigateToDetails(Exercise ex) {
    context.pushNamed('exercise_details', extra: ex);
  }

  void _showFilterBottomSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> selectedItems,
    required Map<String, List<T>> groupedItems,
    required String Function(T) labelBuilder,
    required void Function(T) onToggleItem,
    required VoidCallback onClearAll,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            List<Widget> listItems = [];
            for (final entry in groupedItems.entries) {
              if (entry.key.isNotEmpty) {
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 12,
                      left: 4,
                    ),
                    child: Text(
                      t.translateDynamic(entry.key).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                );
              }
              for (final item in entry.value) {
                final isSelected = selectedItems.contains(item);
                listItems.add(
                  _buildFilterItemCard(
                    title: labelBuilder(item),
                    isSelected: isSelected,
                    colorScheme: colorScheme,
                    onTap: () {
                      setModalState(() => onToggleItem(item));
                    },
                  ),
                );
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: listItems,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () {
                                    setModalState(() {
                                      onClearAll();
                                    });
                                  },
                            child: Text(t.common.delete_all),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => context.pop(),
                            child: Text(
                              t.common.confirm,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterItemCard({
    required String title,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (isSelected)
                    Transform.scale(
                      scale: 1.0,
                      child: Icon(
                        Symbols.check_circle,
                        color: colorScheme.primary,
                        fill: 1.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allExercises = context.select<ExerciseLibraryCubit, List<Exercise>>(
      (cubit) => cubit.state.exercises,
    );
    final frequencyMap = context.select<WorkoutCubit, Map<String, int>>(
      (cubit) => cubit.state.exerciseFrequencyMap,
    );

    var filteredExercises = allExercises.smartFilter(
      searchQuery: _searchQuery,
      targetMajorMuscle: null,
    );

    if (_filterMuscles.isNotEmpty) {
      filteredExercises = filteredExercises
          .where((ex) => _filterMuscles.contains(ex.primaryMuscle))
          .toList();
    }
    if (_filterEquipments.isNotEmpty) {
      filteredExercises = filteredExercises
          .where((ex) => _filterEquipments.contains(ex.equipment))
          .toList();
    }

    int sortStandard(Exercise a, Exercise b) {
      if (a.isCustom && !b.isCustom) return -1;
      if (!a.isCustom && b.isCustom) return 1;

      const warmUpId = 'd85332c1-01e4-4845-9d1d-bb814e36f7d2';
      final aIsWarmup = a.id == warmUpId;
      final bIsWarmup = b.id == warmUpId;
      if (aIsWarmup && !bIsWarmup) return -1;
      if (!aIsWarmup && bIsWarmup) return 1;

      final muscleA = a.primaryMuscle?.name ?? '';
      final muscleB = b.primaryMuscle?.name ?? '';
      final muscleCompare = muscleA.compareTo(muscleB);
      if (muscleCompare != 0) return muscleCompare;

      return a.name.compareTo(b.name);
    }

    int sortFreq(Exercise a, Exercise b) {
      final fA = frequencyMap[a.id] ?? 0;
      final fB = frequencyMap[b.id] ?? 0;
      if (fA != fB) return fB.compareTo(fA);
      return sortStandard(a, b);
    }

    int sortSuggested(Exercise a, Exercise b) {
      bool aIsExact = a.primaryMuscle == widget.suggestedMuscle;
      bool bIsExact = b.primaryMuscle == widget.suggestedMuscle;

      if (aIsExact && !bIsExact) return -1;
      if (!aIsExact && bIsExact) return 1;

      return sortFreq(a, b);
    }

    List<Exercise> suggestedList = [];
    List<Exercise> recentList = [];
    List<Exercise> otherList = [];

    for (var ex in filteredExercises) {
      bool isSuggestedTarget =
          widget.suggestedMuscle != null &&
          ex.primaryMuscle != null &&
          ex.primaryMuscle!.major == widget.suggestedMuscle!.major;

      if (isSuggestedTarget) {
        suggestedList.add(ex);
      } else if ((frequencyMap[ex.id] ?? 0) > 0) {
        recentList.add(ex);
      } else {
        otherList.add(ex);
      }
    }

    suggestedList.sort(sortSuggested);
    recentList.sort(sortFreq);
    otherList.sort(sortStandard);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: _getAppBarTitle(),
        navIcon: _isSelectionMode ? Symbols.close : Symbols.arrow_back,
        onBackClick: () => context.pop(),
        actions: [
          GymTourTarget(
            isActive: !context.read<TourCubit>().state.hasSeenExerciseLibrary || forceShowTour,
            tourKey: TourKeys.libraryAddCustomBtn,
            title: t.tour.library_add_custom_title,
            description: t.tour.library_add_custom_desc,
            targetPadding: const EdgeInsets.all(4),
            child: IconButton(
              icon: Icon(Symbols.add, color: colorScheme.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCustomExerciseScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showScrollToTop,
        builder: (context, show, child) {
          return AnimatedScale(
            scale: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: FloatingActionButton(
              mini: true, // Dùng size mini để không chắn quá nhiều tầm nhìn
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 4,
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Symbols.keyboard_double_arrow_up),
            ),
          );
        },
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Builder(
            builder: (context) {
              final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
              
              Widget searchAndFilter = SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: GymSearchBar(
                          searchQuery: _searchQuery,
                          onSearchChange: (v) {
                            if (_debouncer?.isActive ?? false) {
                              _debouncer!.cancel();
                            }
                            _debouncer = Timer(
                              const Duration(milliseconds: 300),
                              () => setState(() => _searchQuery = v),
                            );
                          },
                          placeholderText: t.explore.hint_library_search,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isTablet) ...[
                        _buildFilterButton<MuscleGroup>(
                          context: context,
                          selectedItems: _filterMuscles,
                          defaultHint: t.explore.label_filter_muscle,
                          labelBuilder: _translateMuscle,
                          onClear: () =>
                              setState(() => _filterMuscles.clear()),
                          onTap: () {
                            final groupedMuscles =
                                <String, List<MuscleGroup>>{};
                            for (var m in MuscleGroup.values) {
                              String majorKey;
                              if (m.major == MajorMuscleGroup.FULL_BODY ||
                                  m.major == MajorMuscleGroup.CARDIO) {
                                majorKey = 'common.other';
                              } else {
                                majorKey =
                                    'muscles.${m.major.name.toLowerCase()}';
                              }
                              groupedMuscles
                                  .putIfAbsent(majorKey, () => [])
                                  .add(m);
                            }
                            _showFilterBottomSheet<MuscleGroup>(
                              context: context,
                              title: t.explore.label_filter_muscle,
                              selectedItems: _filterMuscles,
                              groupedItems: groupedMuscles,
                              labelBuilder: _translateMuscle,
                              onClearAll: () =>
                                  setState(() => _filterMuscles.clear()),
                              onToggleItem: (item) {
                                setState(() {
                                  if (_filterMuscles.contains(item)) {
                                    _filterMuscles.remove(item);
                                  } else {
                                    _filterMuscles.add(item);
                                  }
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFilterButton<Equipment>(
                          context: context,
                          selectedItems: _filterEquipments,
                          defaultHint: t.explore.label_filter_equipment,
                          labelBuilder: _translateEquipment,
                          onClear: () =>
                              setState(() => _filterEquipments.clear()),
                          onTap: () {
                            _showFilterBottomSheet<Equipment>(
                              context: context,
                              title: t.explore.label_filter_equipment,
                              selectedItems: _filterEquipments,
                              groupedItems: {'': Equipment.values},
                              labelBuilder: _translateEquipment,
                              onClearAll: () =>
                                  setState(() => _filterEquipments.clear()),
                              onToggleItem: (item) {
                                setState(() {
                                  if (_filterEquipments.contains(item)) {
                                    _filterEquipments.remove(item);
                                  } else {
                                    _filterEquipments.add(item);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterButton<MuscleGroup>(
                                context: context,
                                selectedItems: _filterMuscles,
                                defaultHint: t.explore.label_filter_muscle,
                                labelBuilder: _translateMuscle,
                                onClear: () =>
                                    setState(() => _filterMuscles.clear()),
                                onTap: () {
                                  final groupedMuscles =
                                      <String, List<MuscleGroup>>{};
                                  for (var m in MuscleGroup.values) {
                                    String majorKey;
                                    if (m.major == MajorMuscleGroup.FULL_BODY ||
                                        m.major == MajorMuscleGroup.CARDIO) {
                                      majorKey = 'common.other';
                                    } else {
                                      majorKey =
                                          'muscles.${m.major.name.toLowerCase()}';
                                    }
                                    groupedMuscles
                                        .putIfAbsent(majorKey, () => [])
                                        .add(m);
                                  }

                                  _showFilterBottomSheet<MuscleGroup>(
                                    context: context,
                                    title: t.explore.label_filter_muscle,
                                    selectedItems: _filterMuscles,
                                    groupedItems: groupedMuscles,
                                    labelBuilder: _translateMuscle,
                                    onClearAll: () =>
                                        setState(() => _filterMuscles.clear()),
                                    onToggleItem: (item) {
                                      setState(() {
                                        if (_filterMuscles.contains(item)) {
                                          _filterMuscles.remove(item);
                                        } else {
                                          _filterMuscles.add(item);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFilterButton<Equipment>(
                                context: context,
                                selectedItems: _filterEquipments,
                                defaultHint: t.explore.label_filter_equipment,
                                labelBuilder: _translateEquipment,
                                onClear: () =>
                                    setState(() => _filterEquipments.clear()),
                                onTap: () {
                                  _showFilterBottomSheet<Equipment>(
                                    context: context,
                                    title: t.explore.label_filter_equipment,
                                    selectedItems: _filterEquipments,
                                    groupedItems: {'': Equipment.values},
                                    labelBuilder: _translateEquipment,
                                    onClearAll: () =>
                                        setState(() => _filterEquipments.clear()),
                                    onToggleItem: (item) {
                                      setState(() {
                                        if (_filterEquipments.contains(item)) {
                                          _filterEquipments.remove(item);
                                        } else {
                                          _filterEquipments.add(item);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (widget.mode == LibraryMode.view)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, left: 4.0),
                          child: Row(
                            children: [
                              Text(
                                '${filteredExercises.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.profile.btn_menu_exercises.toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );

              Widget exerciseList = filteredExercises.isEmpty
                  ? Center(
                      child: Text(
                        t.explore.msg_library_not_found,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : CustomScrollView(
                      controller: _scrollController,
                      key: ValueKey(
                        'scroll_${_searchQuery}_${_filterMuscles.length}_${_filterEquipments.length}',
                      ),
                      slivers: [
                        if (suggestedList.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Symbols.star,
                                    color: Theme.of(
                                      context,
                                    ).gymColors.goldRank,
                                    size: 16,
                                    fill: 1.0,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.explore.label_suggested_for_you
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).gymColors.goldRank,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildSliverExerciseList(suggestedList),
                        ],

                        if (recentList.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: suggestedList.isNotEmpty ? 24 : 8,
                                bottom: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Symbols.history,
                                    color: colorScheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.explore.label_recent.toUpperCase(),
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildSliverExerciseList(recentList),
                        ],

                        if (otherList.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top:
                                    (suggestedList.isNotEmpty ||
                                        recentList.isNotEmpty)
                                    ? 24
                                    : 8,
                                bottom: 16,
                              ),
                              child: Text(
                                (suggestedList.isNotEmpty ||
                                        recentList.isNotEmpty)
                                    ? t.explore.label_all_other_exercises
                                          .toUpperCase()
                                    : t.explore.label_exercise_list
                                          .toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          _buildSliverExerciseList(otherList),
                        ],
                      ],
                    );

              Widget mainContent;
              if (isTablet) {
                mainContent = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: searchAndFilter,
                    ),
                    Expanded(
                      flex: 6,
                      child: exerciseList,
                    ),
                  ],
                );
              } else {
                mainContent = Column(
                  children: [
                    searchAndFilter,
                    Expanded(
                      child: exerciseList,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(child: mainContent),
                  if (widget.mode == LibraryMode.multiSelect &&
                      _selectedExercises.isNotEmpty)
                    _buildMultiSelectBottomBar(colorScheme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSliverExerciseList(List<Exercise> exercisesList) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ex = exercisesList[index];
          final isSelected = _selectedExercises.contains(ex);
          final selectionIndex =
              (widget.mode == LibraryMode.multiSelect && isSelected)
              ? _selectedExercises.indexOf(ex)
              : -1;

          return _ExerciseCard(
            exercise: ex,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            isPreSelected: widget.preSelectedIds.contains(ex.id),
            selectionIndex: selectionIndex,
            translateMuscle: _translateMuscle,
            translateEquipment: _translateEquipment,
            onToggleSelect: () => _handleExerciseSelection(ex),
            onInfoClick: () => _navigateToDetails(ex),
          );
        }, childCount: exercisesList.length),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (widget.mode) {
      case LibraryMode.view:
        return t.explore.title_library_main;
      case LibraryMode.singleSelect:
        return t.explore.title_library_dialog_single;
      case LibraryMode.multiSelect:
        return t.explore.title_library_dialog_multi;
    }
  }

  Widget _buildFilterButton<T>({
    required BuildContext context,
    required List<T> selectedItems,
    required String defaultHint,
    required String Function(T) labelBuilder,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = selectedItems.isNotEmpty;

    String displayText = defaultHint;
    if (isActive) {
      displayText = labelBuilder(selectedItems.first);
      if (selectedItems.length > 1) {
        displayText += ' (+${selectedItems.length - 1})';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surface,
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onClear,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Symbols.close,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(
                    Symbols.tune,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectBottomBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 56),
          ),
          onPressed: () {
            widget.onExercisesSelected?.call(_selectedExercises);
            context.pop();
          },
          child: Text(
            t.explore.btn_library_add_selected_count(arg1: _selectedExercises.length.toString()),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isPreSelected;
  final int selectionIndex;
  final String Function(MuscleGroup) translateMuscle;
  final String Function(Equipment) translateEquipment;
  final VoidCallback onToggleSelect;
  final VoidCallback onInfoClick;

  const _ExerciseCard({
    required this.exercise,
    required this.isSelectionMode,
    required this.isSelected,
    required this.isPreSelected,
    required this.selectionIndex,
    required this.translateMuscle,
    required this.translateEquipment,
    required this.onToggleSelect,
    required this.onInfoClick,
  });

  Widget _buildAvatar(
    ColorScheme colorScheme,
    bool effectivelySelected,
    String displayName,
  ) {
    if (isSelectionMode && effectivelySelected) {
      return Container(
        key: const ValueKey('checked'),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPreSelected
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primary,
        ),
        alignment: Alignment.center,
        child: (selectionIndex >= 0 && !isPreSelected)
            ? Text(
                '${selectionIndex + 1}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : Icon(
                Symbols.check,
                color: isPreSelected
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimary,
              ),
      );
    }

    return Container(
      key: const ValueKey('unchecked'),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelectionMode
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest,
      ),
      alignment: Alignment.center,
      child: _buildImageContent(colorScheme, displayName),
    );
  }

  // 🚀 CRITIC FIX: Hỗ trợ hiển thị ảnh Custom (localImagePath) và ảnh Mặc định (Asset)
  Widget _buildImageContent(ColorScheme colorScheme, String displayName) {
    // 1. Nếu là Custom Exercise và có ảnh local
    if (exercise.isCustom &&
        exercise.localImagePath != null &&
        exercise.localImagePath!.trim().isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              colorScheme.surfaceContainerHighest, // Nền dự phòng cho ảnh cover
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.file(
            File(exercise.localImagePath!),
            fit: BoxFit
                .cover, // Ảnh chụp người dùng nên dùng cover để lấp đầy hình tròn
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackText(colorScheme, displayName),
          ),
        ),
      );
    }

    // 2. Nếu là Bài tập mặc định và có ảnh asset
    if (exercise.image != null && exercise.image!.trim().isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white, // Đảm bảo background trắng cho ảnh GIF mặc định
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            exercise.image!,
            fit: BoxFit.contain, // Giữ tỷ lệ ảnh mặc định
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackText(colorScheme, displayName),
          ),
        ),
      );
    }

    // 3. Fallback: Không có ảnh thì hiển thị chữ cái đầu
    return _buildFallbackText(colorScheme, displayName);
  }

  Widget _buildFallbackText(ColorScheme colorScheme, String displayName) {
    return Text(
      displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: isSelectionMode
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectivelySelected = isSelected || isPreSelected;

    final displayName = exercise.isCustom ? exercise.name : t.translateDynamic(exercise.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isPreSelected
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
              : (isSelected
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.surface),
          border: Border.all(
            color: isPreSelected
                ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                : (isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5)),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isPreSelected
                ? null
                : (isSelectionMode ? onToggleSelect : onInfoClick),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: _buildAvatar(
                      colorScheme,
                      effectivelySelected,
                      displayName,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isPreSelected
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (exercise.isCustom)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).gymColors.goldRank.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.explore.label_custom_exercise,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).gymColors.goldRank,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (exercise.primaryMuscle != null)
                              Text(
                                translateMuscle(exercise.primaryMuscle!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPreSelected
                                      ? colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        )
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (exercise.primaryMuscle != null &&
                                exercise.equipment != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  "•",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ),
                            if (exercise.equipment != null)
                              Text(
                                translateEquipment(exercise.equipment!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPreSelected
                                      ? colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        )
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelectionMode)
                    IconButton(
                      icon: Icon(
                        Symbols.info,
                        color: isPreSelected
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                      ),
                      onPressed: onInfoClick,
                      tooltip: t.workout.tooltip_view_details,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
