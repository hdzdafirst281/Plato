import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundWorkoutService {
  static final BackgroundWorkoutService _instance = BackgroundWorkoutService._internal();
  factory BackgroundWorkoutService() => _instance;
  BackgroundWorkoutService._internal();

  static const String ongoingChannelId = 'workout_ongoing_v6'; 
  static const int notificationId = 8888;

  static String? pendingPayload;
  static final StreamController<String?> notificationTapStream = StreamController<String?>.broadcast();

  Stream<Map<String, dynamic>?> get onServiceReady => FlutterBackgroundService().on('SERVICE_READY');

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse notificationResponse) {}

  Future<void> initialize() async {
    final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_plato') 
    );
    
    await flnp.initialize(
      settings: initSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        pendingPayload = response.payload;
        notificationTapStream.add(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final service = FlutterBackgroundService();

    const AndroidNotificationChannel ongoingChannel = AndroidNotificationChannel(
      ongoingChannelId,
      'Workout Tracking',
      description: 'Hiển thị quá trình tập luyện',
      importance: Importance.defaultImportance,
      playSound: false, 
      enableVibration: false,
    );

    final androidImplementation = flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(ongoingChannel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart, 
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: ongoingChannelId, 
        initialNotificationTitle: 'Plato Gym',
        initialNotificationContent: 'Đang tải dữ liệu buổi tập...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// =========================================================================
  /// PHẦN MỚI: HÀM KHỞI ĐỘNG AN TOÀN ĐÃ BAO GỒM LOG DEBUG CHI TIẾT
  /// =========================================================================
  Future<bool> safeStartService() async {
    debugPrint("🚀 [SERVICE] 1. Bắt đầu safeStartService...");
    
    // 1. Luôn xin quyền Notification trước
    final notifStatus = await Permission.notification.request();
    debugPrint("🚀 [SERVICE] 2. Quyền Notification: $notifStatus");

    // 2. Xử lý quyền Activity Recognition
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      debugPrint("🚀 [SERVICE] 3. OS Version: Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})");
      
      // FGS Health chỉ bắt buộc quyền trên Android 14+ (SDK 34+)
      if (androidInfo.version.sdkInt >= 34) {
        debugPrint("🚀 [SERVICE] 4. Bắt đầu kiểm tra ACTIVITY_RECOGNITION...");
        final status = await Permission.activityRecognition.status;
        
        if (status.isDenied || status.isPermanentlyDenied) {
          debugPrint("🚀 [SERVICE] 5. Quyền chưa được cấp, tiến hành hiển thị popup xin quyền...");
          final result = await Permission.activityRecognition.request();
          
          if (!result.isGranted) {
            debugPrint("❌ [SERVICE] LỖI: Bị từ chối quyền Activity Recognition!");
            debugPrint("💡 [MẸO]: Nếu bạn dùng Máy ảo, hãy vào Settings app -> Permissions -> Cho phép Physical Activity.");
            return false; 
          }
        }
        debugPrint("✅ [SERVICE] Đã có quyền ACTIVITY_RECOGNITION hợp lệ.");
      } else {
        debugPrint("🚀 [SERVICE] Bỏ qua xin quyền ACTIVITY_RECOGNITION do SDK < 34.");
      }
    }

    // 3. Khởi động thực tế
    debugPrint("🚀 [SERVICE] 6. Đang gọi _startServiceInternal()...");
    return await _startServiceInternal();
  }

  Future<bool> _startServiceInternal() async {
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      
      if (!isRunning) {
        debugPrint("🚀 [SERVICE] 7. Đang kích hoạt service ngầm...");
        final startResult = await service.startService();
        debugPrint("🚀 [SERVICE] 8. Kết quả kích hoạt: $startResult");
        return startResult; 
      }
      
      debugPrint("🚀 [SERVICE] 7. Service đã chạy sẵn từ trước.");
      return true;
    } catch (e, stacktrace) {
      // Bắt toàn bộ lỗi (Crash do OS chặn, sai Manifest, v.v.)
      debugPrint("❌ [SERVICE] CRASH KHI START FGS: $e");
      debugPrint("❌ [SERVICE] Stacktrace: $stacktrace");
      return false;
    }
  }

  void stopService() {
    FlutterBackgroundService().invoke('STOP_SERVICE');
  }

  void updateState(String title, String body, {int? startTimeMillis}) {
    FlutterBackgroundService().invoke('UPDATE_STATE', {
      'title': title,
      'body': body,
      'startTimeMillis': startTimeMillis,
    });
  }

  void startRestTimer({
    required int duration, 
    required String restTitle, 
    required String nextBody, 
    required String postRestTitle,
  }) {
    FlutterBackgroundService().invoke('START_REST', {
      'duration': duration,
      'restTitle': restTitle,
      'nextBody': nextBody,
      'postRestTitle': postRestTitle,
    });
  }
}

