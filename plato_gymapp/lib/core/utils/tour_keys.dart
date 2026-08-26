import 'package:flutter/material.dart';

class TourKeys {
  TourKeys._();

  // --- Log Workout Screen ---
  static final GlobalKey logWorkoutMinimize = GlobalKey(debugLabel: 'logWorkoutMinimize');
  static final GlobalKey logWorkoutDashboard = GlobalKey(debugLabel: 'logWorkoutDashboard');
  static final GlobalKey logWorkoutExerciseOptionsBtn = GlobalKey(debugLabel: 'logWorkoutExerciseOptionsBtn');
  static final GlobalKey logWorkoutSetRow = GlobalKey(debugLabel: 'logWorkoutSetRow');
  static final GlobalKey logWorkoutFabAdd = GlobalKey(debugLabel: 'logWorkoutFabAdd');
  static final GlobalKey logWorkoutTimerPlayBtn = GlobalKey(debugLabel: 'logWorkoutTimerPlayBtn');

  // --- Nutrition Screen ---
  static final GlobalKey nutritionHistoryBtn = GlobalKey(debugLabel: 'nutritionHistoryBtn');
  static final GlobalKey nutritionDashboard = GlobalKey(debugLabel: 'nutritionDashboard');
  static final GlobalKey nutritionWaterTracker = GlobalKey(debugLabel: 'nutritionWaterTracker');
  static final GlobalKey nutritionWeightGoal = GlobalKey(debugLabel: 'nutritionWeightGoal');
  static final GlobalKey nutritionMealSection = GlobalKey(debugLabel: 'nutritionMealSection');

  // --- Workout Screen ---
  static final GlobalKey workoutExploreBtn = GlobalKey(debugLabel: 'workoutExploreBtn');
  static final GlobalKey workoutRecoveryChart = GlobalKey(debugLabel: 'workoutRecoveryChart');
  static final GlobalKey workoutFolderHeader = GlobalKey(debugLabel: 'workoutFolderHeader');
  static final GlobalKey workoutFolderAddBtn = GlobalKey(debugLabel: 'workoutFolderAddBtn');

  // --- Calendar Screen ---
  static final GlobalKey calendarViewToggleBtn = GlobalKey(debugLabel: 'calendarViewToggleBtn');
  static final GlobalKey calendarDayCell = GlobalKey(debugLabel: 'calendarDayCell');
  static final GlobalKey calendarScheduleBtn = GlobalKey(debugLabel: 'calendarScheduleBtn');

  // --- Exercise Library Screen ---
  static final GlobalKey libraryAddCustomBtn = GlobalKey(debugLabel: 'libraryAddCustomBtn');
}