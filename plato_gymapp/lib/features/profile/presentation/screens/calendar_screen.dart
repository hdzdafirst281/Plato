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
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_tour_target.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/theme/colors.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import 'package:plato_gymapp/core/navigation/app_routes.dart';
import 'package:plato_gymapp/core/utils/tour_keys.dart';
import 'package:plato_gymapp/features/profile/domain/profile_chart_utils.dart' as profile_chart_utils;
import 'package:plato_gymapp/features/workout/presentation/bloc/editor_cubit.dart';

import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:showcaseview/showcaseview.dart';
import '../bloc/stats_cubit.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.MONTH;
  
  late PageController _monthPageController;
  late PageController _yearPageController;
  
  // Xử lý ẩn lịch sử quá khứ
  int _earliestMonthOffset = 0;
  int _initialMonthPage = 0;
  int _currentMonthIndex = 0;
  int _currentYearIndex = 0;

  Timer? _tourDelayTimer;
  final bool forceShowTour = false; // [DEBUG FLAG]
  
  DateTime? _selectedTabletDate;
  List<dynamic>? _selectedTabletSessions;
  ShowCaseWidgetState? _showcaseState;

  // Cache dữ liệu (Tối ưu hiệu năng O(n))
  Map<DateTime, List<dynamic>> _mappedItemsCache = {};
  List<WorkoutSession> _lastPastWorkouts = [];
  List<ScheduledWorkout> _lastFutureWorkouts = [];

  @override
  void initState() {
    super.initState();
    _initPagination();

    // Đợi UI render xong data ban đầu mới trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerTour();
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

  @override
  void dispose() {
    if (_tourDelayTimer?.isActive ?? false) {
      _tourDelayTimer?.cancel();
    }
    
    // [CRITIC DEBUG FIX 1]: Force clear cờ khóa App nếu màn hình bị pop ngang bằng nút back vật lý.
    if (AppRouter.isTourActive.value) {
      AppRouter.forceAbortTour();
    }
    
    // ignore: deprecated_member_use
    try { _showcaseState?.dismiss(); } catch (_) {}
    
    _monthPageController.dispose();
    _yearPageController.dispose();
    super.dispose();
  }

  // Trigger
  void _checkAndTriggerTour() {
    if (!mounted || AppRouter.isTourActive.value) return;
    final tourCubit = context.read<TourCubit>();
    if (tourCubit.state.hasSeenCalendar && !forceShowTour) return;
    
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
    AppRouter.startTour(context, [
      TourKeys.calendarViewToggleBtn,
      TourKeys.calendarDayCell,
    ], 
    onCompleted: () {
      tourCubit.completeCalendarTour();
    });
  }

  // THÊM BIẾN QUẢN LÝ NĂM CÓ DỮ LIỆU
  List<int> _activeYears = [];

  void _initPagination() {
    final statsState = context.read<StatsCubit>().state;
    final workoutState = context.read<WorkoutCubit>().state;
    
    // Gọi update để cache sẵn _activeYears
    _updateMappedItemsIfChanged(statsState.workouts, workoutState.scheduledWorkoutsList);

    final pastWorkouts = statsState.workouts;
    final now = DateTime.now();

    if (pastWorkouts.isNotEmpty) {
      final minMillis = pastWorkouts.map((w) => w.startTime).reduce(math.min);
      final earliestDate = DateTime.fromMillisecondsSinceEpoch(minMillis).toLocal();
      _earliestMonthOffset = (earliestDate.year - now.year) * 12 + earliestDate.month - now.month;
    } else {
      _earliestMonthOffset = 0;
    }

    if (_earliestMonthOffset > 0) _earliestMonthOffset = 0;

    _initialMonthPage = -_earliestMonthOffset;
    _currentMonthIndex = _initialMonthPage;
    _monthPageController = PageController(initialPage: _initialMonthPage);

    // Gán page hiển thị năm hiện tại hoặc năm cuối cùng có data
    _currentYearIndex = math.max(0, _activeYears.length - 1);
    _yearPageController = PageController(initialPage: _currentYearIndex);
  }

  // [PERF FIX]: Giới hạn tạo Map tương lai 3 năm và cập nhật mảng năm (active years)
  void _updateMappedItemsIfChanged(List<WorkoutSession> past, List<ScheduledWorkout> future) {
    if (_lastPastWorkouts == past && _lastFutureWorkouts == future) return;

    final mappedItems = <DateTime, List<dynamic>>{};
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Giới hạn tương lai tối đa 3 năm để chặn vòng lặp vô hạn
    final maxFutureDate = DateTime(now.year + 3, now.month, now.day);
    Set<int> yearsSet = {now.year}; // Luôn hiển thị ít nhất năm hiện tại

    for (var w in past) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(w.startTime).toLocal();
      final midnightKey = DateTime(localDate.year, localDate.month, localDate.day);
      mappedItems.putIfAbsent(midnightKey, () => []).add(w);
      yearsSet.add(localDate.year);
    }
    
    for (var s in future) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(s.targetDateMillis).toLocal();
      final midnightKey = DateTime(localDate.year, localDate.month, localDate.day);
      
      if (midnightKey.isBefore(todayMidnight)) continue;
      if (midnightKey.isAfter(maxFutureDate)) continue; 
      
      mappedItems.putIfAbsent(midnightKey, () => []).add(s);
      yearsSet.add(localDate.year);
    }

    _mappedItemsCache = mappedItems;
    _lastPastWorkouts = past;
    _lastFutureWorkouts = future;
    
    _activeYears = yearsSet.toList()..sort();
    if (_currentYearIndex >= _activeYears.length) {
      _currentYearIndex = math.max(0, _activeYears.length - 1);
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return "0m";
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return t.common.time_h_m(h: h.toString(), m: m.toString());
    return t.common.time_m(m: m.toString());
  }

  DateTime get _activeDate {
    final now = DateTime.now();
    if (_viewMode == CalendarViewMode.MONTH) {
      final offset = _currentMonthIndex + _earliestMonthOffset;
      return DateTime(now.year, now.month + offset, 1);
    } else {
      if (_activeYears.isEmpty) return now;
      return DateTime(_activeYears[_currentYearIndex], 1, 1);
    }
  }

  void _onArrowPressed(bool isNext) {
    if (_viewMode == CalendarViewMode.MONTH) {
      if (isNext) {
        _monthPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
      } else if (_currentMonthIndex > 0) {
        _monthPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
      }
    } else if (_viewMode == CalendarViewMode.YEAR) {
      if (isNext && _currentYearIndex < _activeYears.length - 1) {
        _yearPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
      } else if (!isNext && _currentYearIndex > 0) {
        _yearPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
      }
    }
  }

  void _onTodayPressed() {
    if (_viewMode == CalendarViewMode.MONTH) {
      _monthPageController.animateToPage(_initialMonthPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    } else if (_viewMode == CalendarViewMode.YEAR) {
      int todayIdx = _activeYears.indexOf(DateTime.now().year);
      if (todayIdx != -1) {
        _yearPageController.animateToPage(todayIdx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      }
    } else {
      // Đối với Multi-Year, ta có thể dùng ScrollController nếu cần, 
      // nhưng mặc định danh sách xếp ngược từ mới nhất xuống.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final statsState = context.watch<StatsCubit>().state;
    final workoutState = context.watch<WorkoutCubit>().state;
    
    _updateMappedItemsIfChanged(statsState.workouts, workoutState.scheduledWorkoutsList);

    if (isDesktopMode(context) && _selectedTabletDate != null) {
      final key = DateTime(_selectedTabletDate!.year, _selectedTabletDate!.month, _selectedTabletDate!.day);
      _selectedTabletSessions = _mappedItemsCache[key] ?? [];
    }

    final currentLangCode = TranslationProvider.of(context).flutterLocale.languageCode;
    String titleLabel;
    if (_viewMode == CalendarViewMode.MONTH) {
      titleLabel = DateFormat("MMMM yyyy", currentLangCode).format(_activeDate);
    } else {
      final y = _activeYears.isNotEmpty ? _activeYears[_currentYearIndex] : DateTime.now().year;
      titleLabel = t.stats.format_calendar_year_title(arg1: y.toString());
    }

    final isLeftArrowActive = _viewMode == CalendarViewMode.MONTH ? _currentMonthIndex > 0 : _currentYearIndex > 0;
    final isRightArrowActive = _viewMode == CalendarViewMode.YEAR ? _currentYearIndex < _activeYears.length - 1 : true;

    // Label cho App Bar
    final String viewModeLabel = switch (_viewMode) {
      CalendarViewMode.MONTH => t.calendar.view_month,
      CalendarViewMode.YEAR => t.calendar.view_year,
      CalendarViewMode.MULTI_YEAR => t.calendar.view_multi_year,
    };

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Symbols.arrow_back, color: colorScheme.onSurface), 
          onPressed: () {
            // ignore: deprecated_member_use
            _showcaseState?.dismiss(); // Tắt guide tour trước khi pop
            context.pop();
          }
        ),
        titleSpacing: 0,
        centerTitle: true,
        // [UI/UX FIX]: Thay thế Row bằng Center để hấp thụ constraint từ AppBar.
        title: Row(
          mainAxisSize: MainAxisSize.min, // Quan trọng: Ép Row co lại nhỏ nhất có thể
          children: [
            GymTourTarget(
              isActive: !context.read<TourCubit>().state.hasSeenCalendar || forceShowTour,
              tourKey: TourKeys.calendarViewToggleBtn,
              title: t.tour.calendar_toggle_title,
              description: t.tour.calendar_toggle_desc,
              borderRadius: 12.0, 
              targetPadding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: PopupMenuButton<CalendarViewMode>(
                  initialValue: _viewMode,
                  onSelected: (CalendarViewMode result) {
                    setState(() {
                      _viewMode = result;
                    });
                  },
                  offset: const Offset(0, 40),
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<CalendarViewMode>>[
                    PopupMenuItem<CalendarViewMode>(
                      value: CalendarViewMode.MONTH,
                      child: Text(t.calendar.view_month),
                    ),
                    PopupMenuItem<CalendarViewMode>(
                      value: CalendarViewMode.YEAR,
                      child: Text(t.calendar.view_year),
                    ),
                    PopupMenuItem<CalendarViewMode>(
                      value: CalendarViewMode.MULTI_YEAR,
                      child: Text(t.calendar.view_multi_year),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(viewModeLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
                        const SizedBox(width: 4),
                        Icon(Symbols.expand_more, color: colorScheme.onSurface),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _onTodayPressed,
            child: Text(t.stats.btn_calendar_today, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
            
            final double cellWidth = (constraints.maxWidth - 32) / 7;
            const double childAspectRatio = 0.45; 
            final double cellHeight = cellWidth / childAspectRatio;
            final double calculatedGridHeight = cellHeight * 6 + 56;
            
            Widget calendarContent = SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        // [CRITIC DEBUG FIX]: Giữ nguyên UI chung một hàng (Row) cho 2 _CompactStatCard 
                        return Row(
                          children: [
                            Expanded(
                              child: _CompactStatCard(
                                icon: Symbols.local_fire_department,
                                gradientColors: isDark ? const [streakGradientStartDark, streakGradientEndDark] : const [streakGradientStartLight, streakGradientEndLight],
                                title: t.stats.label_calendar_streak_title,
                                value: "${statsState.weeklyStreak}",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CompactStatCard(
                                icon: Symbols.bedtime,
                                gradientColors: isDark ? const [restGradientStartDark, restGradientEndDark] : const [restGradientStartLight, restGradientEndLight],
                                title: t.stats.label_calendar_rest_title,
                                value: "${statsState.restDays}",
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  
                  // Chỉ hiển thị mũi tên ở Month và Year
                  if (_viewMode != CalendarViewMode.MULTI_YEAR)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Symbols.arrow_left, color: isLeftArrowActive ? null : colorScheme.onSurface.withValues(alpha: 0.38)), 
                            onPressed: isLeftArrowActive ? () => _onArrowPressed(false) : null
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(titleLabel.toUpperCase(), key: ValueKey(titleLabel), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton(
                            icon: Icon(Symbols.arrow_right, color: isRightArrowActive ? null : colorScheme.onSurface.withValues(alpha: 0.38)), 
                            onPressed: isRightArrowActive ? () => _onArrowPressed(true) : null
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _viewMode == CalendarViewMode.MONTH 
                      ? SizedBox(
                          height: calculatedGridHeight,
                          child: PageView.builder(
                            key: const ValueKey("month_view"),
                            controller: _monthPageController,
                            onPageChanged: (idx) => setState(() => _currentMonthIndex = idx),
                            itemBuilder: (context, index) {
                              final offset = index + _earliestMonthOffset;
                              final date = DateTime(DateTime.now().year, DateTime.now().month + offset, 1);
                              return _MonthCalendarGrid(
                                activeDate: date, 
                                mappedItems: _mappedItemsCache,
                                isDesktop: isDesktop,
                                childAspectRatio: childAspectRatio,
                                forceShowTour: forceShowTour,
                                onDaySelected: (d, sessions, {bool startTour = false}) {
                                  if (isDesktop) {
                                    setState(() {
                                      _selectedTabletDate = d;
                                      _selectedTabletSessions = sessions;
                                    });
                                  } else {
                                    _showDayWorkoutsSheet(context, d, sessions);
                                  }
                                },
                              );
                            },
                          ),
                        )
                      : (_viewMode == CalendarViewMode.YEAR 
                          ? SizedBox(
                              height: 600,
                              child: PageView.builder(
                                key: const ValueKey("year_view"),
                                controller: _yearPageController,
                                itemCount: _activeYears.length,
                                onPageChanged: (idx) => setState(() => _currentYearIndex = idx),
                                itemBuilder: (context, index) {
                                  return _YearHeatmapView(year: _activeYears[index], mappedItems: _mappedItemsCache);
                                },
                              ),
                            )
                          : _MultiYearHeatmapView(
                            activeYears: _activeYears, 
                            mappedItems: _mappedItemsCache, 
                            pastWorkouts: statsState.workouts, // Thêm dòng này
                          )
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );

            if (isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: calendarContent),
                      Expanded(
                        flex: 4, 
                        child: Container(
                          margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3))
                          ),
                          child: _selectedTabletDate != null
                              ? _buildDayDetailsInline(context, _selectedTabletDate!, _selectedTabletSessions ?? [])
                              : Center(child: Text(t.calendar.select_day_prompt, style: TextStyle(color: colorScheme.onSurfaceVariant))),
                        )
                      )
                    ],
                  ),
                ),
              );
            }

            return calendarContent;
          },
        ),
      ),
    );
  }

  void _showDayWorkoutsSheet(BuildContext context, DateTime date, List<dynamic> initialSessions) {
    final parentContext = context; 
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      useRootNavigator: false,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: parentContext.read<WorkoutCubit>()),
              BlocProvider.value(value: parentContext.read<StatsCubit>()),
            ],
            child: BlocBuilder<WorkoutCubit, WorkoutState>(
              builder: (builderCtx, workoutState) {
                // Tận dụng dữ liệu Cache đã có sẵn
                final liveSessions = (_mappedItemsCache[DateTime(date.year, date.month, date.day)] ?? []).toList();
                return _buildDayDetailsInline(parentContext, date, liveSessions, isModal: true, modalContext: ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleDeleteScheduledWorkout(BuildContext parentContext, ScheduledWorkout s, bool isModal, {BuildContext? modalContext}) async {
    final cubit = parentContext.read<WorkoutCubit>();
    final allScheduled = cubit.state.scheduledWorkoutsList;
    
    final sameRoutineInstances = allScheduled.where((w) => w.routineId == s.routineId).toList();

    if (sameRoutineInstances.length > 1) {
      GymDialog.showCustom(
        context: parentContext,
        titleWidget: Text(t.calendar.title_delete, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(t.calendar.msg_delete_recurring), 
        actions: [
          TextButton(
            onPressed: () {
              cubit.removeScheduledWorkout(s.id);
              Navigator.of(parentContext, rootNavigator: true).pop();
            },
            child: Text(t.calendar.opt_delete_one)
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(parentContext).colorScheme.error),
            onPressed: () {
              for (var instance in sameRoutineInstances) {
                cubit.removeScheduledWorkout(instance.id);
              }
              Navigator.of(parentContext, rootNavigator: true).pop();
            },
            child: Text(t.calendar.opt_delete_all)
          )
        ],
      );
    } else {
      final confirm = await GymDialog.showDestructive(
        context: parentContext,
        title: t.calendar.title_delete,
        message: t.calendar.msg_delete_confirm,
        cancelText: t.calendar.btn_cancel,
        confirmText: t.common.delete,
      );
      if (confirm == true) {
        cubit.removeScheduledWorkout(s.id);
      }
    }
  }

  Widget _buildDayDetailsInline(BuildContext parentContext, DateTime date, List<dynamic> items, {bool isModal = false, BuildContext? modalContext}) {
    final colorScheme = Theme.of(parentContext).colorScheme;
    final dateStr = DateFormat("dd MMMM yyyy", TranslationProvider.of(parentContext).flutterLocale.languageCode).format(date);
    
    final pastSessions = items.whereType<WorkoutSession>().toList();
    final futureSessions = items.whereType<ScheduledWorkout>().toList();
    
    final routinesList = parentContext.read<WorkoutCubit>().state.userCustomRoutinesList;
    futureSessions.sort((a, b) {
      final nameA = routinesList.where((r) => r.id == a.routineId).firstOrNull?.name ?? a.routineName;
      final nameB = routinesList.where((r) => r.id == b.routineId).firstOrNull?.name ?? b.routineName;
      return nameA.compareTo(nameB);
    });

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final isPastDate = date.isBefore(todayMidnight);
    
    final bool isTooLong = items.length >= 5;

    return SingleChildScrollView(
      padding: isModal ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.calendar.title_day_detail, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPastDate)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _openScheduleFlow(parentContext, date),
                          icon: const Icon(Symbols.add),
                          label: Text(t.calendar.btn_schedule),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    )
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          if (items.isEmpty)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 40),
               decoration: BoxDecoration(
                 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
               ),
               child: Column(
                 children: [
                   Icon(Symbols.event_busy, size: 48, color: colorScheme.outline),
                   const SizedBox(height: 16),
                   Text(t.calendar.msg_empty, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                 ],
               ),
             ).animate().fade().scale(begin: const Offset(0.95, 0.95)),
          
          if (futureSessions.isNotEmpty) ...[
             Text(t.calendar.section_upcoming, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
             const SizedBox(height: 12),
             ...futureSessions.map((s) {
              final cardColor = s.colorHex != null ? _hexToColor(s.colorHex!) : colorScheme.primary;
              
              final routine = routinesList.where((r) => r.id == s.routineId).firstOrNull;
              final displayRoutineName = routine?.name ?? s.routineName;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardColor, width: 1.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (routine != null) {
                        parentContext.read<EditorCubit>().setRoutineToEdit(routine);
                        parentContext.push('/workout/${AppRoutes.createRoutine}', extra: true);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.surface, 
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Symbols.schedule, color: cardColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${t.calendar.title_planned} ${t.translateDynamic(displayRoutineName)}", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(t.calendar.label_upcoming, style: TextStyle(fontSize: 12, color: cardColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Symbols.edit_calendar, color: colorScheme.primary),
                            tooltip: t.common.edit,
                            onPressed: () {
                              if (routine != null) {
                                _openScheduleFlow(parentContext, date, existingSchedule: s, initialRoutine: routine);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Symbols.delete_outline, color: colorScheme.error),
                            tooltip: t.common.delete,
                            onPressed: () => _handleDeleteScheduledWorkout(parentContext, s, isModal, modalContext: modalContext),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0);
            }),
            const SizedBox(height: 8),
          ],

          if (pastSessions.isNotEmpty) ...[
             Text(t.rank.tab_history, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
             const SizedBox(height: 12),
             ...pastSessions.map((s) {
              final rpeColor = _getRpeColor(parentContext, s.rpe);
              final durationStr = _formatDuration(s.totalDurationSeconds);
              final exercisesCountStr = t.workout.format_detail_exercises_count(arg1: s.exercises.length.toString());
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: rpeColor.withValues(alpha: 0.15), 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: rpeColor, width: 1.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      parentContext.push('/workout/workout_detail/${s.id}'); 
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
                            child: Icon(Symbols.done_all, color: rpeColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.translateDynamic(s.name), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('$exercisesCountStr • $durationStr', style: TextStyle(fontSize: 12, color: rpeColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0);
            }),
             const SizedBox(height: 8),
          ],

          if (isModal && isTooLong) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Symbols.close),
                label: Text(
                  t.common.close, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
                  foregroundColor: WidgetStatePropertyAll(colorScheme.error), 
                  overlayColor: WidgetStatePropertyAll(colorScheme.error.withValues(alpha: 0.15)), 
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
                onPressed: () {
                  if (modalContext != null) Navigator.pop(modalContext);
                },
              ),
            ),
            const SizedBox(height: 8),
          ]
        ],
      ),
    );
  }
  
  void _openScheduleFlow(BuildContext parentContext, DateTime targetDate, {ScheduledWorkout? existingSchedule, WorkoutSession? initialRoutine}) {
    showDialog(
      context: parentContext,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Theme.of(parentContext).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Theme.of(parentContext).colorScheme.outline.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: BlocProvider.value(
            value: parentContext.read<WorkoutCubit>(),
            child: _ScheduleDialogContent(
              targetDate: targetDate,
              existingSchedule: existingSchedule,
              initialRoutine: initialRoutine,
            ),
          ),
        );
      },
    );
  }
  
  // Áp dụng chuẩn ResponsiveBreakpoints thay cho biến hardcode
  bool isDesktopMode(BuildContext context) => ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
}

