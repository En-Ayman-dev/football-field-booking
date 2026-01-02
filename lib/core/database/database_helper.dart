// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  static const String _databaseName = 'arena_manager.db';
  // --- تم رفع الإصدار لتطبيق التعديلات الجديدة (جدول الإعدادات settings) ---
  static const int _databaseVersion = 8;

  // أسماء الجداول
  static const String tableUsers = 'users';
  static const String tableCoaches = 'coaches';
  static const String tablePitches = 'pitches';
  static const String tableBalls = 'balls';
  static const String tableBookings = 'bookings';
  static const String tableSyncStatus = 'sync_status';
  static const String tableDepositRequests = 'deposit_requests';
  // --- الجدول الجديد ---
  static const String tableSettings = 'settings';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // جدول المستخدمين
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        role TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        wage_per_booking REAL,
        can_manage_pitches INTEGER NOT NULL DEFAULT 0,
        can_manage_coaches INTEGER NOT NULL DEFAULT 0,
        can_manage_bookings INTEGER NOT NULL DEFAULT 0,
        can_view_reports INTEGER NOT NULL DEFAULT 0,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول المدربين
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tableCoaches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        specialization TEXT,
        price_per_hour REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول الملاعب
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tablePitches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        name TEXT NOT NULL,
        location TEXT,
        price_per_hour REAL,
        is_indoor INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول الكرات
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tableBalls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        name TEXT NOT NULL,
        size TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        is_available INTEGER NOT NULL DEFAULT 1,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول الحجوزات
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tableBookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        user_id INTEGER NOT NULL,
        coach_id INTEGER,
        pitch_id INTEGER NOT NULL,
        ball_id INTEGER,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        total_price REAL,
        status TEXT,
        notes TEXT,
        team_name TEXT,
        customer_phone TEXT,
        period TEXT,
        created_by_user_id INTEGER NOT NULL,
        staff_wage REAL,
        coach_wage REAL,
        is_deposited INTEGER NOT NULL DEFAULT 0,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        FOREIGN KEY (coach_id) REFERENCES $tableCoaches (id) ON DELETE SET NULL,
        FOREIGN KEY (pitch_id) REFERENCES $tablePitches (id) ON DELETE CASCADE,
        FOREIGN KEY (ball_id) REFERENCES $tableBalls (id) ON DELETE SET NULL,
        FOREIGN KEY (created_by_user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      );
    ''');

    // جدول حالة المزامنة
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tableSyncStatus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        operation TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        last_attempt_at TEXT,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول طلبات التوريد
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tableDepositRequests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        processed_by INTEGER,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        processed_at TEXT,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        FOREIGN KEY (processed_by) REFERENCES $tableUsers (id) ON DELETE SET NULL
      );
    ''');

    // --- جدول الإعدادات الجديد (بنسخته القابلة للمزامنة) ---
    batch.execute('''
      CREATE TABLE IF NOT EXISTS $tableSettings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT,
        firebase_id TEXT UNIQUE,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (newVersion > oldVersion) {
      // ... (التحديثات السابقة 1-5 كما هي) ...
      try {
        final info = await db.rawQuery('PRAGMA table_info($tableUsers)');
        final hasWage = info.any(
          (col) => (col['name'] as String?) == 'wage_per_booking',
        );
        if (!hasWage) {
          await db.execute(
            'ALTER TABLE $tableUsers ADD COLUMN wage_per_booking REAL',
          );
        }
        final hasCanManagePitches = info.any(
          (col) => (col['name'] as String?) == 'can_manage_pitches',
        );
        if (!hasCanManagePitches) {
          await db.execute(
            'ALTER TABLE $tableUsers ADD COLUMN can_manage_pitches INTEGER NOT NULL DEFAULT 0',
          );
        }
        final hasCanManageCoaches = info.any(
          (col) => (col['name'] as String?) == 'can_manage_coaches',
        );
        if (!hasCanManageCoaches) {
          await db.execute(
            'ALTER TABLE $tableUsers ADD COLUMN can_manage_coaches INTEGER NOT NULL DEFAULT 0',
          );
        }
        final hasCanManageBookings = info.any(
          (col) => (col['name'] as String?) == 'can_manage_bookings',
        );
        if (!hasCanManageBookings) {
          await db.execute(
            'ALTER TABLE $tableUsers ADD COLUMN can_manage_bookings INTEGER NOT NULL DEFAULT 0',
          );
        }
        final hasCanViewReports = info.any(
          (col) => (col['name'] as String?) == 'can_view_reports',
        );
        if (!hasCanViewReports) {
          await db.execute(
            'ALTER TABLE $tableUsers ADD COLUMN can_view_reports INTEGER NOT NULL DEFAULT 0',
          );
        }
      } catch (e) {
        if (kDebugMode) print('Error user table upgrades: $e');
      }

      try {
        final bookingInfo = await db.rawQuery(
          'PRAGMA table_info($tableBookings)',
        );
        final hasStaffWage = bookingInfo.any(
          (col) => (col['name'] as String?) == 'staff_wage',
        );
        if (!hasStaffWage) {
          await db.execute(
            'ALTER TABLE $tableBookings ADD COLUMN staff_wage REAL',
          );
        }
        final hasCoachWage = bookingInfo.any(
          (col) => (col['name'] as String?) == 'coach_wage',
        );
        if (!hasCoachWage) {
          await db.execute(
            'ALTER TABLE $tableBookings ADD COLUMN coach_wage REAL',
          );
        }
        final hasPeriod = bookingInfo.any(
          (col) => (col['name'] as String?) == 'period',
        );
        if (!hasPeriod) {
          await db.execute('ALTER TABLE $tableBookings ADD COLUMN period TEXT');
        }
      } catch (e) {
        if (kDebugMode) print('Error bookings table upgrades: $e');
      }

      try {
        final bookingInfo = await db.rawQuery(
          'PRAGMA table_info($tableBookings)',
        );
        final expectedColumns = <String, String>{
          'team_name': 'TEXT',
          'customer_phone': 'TEXT',
        };
        for (final entry in expectedColumns.entries) {
          final name = entry.key;
          final colType = entry.value;
          final hasCol = bookingInfo.any((c) => (c['name'] as String?) == name);
          if (!hasCol) {
            await db.execute(
              'ALTER TABLE $tableBookings ADD COLUMN $name $colType',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error bookings optional columns: $e');
      }

      try {
        final depositInfo = await db.rawQuery(
          'PRAGMA table_info($tableDepositRequests)',
        );
        if (depositInfo.isEmpty) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableDepositRequests (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              note TEXT,
              status TEXT NOT NULL DEFAULT 'pending',
              processed_by INTEGER,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              processed_at TEXT,
              is_dirty INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
              FOREIGN KEY (processed_by) REFERENCES $tableUsers (id) ON DELETE SET NULL
            );
          ''');
        }
      } catch (e) {
        if (kDebugMode) print('Error creating $tableDepositRequests: $e');
      }

      // --- التحديث الجديد (الإصدار 6) للمزامنة ---
      if (newVersion >= 6) {
        final tablesToSync = [
          tableUsers,
          tableCoaches,
          tablePitches,
          tableBalls,
          tableBookings,
          tableDepositRequests,
        ];

        for (var table in tablesToSync) {
          try {
            final info = await db.rawQuery('PRAGMA table_info($table)');
            final hasFirebaseId = info.any(
              (col) => (col['name'] as String?) == 'firebase_id',
            );
            if (!hasFirebaseId) {
              await db.execute(
                'ALTER TABLE $table ADD COLUMN firebase_id TEXT UNIQUE',
              );
            }
            final hasDeletedAt = info.any(
              (col) => (col['name'] as String?) == 'deleted_at',
            );
            if (!hasDeletedAt) {
              await db.execute('ALTER TABLE $table ADD COLUMN deleted_at TEXT');
            }
            final hasIsDirty = info.any(
              (col) => (col['name'] as String?) == 'is_dirty',
            );
            if (!hasIsDirty) {
              await db.execute(
                'ALTER TABLE $table ADD COLUMN is_dirty INTEGER NOT NULL DEFAULT 0',
              );
            }
          } catch (e) {
            if (kDebugMode) print('Error upgrading table $table for sync: $e');
          }
        }
      }

      // --- التحديث الجديد (الإصدار 7): إضافة is_deposited ---
      if (newVersion >= 7) {
        try {
          final bookingInfo = await db.rawQuery(
            'PRAGMA table_info($tableBookings)',
          );
          final hasIsDeposited = bookingInfo.any(
            (col) => (col['name'] as String?) == 'is_deposited',
          );
          if (!hasIsDeposited) {
            await db.execute(
              'ALTER TABLE $tableBookings ADD COLUMN is_deposited INTEGER NOT NULL DEFAULT 0',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error upgrading booking table for is_deposited: $e');
          }
        }
      }

      // --- التحديث الجديد (الإصدار 8): إضافة جدول الإعدادات للمزامنة ---
      if (newVersion >= 8) {
        try {
          // التحقق مما إذا كان الجدول موجوداً
          var list = await db.query(
            'sqlite_master',
            where: 'name = ?',
            whereArgs: [tableSettings],
          );

          if (list.isNotEmpty) {
            // إذا كان الجدول موجوداً، نتحقق من وجود عمود id (الذي يعتمد عليه نظام المزامنة)
            // النسخة القديمة كانت: (key TEXT PRIMARY KEY, value TEXT)
            var cols = await db.rawQuery('PRAGMA table_info($tableSettings)');
            var hasId = cols.any((c) => c['name'] == 'id');

            if (!hasId) {
              // الجدول قديم، نحتاج لترحيله
              // 1. إعادة تسمية الجدول القديم
              await db.execute(
                'ALTER TABLE $tableSettings RENAME TO settings_old',
              );

              // 2. إنشاء الجدول الجديد بالبنية الصحيحة
              await db.execute('''
                CREATE TABLE $tableSettings (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  key TEXT NOT NULL UNIQUE,
                  value TEXT,
                  firebase_id TEXT UNIQUE,
                  is_dirty INTEGER NOT NULL DEFAULT 0,
                  deleted_at TEXT,
                  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
              ''');

              // 3. نقل البيانات (key, value)
              await db.execute(
                'INSERT INTO $tableSettings (key, value) SELECT key, value FROM settings_old',
              );

              // 4. حذف الجدول القديم
              await db.execute('DROP TABLE settings_old');

              if (kDebugMode) {
                print('Migrated settings table to version 8 schema');
              }
            }
          } else {
            // الجدول غير موجود، ننشئه
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $tableSettings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT NOT NULL UNIQUE,
                value TEXT,
                firebase_id TEXT UNIQUE,
                is_dirty INTEGER NOT NULL DEFAULT 0,
                deleted_at TEXT,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
              )
            ''');
          }
        } catch (e) {
          if (kDebugMode) print('Error upgrading settings table: $e');
        }
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }

  // --- دوال التقارير ... (كما هي) ---
  Future<List<Map<String, dynamic>>> getRawBookingsForReport(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final String startStr = DateTime(
      start.year,
      start.month,
      start.day,
      0,
      0,
      0,
    ).toIso8601String();
    final String endStr = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    ).toIso8601String();

    return await db.rawQuery(
      '''
      SELECT b.*, p.name as pitch_name 
      FROM $tableBookings b
      JOIN $tablePitches p ON b.pitch_id = p.id
      WHERE b.start_time >= ? AND b.start_time <= ? AND b.status != 'cancelled'
      ORDER BY b.start_time ASC
    ''',
      [startStr, endStr],
    );
  }

  Future<List<Map<String, dynamic>>> getBookingsForDetailedReport(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final String startStr = DateTime(
      start.year,
      start.month,
      start.day,
      0,
      0,
      0,
    ).toIso8601String();
    final String endStr = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    ).toIso8601String();

    return await db.rawQuery(
      '''
      SELECT 
        b.*, 
        p.name as pitch_name,
        u.name as employee_name,
        c.name as coach_name
      FROM $tableBookings b
      JOIN $tablePitches p ON b.pitch_id = p.id
      LEFT JOIN $tableUsers u ON b.created_by_user_id = u.id
      LEFT JOIN $tableCoaches c ON b.coach_id = c.id
      WHERE b.start_time >= ? AND b.start_time <= ?
      ORDER BY b.start_time ASC
    ''',
      [startStr, endStr],
    );
  }

  Future<List<Map<String, dynamic>>> getApprovedDepositsForReport(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final String startStr = DateTime(
      start.year,
      start.month,
      start.day,
      0,
      0,
      0,
    ).toIso8601String();
    final String endStr = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    ).toIso8601String();

    return await db.query(
      tableDepositRequests,
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [startStr, endStr, 'approved'],
    );
  }

  // --- CRUD عامة ---
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    values['is_dirty'] = values['is_dirty'] ?? 1;
    values['updated_at'] =
        values['updated_at'] ?? DateTime.now().toIso8601String();
    return await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    final result = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    values['is_dirty'] = values['is_dirty'] ?? 1;
    values['updated_at'] =
        values['updated_at'] ?? DateTime.now().toIso8601String();
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  Future<void> rawExecute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  // --- دوال المزامنة ---
  Future<List<Map<String, dynamic>>> getDirtyRecords(String table) async {
    final db = await database;
    return await db.query(table, where: 'is_dirty = ?', whereArgs: [1]);
  }

  Future<void> markAsSynced(
    String table,
    int localId,
    String firebaseId,
  ) async {
    final db = await database;
    await db.update(
      table,
      {
        'is_dirty': 0,
        'firebase_id': firebaseId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> upsertFromCloud(String table, Map<String, dynamic> values) async {
    final db = await database;
    final String? firebaseId = values['firebase_id'];

    if (firebaseId == null) {
      return await insert(table, values);
    }

    // هنا قد نواجه مشكلة مع جدول settings لأنه قد يحتوي على سجلات موجودة محلياً بنفس الـ Key
    // لكن ليس لها firebase_id بعد. لذا نحتاج لمعالجة خاصة لجدول الإعدادات.
    if (table == tableSettings && values.containsKey('key')) {
      final key = values['key'];
      final List<Map<String, dynamic>> existingByKey = await db.query(
        table,
        columns: ['id'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (existingByKey.isNotEmpty) {
        // تحديث السجل الموجود بنفس المفتاح لربطه بالمعرف السحابي
        final int id = existingByKey.first['id'] as int;
        values['is_dirty'] = 0;
        values['updated_at'] =
            values['updated_at'] ?? DateTime.now().toIso8601String();
        await db.update(table, values, where: 'id = ?', whereArgs: [id]);
        return id;
      }
    }

    final List<Map<String, dynamic>> existing = await db.query(
      table,
      columns: ['id'],
      where: 'firebase_id = ?',
      whereArgs: [firebaseId],
      limit: 1,
    );

    values['is_dirty'] = 0;
    values['updated_at'] =
        values['updated_at'] ?? DateTime.now().toIso8601String();

    if (existing.isNotEmpty) {
      final int id = existing.first['id'] as int;
      await db.update(table, values, where: 'id = ?', whereArgs: [id]);
      return id;
    } else {
      return await db.insert(table, values);
    }
  }

  Future<int?> getLocalIdByFirebaseId(String table, String firebaseId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      table,
      columns: ['id'],
      where: 'firebase_id = ?',
      whereArgs: [firebaseId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  Future<bool> isPitchAvailable({
    required int pitchId,
    required String startTime,
    required String endTime,
    int? excludeBookingId,
  }) async {
    final db = await database;
    String where =
        "pitch_id = ? AND status != 'cancelled' AND (start_time < ? AND end_time > ?)";
    List<Object?> args = [pitchId, endTime, startTime];

    if (excludeBookingId != null) {
      where += " AND id != ?";
      args.add(excludeBookingId);
    }

    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM $tableBookings WHERE $where",
        args,
      ),
    );
    return (count ?? 0) == 0;
  }

  // --- دوال التوريد ---
  Future<List<Map<String, dynamic>>> getWorkerPaidUndepositedBookings(
    int userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT b.*, p.name as pitch_name 
      FROM $tableBookings b
      JOIN $tablePitches p ON b.pitch_id = p.id
      WHERE b.created_by_user_id = ? 
        AND b.status = 'paid' 
        AND b.is_deposited = 0
        AND (b.deleted_at IS NULL)
      ORDER BY b.start_time DESC
    ''',
      [userId],
    );
  }

  Future<int> getWorkerPendingBookingsCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM $tableBookings 
      WHERE created_by_user_id = ? 
        AND status = 'pending'
        AND (deleted_at IS NULL)
    ''',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markBookingsAsDeposited(List<int> bookingIds) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var id in bookingIds) {
        await txn.update(
          tableBookings,
          {
            'is_deposited': 1,
            'is_dirty': 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  // --- تهيئة الأدمن ---
  Future<void> seedAdminUser() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableUsers WHERE username = ?',
        ['admin'],
      );
      final bool adminExists = (result.first['count'] as int) > 0;
      final adminValues = {
        'name': 'مدير النظام',
        'username': 'admin',
        'password': '123456',
        'role': 'admin',
        'is_active': 1,
        'can_manage_pitches': 1,
        'can_manage_coaches': 1,
        'can_manage_bookings': 1,
        'can_view_reports': 1,
        'is_dirty': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (adminExists) {
        await db.update(
          tableUsers,
          adminValues,
          where: 'username = ?',
          whereArgs: ['admin'],
        );
      } else {
        await db.insert(tableUsers, adminValues);
      }
      if (kDebugMode) print('Database: Admin seeding completed successfully.');
    } catch (e) {
      if (kDebugMode) print('Database Error: Seeding failed: $e');
    }
  }
}
