import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

class WorkoutPermissionHelper {
  static const String _hasAskedPrePermissionKey = 'hasAskedPrePermission';

  static const String isBackgroundWorkoutEnabledKey =
      'isBackgroundWorkoutEnabled';

  static bool shouldAskPrePermission(SharedPreferences prefs) =>
      prefs.getBool(_hasAskedPrePermissionKey) != true;

  static Future<void> markPrePermissionHandled(SharedPreferences prefs) =>
      prefs.setBool(_hasAskedPrePermissionKey, true);

  static Future<void> checkAndStartWorkout(
    BuildContext context,
    VoidCallback onStartWorkout,
  ) async {
    final prefs = getIt<SharedPreferences>();

    if (!shouldAskPrePermission(prefs)) {
      onStartWorkout();
      return;
    }

    bool hasNoti = await Permission.notification.isGranted;
    bool hasActivity = true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 34) {
        hasActivity = await Permission.activityRecognition.isGranted;
      }
    }

    if (!context.mounted) return;

    final result = await GymDialog.showConfirm(
      context: context,
      title: t.workout.pre_permission_title,
      message: t.workout.pre_permission_desc,
      confirmText: t.workout.pre_permission_btn_allow,
      cancelText: t.workout.pre_permission_btn_later,
    );

    await markPrePermissionHandled(prefs);

    if (result == true) {
      if (!hasNoti) await Permission.notification.request();
      if (Platform.isAndroid && !hasActivity) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 34) {
          await Permission.activityRecognition.request();
        }
      }

      // Kiểm tra lại sau khi xin OS
      hasNoti = await Permission.notification.isGranted;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 34) {
          hasActivity = await Permission.activityRecognition.isGranted;
        }
      }

      if (hasNoti && hasActivity) {
        await prefs.setBool(isBackgroundWorkoutEnabledKey, true);
      } else {
        await prefs.setBool(isBackgroundWorkoutEnabledKey, false);
        if (context.mounted) {
          GymSnackbar.show(
            context,
            message: t.workout.err_permission_partial,
            accentColor: Colors.redAccent,
          );
        }
      }
    } else {
      await prefs.setBool(isBackgroundWorkoutEnabledKey, false);
    }

    if (!context.mounted) return;
    onStartWorkout();
  }
}
