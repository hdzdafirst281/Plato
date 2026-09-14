import 'package:sqflite/sqflite.dart' as sqlite;
import 'dart:convert';
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/database/entities.dart';

class NotificationStore {
  final AppDatabase db;
  NotificationStore(this.db);
  Future<Map<String, dynamic>?> read(String key) async {
    final record = await db.notificationDao.getById(key);
    return record == null
        ? null
        : jsonDecode(record.valueJson) as Map<String, dynamic>;
  }

  Future<void> write(String key, Map<String, dynamic> value) => db
      .notificationDao
      .put(NotificationRecordEntity(id: key, valueJson: jsonEncode(value)));
  Future<Map<String, Map<String, dynamic>>> all(String prefix) async => {
    for (final record in await db.notificationDao.getAll())
      if (record.id.startsWith(prefix))
        record.id: jsonDecode(record.valueJson) as Map<String, dynamic>,
  };
  Future<void> writeBatch(Map<String, Map<String, dynamic>> records) async {
    await (db.database as sqlite.Database).transaction((txn) async {
      for (final entry in records.entries) {
        await txn.insert(
          'notification_records_local',
          {'id': entry.key, 'valueJson': jsonEncode(entry.value)},
          conflictAlgorithm: sqlite.ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> remove(String key) => db.notificationDao.remove(key);
}
