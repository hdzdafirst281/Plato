import 'package:sqflite/sqflite.dart' as sqlite;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/database/entities.dart';

class NotificationStore {
  final AppDatabase db;
  String? _deliveryOwner;
  NotificationStore(this.db);

  /// SQLite arbitrates between the UI engine and Workmanager's headless engine.
  /// Expiry allows recovery if Android kills an engine while it owns the lease.
  Future<T> withDeliveryLock<T>(Future<T> Function() action) async {
    const key = 'system:delivery_lock';
    final owner = const Uuid().v4();
    final database = db.database as sqlite.Database;
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (true) {
      final acquired = await database.transaction((txn) async {
        final rows = await txn.query(
          'notification_records_local',
          where: 'id = ?',
          whereArgs: [key],
        );
        final now = DateTime.now().millisecondsSinceEpoch;
        if (rows.isNotEmpty) {
          final record = jsonDecode(rows.single['valueJson'] as String) as Map;
          if ((record['expires'] as int) > now) return false;
        }
        await txn.insert(
          'notification_records_local',
          {
            'id': key,
            'valueJson': jsonEncode({'owner': owner, 'expires': now + 120000}),
          },
          conflictAlgorithm: sqlite.ConflictAlgorithm.replace,
        );
        return true;
      });
      if (acquired) break;
      if (DateTime.now().isAfter(deadline))
        throw StateError('Notification delivery lock busy');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _deliveryOwner = owner;
    try {
      return await action();
    } finally {
      await database.transaction((txn) async {
        final rows = await txn.query(
          'notification_records_local',
          where: 'id = ?',
          whereArgs: [key],
        );
        if (rows.isNotEmpty &&
            (jsonDecode(rows.single['valueJson'] as String) as Map)['owner'] ==
                owner) {
          await txn.delete(
            'notification_records_local',
            where: 'id = ?',
            whereArgs: [key],
          );
        }
      });
      if (_deliveryOwner == owner) _deliveryOwner = null;
    }
  }

  Future<void> renewDeliveryLock() async {
    final owner = _deliveryOwner;
    if (owner == null) throw StateError('Notification delivery lock not held');
    await (db.database as sqlite.Database).transaction((txn) async {
      final rows = await txn.query(
        'notification_records_local',
        where: 'id = ?',
        whereArgs: ['system:delivery_lock'],
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      if (rows.isEmpty) throw StateError('Notification delivery lock lost');
      final record = jsonDecode(rows.single['valueJson'] as String) as Map;
      if (record['owner'] != owner || (record['expires'] as int) <= now) {
        throw StateError('Notification delivery lock expired');
      }
      await txn.update(
        'notification_records_local',
        {
          'valueJson': jsonEncode({'owner': owner, 'expires': now + 120000}),
        },
        where: 'id = ?',
        whereArgs: ['system:delivery_lock'],
      );
    });
  }

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