class _ScheduleDialogContent extends StatefulWidget {
  final DateTime targetDate;
  final ScheduledWorkout? existingSchedule;
  final WorkoutSession? initialRoutine;

  const _ScheduleDialogContent({
    required this.targetDate,
    this.existingSchedule,
    this.initialRoutine,
  });

  @override
  State<_ScheduleDialogContent> createState() => _ScheduleDialogContentState();
}

class _ScheduleDialogContentState extends State<_ScheduleDialogContent> {
  WorkoutSession? _selectedRoutine;

  @override
  void initState() {
    super.initState();
    _selectedRoutine = widget.initialRoutine;
  }

  void _goToConfig(WorkoutSession routine) {
    setState(() => _selectedRoutine = routine);
  }

  void _goBack() {
    if (widget.existingSchedule != null) {
      Navigator.pop(context); 
    } else {
      setState(() => _selectedRoutine = null);
    }
  }

  void _handleConfirm(int repeatType, int occurrences, List<int> weekdays, int intervalDays, String colorHex) {
    final cubit = context.read<WorkoutCubit>();
    if (widget.existingSchedule != null) {
      if (widget.existingSchedule!.recurrenceGroupId != null && widget.existingSchedule!.recurrenceGroupId!.isNotEmpty) {
        cubit.removeScheduledWorkoutGroup(widget.existingSchedule!.recurrenceGroupId!);
      } else {
        cubit.removeScheduledWorkout(widget.existingSchedule!.id);
      }
    }

    cubit.scheduleRoutine(
      _selectedRoutine!.id, 
      _selectedRoutine!.name, 
      widget.targetDate,
      repeatType: repeatType,
      selectedWeekdays: weekdays,
      occurrences: occurrences,
      intervalDays: intervalDays,
      colorHex: colorHex,
    );
    
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    
    Navigator.pop(context);
    
    _showSuccessDialog(rootContext);
  }

