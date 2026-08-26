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

  static const String isBackgroundWorkoutEnabledKey = 'isBackgroundWorkoutEnabled';

  static Future<void> checkAndStartWorkout(BuildContext context, VoidCallback onStartWorkout) async {
    final prefs = getIt<SharedPreferences>();
    final hasAsked = prefs.getBool(_hasAskedPrePermissionKey) ?? false;

    if (hasAsked) {
      // 1. Đã từng quyết định (qua dialog hoặc setting) -> Tôn trọng setting hiện tại.
      // Không ép isBackgroundWorkoutEnabledKey = true kể cả khi có quyền.
      onStartWorkout();
      return;
    }

    // 2. Chưa từng hỏi, kiểm tra xem OS có tình cờ cho quyền sẵn không
    bool hasNoti = await Permission.notification.isGranted;
    bool hasActivity = true; 
    
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 34) {
        hasActivity = await Permission.activityRecognition.isGranted;
      }
    }

    if (hasNoti && hasActivity) {
      // Đã có quyền sẵn -> Đánh dấu đã hỏi và đang bật (migration cho user cũ)
      await prefs.setBool(_hasAskedPrePermissionKey, true);
      await prefs.setBool(isBackgroundWorkoutEnabledKey, true);
      onStartWorkout();
      return;
    }

    // 3. Hiện Pre-permission Dialog bằng GymDialog
    if (!context.mounted) return;
    
    final result = await GymDialog.showConfirm(
      context: context,
      title: t.workout.pre_permission_title,
      message: t.workout.pre_permission_desc,
      confirmText: t.workout.pre_permission_btn_allow,
      cancelText: t.workout.pre_permission_btn_later,
    );

    // Đánh dấu là đã hỏi (Dù bấm gì)
    await prefs.setBool(_hasAskedPrePermissionKey, true);

    if (result == true) {
      // User chọn "Cấp quyền" -> Xin quyền OS
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
        // OS Từ chối thì xem như là Không bật
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
      // User chọn "Để sau"
      await prefs.setBool(isBackgroundWorkoutEnabledKey, false);
    }

    if (!context.mounted) return;
    // Dù user đồng ý hay từ chối OS, vẫn tiếp tục vào buổi tập (Fallback an toàn)
    onStartWorkout();
  }
}
