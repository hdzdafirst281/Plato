import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:system_clock/system_clock.dart';

class TimeManager {
  static const String _kServerTimeSync = 'sync_server_time_ms';
  static const String _kUptimeSync = 'sync_uptime_ms';

  static Future<void> syncWithServer() async {
    try {
      final response = await Supabase.instance.client.rpc('get_server_time_ms');
      final int serverTimeMillis = response is int ? response : (response as num).toInt();
      final int currentUptime = SystemClock.uptime().inMilliseconds;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kServerTimeSync, serverTimeMillis);
      await prefs.setInt(_kUptimeSync, currentUptime);
    } catch (e) {
      debugPrint("⚠️ [TimeManager] Lỗi đồng bộ thời gian: $e");
    }
  }

  static Future<int> getTrueTimeMillis() async {
    final prefs = await SharedPreferences.getInstance();
    final syncServerTime = prefs.getInt(_kServerTimeSync);
    final syncUptime = prefs.getInt(_kUptimeSync);

    if (syncServerTime != null && syncUptime != null) {
      final int currentUptime = SystemClock.uptime().inMilliseconds;
      final int elapsed = currentUptime - syncUptime;
      if (currentUptime >= syncUptime) {
        return syncServerTime + elapsed;
      }
    }
    // Fallback: OS Time nhưng bắt buộc ép UTC
    return DateTime.now().toUtc().millisecondsSinceEpoch;
  }
}