  void _showSuccessDialog(BuildContext validContext) {
    GymDialog.showSuccess(
      context: validContext,
      barrierDismissible: false,
      title: t.calendar.title_schedule_success,
      message: t.calendar.msg_schedule_success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.of(context).size.height * 0.85, 
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter, 
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter, 
              children: <Widget>[
                ...previousChildren,
                // ignore: use_null_aware_elements
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: _selectedRoutine == null
              ? KeyedSubtree(
                  key: const ValueKey('picker'),
                  child: _RoutinePickerPage(onRoutineSelected: _goToConfig),
                )
              : KeyedSubtree(
                  key: const ValueKey('config'),
                  child: _RecurrenceConfigPage(
                    routine: _selectedRoutine!,
                    targetDate: widget.targetDate,
                    initialColorHex: widget.existingSchedule?.colorHex,
                    onBack: _goBack,
                    onConfirm: _handleConfirm,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RoutinePickerPage extends StatelessWidget {
  final Function(WorkoutSession) onRoutineSelected;
  const _RoutinePickerPage({required this.onRoutineSelected});

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<WorkoutCubit>().state.userCustomRoutinesList;
    final futureWorkouts = context.watch<WorkoutCubit>().state.scheduledWorkoutsList;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.calendar.title_select_routine, 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                  )
                ),
                IconButton(
                  icon: const Icon(Symbols.close), 
                  onPressed: () => Navigator.pop(context)
                ),
              ],
            ),
          ),
          if (routines.isEmpty) 
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Text(t.calendar.msg_no_routines))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
              itemCount: routines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12), 
              itemBuilder: (c, i) {
                final r = routines[i];
                String? lastColor;
                try {
                   final lastScheduled = futureWorkouts.lastWhere((w) => w.routineId == r.id && w.colorHex != null);
                   lastColor = lastScheduled.colorHex;
                } catch (_) {}
                final Color circleColor = lastColor != null ? _hexToColor(lastColor) : Theme.of(context).colorScheme.primary;

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), 
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onRoutineSelected(r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: circleColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: Icon(Symbols.exercise, color: circleColor, size: 20)
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                t.translateDynamic(r.name), 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                            ),
                            Icon(
                              Symbols.chevron_right, 
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fade(delay: (50 * i).ms).slideX(begin: 0.05, end: 0);
              },
            ),
        ],
      ),
    );
  }
}

