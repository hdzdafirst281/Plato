import 'package:flutter/foundation.dart';
import 'package:floor/floor.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../database/app_database.dart';
import '../database/daos.dart';

@module
abstract class AppModule {
  @preResolve
  @singleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @preResolve
  @singleton
  Future<AppDatabase> get appDatabase async {
    debugPrint("🛠️ [DEBUG DB] 1. Đang khởi tạo AppDatabase...");
    final sharedPrefs = await SharedPreferences.getInstance();

    final callback = Callback(
      onOpen: (sqflite.Database database) async {
        debugPrint("🛠️ [DEBUG DB] 2. Callback onOpen được gọi!");
        try {
          const int currentSqlVersion = 4; // ĐÃ CẬP NHẬT LÊN VERSION 4
          final int savedSqlVersion = sharedPrefs.getInt('sql_seed_version') ?? 0;

          debugPrint("🛠️ [DEBUG DB] -> Phiên bản SQL trong máy: $savedSqlVersion | Phiên bản yêu cầu: $currentSqlVersion");

          if (savedSqlVersion < currentSqlVersion) {
            debugPrint("🛠️ [DEBUG DB] 3. Bắt đầu tiến trình CẬP NHẬT DATABASE!");

            debugPrint("🛠️ [DEBUG DB] 3.1. Đang xóa data cũ...");
            await database.execute('DELETE FROM exercises WHERE is_custom = 0 OR is_custom IS NULL');
            await database.execute('DELETE FROM foods');
            debugPrint("🛠️ [DEBUG DB] -> Đã xóa data cũ thành công!");

            debugPrint("🛠️ [DEBUG DB] 3.2. Đang đọc file init_data.sql...");
            final sqlString = await rootBundle.loadString('assets/init_data.sql');
            
            final rawStatements = sqlString
                .split(';')
                .map((stmt) => stmt.trim())
                .where((stmt) => stmt.isNotEmpty)
                .toList(); 

            final statements = rawStatements.map((stmt) {
              if (stmt.contains('INSERT INTO exercises')) {
                // ĐÃ FIX: Chèn thêm cột user_note và giá trị NULL vào dữ liệu mặc định
                return stmt
                    .replaceAll('is_deleted) VALUES', 'is_deleted, is_custom, user_note) VALUES')
                    .replaceAll(RegExp(r', 0\)$'), ', 0, 0, NULL)')
                    .replaceAll(RegExp(r', 1\)$'), ', 1, 0, NULL)');
              }
              return stmt;
            }).toList();

            debugPrint("🛠️ [DEBUG DB] -> Tìm thấy ${statements.length} câu lệnh SQL cần chạy.");

            debugPrint("🛠️ [DEBUG DB] 3.3. Bắt đầu chạy Transaction (Từng câu lệnh một)...");
            await database.transaction((txn) async {
              for (int i = 0; i < statements.length; i++) {
                final statement = statements[i];
                try {
                  await txn.execute(statement);
                } catch (err) {
                  debugPrint("❌ [DEBUG DB LỖI NGHIÊM TRỌNG] Lỗi SQL văng ra ở câu lệnh thứ ${i + 1}:");
                  debugPrint("❌ [NỘI DUNG LỆNH]: $statement");
                  debugPrint("❌ [CHI TIẾT LỖI]: $err");
                  rethrow; 
                }
              }
            });
            debugPrint("🛠️ [DEBUG DB] -> Chạy Transaction thành công 100%!");

            await sharedPrefs.setInt('sql_seed_version', currentSqlVersion);
            debugPrint("✅ [DEBUG DB] ĐÃ HOÀN TẤT TOÀN BỘ! Đã lưu Version $currentSqlVersion.");
          } else {
            debugPrint("⚡ [DEBUG DB] Database đã ở version mới nhất ($currentSqlVersion). Bỏ qua cập nhật.");
          }
        } catch (e) {
          debugPrint("❌ [DEBUG DB TỔNG] Quá trình cập nhật Database thất bại hoàn toàn!");
          debugPrint("Chi tiết: $e");
        }
      },
    );

    debugPrint("🛠️ [DEBUG DB] Đang build Floor Database...");
    return await $FloorAppDatabase
        .databaseBuilder('plato_app_database.db')
        .addMigrations([migration2to3, migration3to4, migration4to5, migration5to6])
        .addCallback(callback)
        .build();
  }

  @singleton
  FoodDao getFoodDao(AppDatabase db) => db.foodDao;

  @singleton
  ExerciseDao getExerciseDao(AppDatabase db) => db.exerciseDao;

  @singleton
  RewardClaimDao getRewardClaimDao(AppDatabase db) => db.rewardClaimDao;
}