// =====================================================================
// ISOLATE BACKGROUND ĐỘC LẬP
// =====================================================================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized(); 

  final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('ic_stat_plato') 
  );
  await flnp.initialize(settings: initSettings);

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // Ép đồng bộ Disk, tránh Isolate đọc trúng Cache cũ
  
  final draftData = prefs.getString('DRAFT_WORKOUT_STATE');

  if (draftData == null || draftData.isEmpty) {
    debugPrint("🛑 [BACKGROUND_SERVICE] Không có Workout. Xoá Noti và Tự sát!");
    // ĐÃ FIX: Sử dụng named parameter `id:`
    await flnp.cancel(id: BackgroundWorkoutService.notificationId); 
    service.stopSelf();
    return; // Dừng toàn bộ
  }

  // ĐÃ FIX: Sử dụng đầy đủ named parameters (id, title, body, notificationDetails)
  flnp.show(
    id: BackgroundWorkoutService.notificationId, 
    title: 'Plato Gym',                             
    body: 'Đang tiếp tục buổi tập...',             
    notificationDetails: const NotificationDetails(               
      android: AndroidNotificationDetails(
        BackgroundWorkoutService.ongoingChannelId,
        'Workout Tracking',
        icon: 'ic_stat_plato',
        color: Color(0xFFFFFFFF),
        ongoing: true,
        onlyAlertOnce: true,
        importance: Importance.defaultImportance, 
        priority: Priority.defaultPriority,       
        playSound: false,
        enableVibration: false,
      ),
    ),
  );

  final audioSession = await AudioSession.instance;
  // BỎ CHỮ const Ở ĐÂY
  await audioSession.configure(AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    // Phép tính | này giờ hợp lệ vì không còn bị ép là const nữa
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers | AVAudioSessionCategoryOptions.duckOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
    avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    // Thêm const vào bên trong cho AndroidAudioAttributes vì nó độc lập và hợp lệ
    androidAudioAttributes: const AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      flags: AndroidAudioFlags.none,
      usage: AndroidAudioUsage.media,             
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck, 
    androidWillPauseWhenDucked: false,
  ));

  final AudioPlayer audioPlayer = AudioPlayer();

  try {
    await audioPlayer.setAsset('assets/sounds/rest_timer.wav');
  } catch (e) {
    debugPrint("❌ [BACKGROUND_SERVICE] Lỗi load âm thanh just_audio: $e");
  }

  Timer? restTimer;
  Timer? workoutTimer; 
  Timer? bootStabilizerTimer;
  Map<String, dynamic>? latestState; 

  String formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final formattedMS = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return h > 0 ? '$h:$formattedMS' : formattedMS;
  }

  void updateOngoing(String title, String content) {
    // ĐÃ FIX: Trả lại chuẩn named parameters cho hàm update
    flnp.show(
      id: BackgroundWorkoutService.notificationId,
      title: title,
      body: content,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          BackgroundWorkoutService.ongoingChannelId,
          'Workout Tracking',
          icon: 'ic_stat_plato',
          color: Color(0xFFFFFFFF),
          ongoing: true,
          onlyAlertOnce: true, 
          importance: Importance.defaultImportance, 
          priority: Priority.defaultPriority,       
          playSound: false,
          enableVibration: false,
        ),
      ),
      payload: 'route_log_workout', 
    );
  }

  void startMainWorkoutTimer(String title, String body, int startTimeMillis) {
    workoutTimer?.cancel();
    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    
    void tick() {
      int elapsed = DateTime.now().difference(startTime).inSeconds;
      if (elapsed < 0) elapsed = 0;
      updateOngoing('$title (${formatTime(elapsed)})', body);
    }

    tick(); 
    workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) => tick());
  }
  
  service.on('UPDATE_STATE').listen((event) {
    if (event == null) return;
    restTimer?.cancel();
    workoutTimer?.cancel(); 

    String title = event['title'] as String;
    String body = event['body'] as String;
    int? startTimeMillis = event['startTimeMillis'] as int?;

    latestState = { 'title': title, 'body': body, 'startTimeMillis': startTimeMillis };

    if (startTimeMillis != null) {
      startMainWorkoutTimer(title, body, startTimeMillis);
    } else {
      updateOngoing(title, body);
    }
  });

  service.on('START_REST').listen((event) {
    if (event == null) return;
    bootStabilizerTimer?.cancel(); 
    restTimer?.cancel();
    workoutTimer?.cancel(); 
    
    int duration = event['duration'] as int? ?? 0;
    String restTitle = event['restTitle'] as String? ?? "Rest";
    String nextBody = event['nextBody'] as String? ?? "";
    String postRestTitle = event['postRestTitle'] as String? ?? "Work";

    DateTime endTime = DateTime.now().add(Duration(seconds: duration));

    restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      int remainingSeconds = endTime.difference(DateTime.now()).inSeconds;

      if (remainingSeconds > 0) {
        updateOngoing('$restTitle (${formatTime(remainingSeconds)})', nextBody);
      } else {
        timer.cancel();
        
        Future.microtask(() async {
          try {
            if (await Vibration.hasVibrator() == true) {
              Vibration.vibrate(pattern: [0, 500, 200, 500]);
            }
          } catch (e) {
            debugPrint("❌ Lỗi rung: $e");
          }
        });

        Future.microtask(() async {
          try {
            await audioSession.setActive(true);
            await audioPlayer.seek(Duration.zero);
            await audioPlayer.play();
          } catch (e) {
            debugPrint("❌ Lỗi play just_audio: $e");
          } finally {
            await audioSession.setActive(false);
            await audioPlayer.pause();
          }
        });

        if (latestState != null && latestState!['startTimeMillis'] != null) {
          startMainWorkoutTimer(postRestTitle, nextBody, latestState!['startTimeMillis'] as int);
        } else {
          updateOngoing(postRestTitle, nextBody);
        }
      }
    });
  });

  service.on('START_CARDIO_COUNTDOWN').listen((event) {
    if (event == null) return;
    bootStabilizerTimer?.cancel(); 
    restTimer?.cancel();
    workoutTimer?.cancel(); 
    
    int duration = event['duration'] as int? ?? 0;
    String cardioTitle = event['cardioTitle'] as String? ?? "Cardio";
    String bodyContent = event['bodyContent'] as String? ?? "";

    DateTime endTime = DateTime.now().add(Duration(seconds: duration));

    workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      int remainingSeconds = endTime.difference(DateTime.now()).inSeconds;

      if (remainingSeconds > 0) {
        updateOngoing('$cardioTitle (${formatTime(remainingSeconds)})', bodyContent);
      } else {
        timer.cancel();
        
        // Tái sử dụng logic Rung
        Future.microtask(() async {
          try {
            if (await Vibration.hasVibrator() == true) {
              Vibration.vibrate(pattern: [0, 500, 200, 500]);
            }
          } catch (e) {
            debugPrint("❌ Lỗi rung: $e");
          }
        });

        // Tái sử dụng logic Chuông
        Future.microtask(() async {
          try {
            await audioSession.setActive(true);
            await audioPlayer.seek(Duration.zero);
            await audioPlayer.play();
          } catch (e) {
            debugPrint("❌ Lỗi play just_audio: $e");
          } finally {
            await audioSession.setActive(false);
            await audioPlayer.pause();
          }
        });
      }
    });
  });

  service.on('STOP_SERVICE').listen((event) async {
    restTimer?.cancel();
    workoutTimer?.cancel();
    bootStabilizerTimer?.cancel();
    await audioPlayer.dispose();
    service.stopSelf();
  });

  service.invoke('SERVICE_READY');

  int bootTicks = 0;
  bootStabilizerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (bootTicks >= 5) {
      timer.cancel();
      return;
    }
    bootTicks++;
    if (latestState != null && latestState!['startTimeMillis'] == null) {
      updateOngoing(latestState!['title'] as String, latestState!['body'] as String);
    } else if (latestState == null) {
      service.invoke('SERVICE_READY');
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}