class _RecurrenceConfigPage extends StatefulWidget {
  final WorkoutSession routine;
  final DateTime targetDate;
  final String? initialColorHex;
  final VoidCallback onBack;
  final Function(int repeatType, int occurrences, List<int> weekdays, int intervalDays, String colorHex) onConfirm;

  const _RecurrenceConfigPage({
    required this.routine, 
    required this.targetDate, 
    this.initialColorHex, 
    required this.onBack,
    required this.onConfirm
  });

  @override
  State<_RecurrenceConfigPage> createState() => _RecurrenceConfigPageState();
}

class _RecurrenceConfigPageState extends State<_RecurrenceConfigPage> {
  int _repeatType = 0; 
  final List<int> _selectedWeekdays = [];
  bool _isInfinite = true;
  late String _selectedColorHex;

  final TextEditingController _occurrencesController = TextEditingController(text: "10");
  final TextEditingController _intervalDaysController = TextEditingController(text: "2");

  final List<String> _presetColors = [
    "#1976D2", "#388E3C", "#D32F2F", "#FBC02D", "#7B1FA2", "#E64A19", 
  ];

  @override
  void initState() {
    super.initState();
    _selectedWeekdays.add(widget.targetDate.weekday);
    _selectedColorHex = widget.initialColorHex ?? "#1976D2";
  }

