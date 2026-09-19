import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/data/repositories/workout_repository.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'notification_coordinator.dart';

/// Replenishes OS alarms; the OS, not this worker, delivers at the requested time.
class NotificationBackgroundWorker {
  static const taskName = 'vn.zenithas.plato.reminder_refresh';

  static Future<void> register() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  static Future<bool> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (!prefs.containsKey('notification_scope') ||
        prefs.getBool('notification_resetting') == true)
      return true;
    AppDatabase? db;
    SupabaseClient? client;
    AuthRepositoryImpl? auth;
    NotificationCoordinator? service;
    try {
      // Use local repositories without Supabase.initialize or authentication/network I/O.
      await dotenv.load(fileName: '.env');
      client = SupabaseClient(
        dotenv.env['SUPABASE_URL']!,
        dotenv.env['SUPABASE_ANON_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      auth = AuthRepositoryImpl(client, prefs);
      await LocaleSettings.setLocale(
        prefs.getString('app_lang') == 'vi' ? AppLocale.vi : AppLocale.en,
      );
      db = await AppDatabase.openNotificationBackgroundConnection();
      await FlutterLocalNotificationsPlugin().initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_plato'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      service = NotificationCoordinator(
        db,
        prefs,
        WorkoutRepository(db, client),
        auth,
        backgroundRefresh: true,
        clock: () async => DateTime.now(),
      );
      final draft = prefs.getString('DRAFT_WORKOUT_STATE');
      if (draft != null) {
        try {
          final payload = jsonDecode(draft) as Map<String, dynamic>;
          final workout = WorkoutSession.fromJson(
            Map<String, dynamic>.from(payload['activeWorkout'] as Map),
          );
          final started =
              payload['workoutStartTimeOffset'] as int? ?? workout.startTime;
          // An abandoned draft must not suppress reminders for subsequent days.
          final age = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(started),
          );
          if (!age.isNegative &&
              age < const Duration(hours: 6) &&
              workout.endTime == null) {
            service.activeWorkout = true;
            service.activeScheduleId =
                workout.sessionPayload.scheduledWorkoutId;
          }
        } catch (error) {
          debugPrint('Reminder worker ignored invalid workout draft: $error');
        }
      }
      await service.reconcileNow();
      await prefs.setInt(
        'notification_last_background_refresh_at',
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.remove('notification_background_error');
      return true;
    } catch (error) {
      await prefs.setString('notification_background_error', error.toString());
      debugPrint('Reminder background refresh failed: $error');
      return false;
    } finally {
      service?.dispose();
      auth?.dispose();
      await db?.close();
      await client?.dispose();
    }
  }
}