  @override
  void dispose() {
    _occurrencesController.dispose();
    _intervalDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final frequencyLabel = switch (_repeatType) {
      1 => t.calendar.repeat_daily,
      2 => t.calendar.repeat_weekly,
      3 => t.calendar.repeat_interval,
      _ => t.calendar.repeat_none,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24.0, right: 16.0, top: 16.0, bottom: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Symbols.arrow_back), onPressed: widget.onBack, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.translateDynamic(widget.routine.name), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(icon: const Icon(Symbols.close), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, alignment: Alignment.centerRight),
            ],
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.calendar.label_frequency, style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<int>(
                    initialValue: _repeatType,
                    onSelected: (val) => setState(() => _repeatType = val),
                    offset: const Offset(0, 56), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    color: colorScheme.surface,
                    // Sử dụng ResponsiveValue thay cho fix object Width
                    constraints: BoxConstraints(
                      minWidth: ResponsiveValue<double>(
                        context, 
                        defaultValue: MediaQuery.sizeOf(context).width - 80, 
                        conditionalValues: [
                          Condition.largerThan(name: TABLET, value: 400.0),
                        ]
                      ).value,
                    ), 
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 0, child: Text(t.calendar.repeat_none)),
                      PopupMenuItem(value: 1, child: Text(t.calendar.repeat_daily)),
                      PopupMenuItem(value: 2, child: Text(t.calendar.repeat_weekly)),
                      PopupMenuItem(value: 3, child: Text(t.calendar.repeat_interval)),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(frequencyLabel, style: const TextStyle(fontSize: 16)),
                          Icon(Symbols.unfold_more, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_repeatType == 2) ...[
                  const SizedBox(height: 16),
                  Text(t.calendar.label_choose_days, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                      final label = day == 7 ? "CN" : "T${day+1}";
                      final isSelected = _selectedWeekdays.contains(day);
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: colorScheme.primaryContainer,
                        checkmarkColor: colorScheme.onPrimaryContainer,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(day);
                            } else if (_selectedWeekdays.length > 1) {
                              _selectedWeekdays.remove(day);
                            }
                          });
                        },
                      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
                    }).toList(),
                  ),
                ],

                if (_repeatType == 3) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextFormField(
                      controller: _intervalDaysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: t.calendar.label_interval_days,
                        suffixText: t.calendar.suffix_days,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],

                if (_repeatType != 0) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text(t.calendar.label_infinite, style: const TextStyle(fontWeight: FontWeight.bold)),
                    value: _isInfinite,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isInfinite = val ?? true),
                  ),
                  if (!_isInfinite)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextFormField(
                        controller: _occurrencesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: t.calendar.label_occurrences,
                          suffixText: t.calendar.suffix_times,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ).animate().fade().slideY(begin: -0.1, end: 0),
                    ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(t.calendar.title_color, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8.0), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _presetColors.map((hex) {
                final isSelected = _selectedColorHex == hex;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 42 : 36, 
                  height: isSelected ? 42 : 36,
                  decoration: BoxDecoration(
                    color: _hexToColor(hex),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: colorScheme.onSurface, width: 3) : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _selectedColorHex = hex),
                      child: isSelected 
                          ? const Icon(Symbols.check, color: Colors.white, size: 20).animate().scale() 
                          : const SizedBox(), 
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  int occ = 1;
                  if (_isInfinite) {
                    if (_repeatType == 1) {
                      occ = 365 * 3;
                    } else if (_repeatType == 2) occ = 104 * 3; 
                    else if (_repeatType == 3) occ = (365 * 3) ~/ (int.tryParse(_intervalDaysController.text) ?? 1).clamp(1, 1095);
                  } else {
                    occ = int.tryParse(_occurrencesController.text) ?? 1;
                  }
                  
                  int inter = int.tryParse(_intervalDaysController.text) ?? 1;
                  widget.onConfirm(_repeatType, occ, _selectedWeekdays, inter, _selectedColorHex);
                },
                child: Text(t.calendar.btn_confirm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

Color _getRpeColor(BuildContext context, int? rpe) {
  final colorScheme = Theme.of(context).colorScheme;
  final gymColors = Theme.of(context).gymColors;

  if (rpe == null) return colorScheme.primary; 
  if (rpe <= 4) return gymColors.success; 
  if (rpe <= 7) return gymColors.warning; 
  
  return colorScheme.error; 
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors; 
  final String title;
  final String value;
  
  const _CompactStatCard({
    required this.icon, 
    required this.gradientColors, 
    required this.title, 
    required this.value
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25), 
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24, fill: 1.0),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 2),
                  // Bọc bảo vệ Scale Down Cấp độ 3 cho text hiển thị con số
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value, 
                      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StripedPatternPainter extends CustomPainter {
  final Color color;

  _StripedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    const double spacing = 8.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MonthCalendarGrid extends StatelessWidget {
  final DateTime activeDate;
  final Map<DateTime, List<dynamic>> mappedItems;
  final bool isDesktop;
  final double childAspectRatio;
  final bool forceShowTour;
  final void Function(DateTime date, List<dynamic> items, {bool startTour}) onDaySelected;

  const _MonthCalendarGrid({
    required this.activeDate, 
    required this.mappedItems, 
    required this.isDesktop, 
    required this.childAspectRatio,
    this.forceShowTour = false,
    required this.onDaySelected
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final firstDayOfMonth = DateTime(activeDate.year, activeDate.month, 1);
    final lastDayOfMonth = DateTime(activeDate.year, activeDate.month + 1, 0);
    final emptyLeadingDays = firstDayOfMonth.weekday - 1; 
    
    final List<DateTime?> grid = List.generate(emptyLeadingDays, (_) => null);
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      grid.add(DateTime(activeDate.year, activeDate.month, i));
    }
    
    while (grid.length % 7 != 0) {
      grid.add(null);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final weekdays = [t.common.day_mon, t.common.day_tue, t.common.day_wed, t.common.day_thu, t.common.day_fri, t.common.day_sat, t.common.day_sun];

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final routinesList = context.read<WorkoutCubit>().state.userCustomRoutinesList;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: weekdays.map((d) => 
              Expanded(child: Text(d, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)))
            ).toList(),
          ),
          const SizedBox(height: 8),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grid.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              childAspectRatio: childAspectRatio, 
              crossAxisSpacing: 6, 
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final date = grid[index];
              
              if (date == null) {
                return const SizedBox.shrink();
              }

              final items = mappedItems[date] ?? [];
              final isToday = date.isAtSameMomentAs(todayMidnight);
              final isPastDate = date.isBefore(todayMidnight);
              final isEmptyPastDate = isPastDate && items.isEmpty;

              final pastSessions = items.whereType<WorkoutSession>().toList();
              final futureSessions = items.whereType<ScheduledWorkout>().toList();

              Widget cellWidget = Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12), 
                  border: isToday 
                      ? Border.all(color: colorScheme.primary, width: 2) 
                      : Border.all(color: Colors.transparent, width: 2), 
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isEmptyPastDate ? null : () => onDaySelected(date, items, startTour: false),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isEmptyPastDate)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10), 
                            child: CustomPaint(
                              painter: _StripedPatternPainter(
                                color: colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 24,
                              alignment: Alignment.center,
                              // Bọc FittedBox cho con số tránh trào lên ở máy hẹp
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  date.day.toString(), 
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal, 
                                    color: isToday 
                                        ? colorScheme.primary 
                                        : (isEmptyPastDate ? colorScheme.onSurface.withValues(alpha: 0.38) : colorScheme.onSurface)
                                  )
                                ),
                              ),
                            ),
                            
                            if (futureSessions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 2, right: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ...futureSessions.take(2).map((s) {
                                      final routine = routinesList.where((r) => r.id == s.routineId).firstOrNull;
                                      final realRoutineName = routine?.name ?? s.routineName;
                                      final cardColor = s.colorHex != null ? _hexToColor(s.colorHex!) : colorScheme.primary;
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 2),
                                        padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2, right: 0),
                                        decoration: BoxDecoration(
                                          color: cardColor, 
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(4))
                                        ),
                                        child: Text(
                                          t.translateDynamic(realRoutineName), 
                                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold), 
                                          maxLines: 1, 
                                          softWrap: false,
                                          overflow: TextOverflow.clip, 
                                        ),
                                      );
                                    }),
                                    
                                    if (futureSessions.length > 2)
                                      Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Icon(Symbols.more_horiz, size: 12, color: colorScheme.onSurfaceVariant),
                                      ),
                                  ],
                                ),
                              ),

                            const Spacer(),

                            if (pastSessions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: pastSessions.take(4).map((s) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                          width: 6, height: 6,
                                          decoration: BoxDecoration(
                                            color: _getRpeColor(context, s.rpe), 
                                            shape: BoxShape.circle
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    if (pastSessions.length > 4)
                                      const Center( 
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(Symbols.more_horiz, size: 12, color: Colors.grey), 
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (isToday) {
                cellWidget = GymTourTarget(
                  isActive: !context.read<TourCubit>().state.hasSeenCalendar || forceShowTour,
                  tourKey: TourKeys.calendarDayCell,
                  title: t.tour.calendar_day_title,
                  description: t.tour.calendar_day_desc,
                  tooltipPosition: isTablet ?  null : TooltipPosition.top,
                  targetPadding: EdgeInsets.zero,
                  child: cellWidget,
                );
              }
              return cellWidget;
            },
          )
        ],
      ),
    );
  }
}

class _YearHeatmapView extends StatelessWidget {
  final int year;
  final Map<DateTime, List<dynamic>> mappedItems;
  const _YearHeatmapView({required this.year, required this.mappedItems});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 0.85),
        itemCount: 12,
        itemBuilder: (context, index) {
          return _MonthHeatmapItem(year: year, month: index + 1, mappedItems: mappedItems);
        },
      ),
    );
  }
}

class _MonthHeatmapItem extends StatelessWidget {
  final int year, month;
  final Map<DateTime, List<dynamic>> mappedItems;
  const _MonthHeatmapItem({required this.year, required this.month, required this.mappedItems});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final emptyLeadingDays = firstDay.weekday - 1;
    
    final List<DateTime?> grid = List.generate(emptyLeadingDays, (_) => null);
    for (int i = 1; i <= lastDay.day; i++) {
      grid.add(DateTime(year, month, i));
    }
    while (grid.length % 7 != 0) {
      grid.add(null);
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(DateFormat("MMMM", TranslationProvider.of(context).flutterLocale.languageCode).format(firstDay), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: grid.length,
            itemBuilder: (context, index) {
              final date = grid[index];
              if (date == null) return const SizedBox();
              
              final items = mappedItems[date] ?? [];
              
              // Chỉ hiển thị dữ liệu quá khứ cho Year View
              final pastSessions = items.whereType<WorkoutSession>().toList();
              
              Color cellColor = colorScheme.surfaceContainerHighest;

              if (pastSessions.isNotEmpty) {
                 final maxRpe = pastSessions.map((s) => s.rpe ?? 0).reduce(math.max);
                 cellColor = _getRpeColor(context, maxRpe > 0 ? maxRpe : null);
              }

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: cellColor,
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class _MultiYearHeatmapView extends StatelessWidget {
  final List<int> activeYears;
  final Map<DateTime, List<dynamic>> mappedItems;
  final List<WorkoutSession> pastWorkouts;

  const _MultiYearHeatmapView({
    required this.activeYears, 
    required this.mappedItems, 
    required this.pastWorkouts,
  });

  @override
  Widget build(BuildContext context) {
    if (activeYears.isEmpty) return const SizedBox();
    
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;

    // 1. GỌI HELPER ĐỂ LẤY STATS GLOBAL
    final stats = profile_chart_utils.calculateHeatmapStats(pastWorkouts);

    // 2. GIAO DIỆN
    final reversedYears = activeYears.reversed.toList();
    final yearRangeText = activeYears.length > 1 
        ? "${activeYears.first} - ${activeYears.last}" 
        : "${activeYears.first}";

    // CHUẨN HÓA TEXT NGẮN GỌN THEO KEY JSON MỚI
    final globalWorkoutLabel = t.calendar.global_workouts(count: stats.totalWorkouts.toString());
    final globalMaxDaysLabel = t.calendar.global_max_days(days: stats.maxDaysStreak.toString());
    final globalMaxWeeksLabel = t.calendar.global_max_weeks(weeks: stats.maxWeeksStreak.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // BỘ THỐNG KÊ TỔNG QUAN
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(yearRangeText, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: colorScheme.primary)),
                const SizedBox(height: 12),
                
                // [CRITIC DEBUG FIX]: Cấp độ 2 (Expanded + Ngắt dòng) cho text để chặn overflow thiết bị cực nhỏ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.exercise, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(globalWorkoutLabel, style: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.local_fire_department, size: 18, color: gymColors.fireHexagon),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(globalMaxDaysLabel, style: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.emoji_events, size: 18, color: gymColors.rankGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(globalMaxWeeksLabel, style: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // DANH SÁCH HEATMAP TỪNG NĂM
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reversedYears.length,
          itemBuilder: (context, index) {
            return _HevyYearHeatmap(
              year: reversedYears[index], 
              mappedItems: mappedItems,
              pastWorkouts: pastWorkouts,
            );
          },
        ),
      ],
    );
  }
}

class _HevyYearHeatmap extends StatelessWidget {
  final int year;
  final Map<DateTime, List<dynamic>> mappedItems;
  final List<WorkoutSession> pastWorkouts;

  const _HevyYearHeatmap({
    required this.year, 
    required this.mappedItems, 
    required this.pastWorkouts,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    final currentLangCode = TranslationProvider.of(context).flutterLocale.languageCode;
    
    // 1. SỬ DỤNG HELPER CHO NĂM CỤ THỂ
    final stats = profile_chart_utils.calculateHeatmapStats(pastWorkouts, targetYear: year);

    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    final emptyLeadingDays = firstDay.weekday - 1; 
    final daysInYear = lastDay.difference(firstDay).inDays + 1;
    
    final numCols = ((emptyLeadingDays + daysInYear) / 7).ceil(); 
    final totalCells = numCols * 7; 

    // CHUẨN HÓA TEXT THEO KEY JSON CHUNG
    final workoutLabel = t.calendar.max_workouts(count: stats.totalWorkouts.toString());
    final daysStreakLabel = t.calendar.max_days(days: stats.maxDaysStreak.toString());
    final weeksStreakLabel = t.calendar.max_weeks(weeks: stats.maxWeeksStreak.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // [CRITIC DEBUG FIX 2]: Đưa về center để Năm và 3 Label thống kê nằm trên một đường thẳng.
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Text(year.toString(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: colorScheme.primary)),
              const SizedBox(width: 8),
              // 2. DÀN NGANG UI BẰNG WRAP CHO TỪNG NĂM
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  // [CRITIC DEBUG FIX 2]: Canh giữa các item bên trong Wrap để icon và text không bị lệch trục Y
                  crossAxisAlignment: WrapCrossAlignment.center, 
                  spacing: 12, 
                  runSpacing: 4, 
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.exercise, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(workoutLabel, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.local_fire_department, size: 14, color: gymColors.fireHexagon),
                        const SizedBox(width: 4),
                        Text(daysStreakLabel, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.emoji_events, size: 14, color: gymColors.rankGold),
                        const SizedBox(width: 4),
                        Text(weeksStreakLabel, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // [CRITIC DEBUG FIX 1]: Xóa mainAxisAlignment, dùng Expanded chia đều cứng 12 cột, 
          // bọc FittedBox (Cấp độ 3) để chống tràn chữ hoàn toàn trên màn nhỏ.
          child: Row(
            children: List.generate(12, (index) {
              final monthDate = DateTime(year, index + 1, 1);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat("MMM", currentLangCode).format(monthDate), 
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              const spacing = 2.0;
              final cellSize = (availableWidth - (numCols - 1) * spacing) / numCols;
              
              return SizedBox(
                height: (cellSize * 7) + (spacing * 6) + 0.5,
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: spacing, 
                  runSpacing: spacing, 
                  children: List.generate(totalCells, (index) {
                    
                    bool isOutOfRange = index < emptyLeadingDays || index >= emptyLeadingDays + daysInYear;
                    Color cellColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

                    if (!isOutOfRange) {
                      final dayOffset = index - emptyLeadingDays;
                      final date = firstDay.add(Duration(days: dayOffset));
                      final items = mappedItems[date] ?? [];
                      final pastSessions = items.whereType<WorkoutSession>().toList();
                      
                      if (pastSessions.isNotEmpty) {
                        final maxRpe = pastSessions.map((s) => s.rpe ?? 0).reduce(math.max);
                        cellColor = _getRpeColor(context, maxRpe > 0 ? maxRpe : null);
                      }
                    }
                    
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(cellSize * 0.2),
                      ),
                    );
                  }),
                ),
              );
            }
          ),
        ),
        const SizedBox(height: 32), 
      ],
    );
  }
}