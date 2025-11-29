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
  // Bump version when schema changes. Increment to trigger onUpgrade for existing DBs.
  static const int _databaseVersion = 4;

  // أسماء الجداول
  static const String tableUsers = 'users';
  static const String tableCoaches = 'coaches';
  static const String tablePitches = 'pitches';
  static const String tableBalls = 'balls';
  static const String tableBookings = 'bookings';
  static const String tableSyncStatus = 'sync_status';

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
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول المدربين
    batch.execute('''
      CREATE TABLE $tableCoaches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        specialization TEXT,
        price_per_hour REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول الملاعب
    batch.execute('''
      CREATE TABLE $tablePitches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        price_per_hour REAL,
        is_indoor INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول الكرات
    batch.execute('''
      CREATE TABLE $tableBalls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        size TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        is_available INTEGER NOT NULL DEFAULT 1,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // جدول الحجوزات (محدّث)
    batch.execute('''
      CREATE TABLE $tableBookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        is_dirty INTEGER NOT NULL DEFAULT 0,
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
      CREATE TABLE $tableSyncStatus (
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

    await batch.commit();
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // تنفيذ ترحيل آمن عند ترقية النسخة.
    // مثال: إضافة عمود `wage_per_booking` إلى جدول `users` إذا لم يكن موجودًا.
    if (newVersion > oldVersion) {
      // تحقق مما إذا كان العمود موجودًا بالفعل
      try {
        final info = await db.rawQuery('PRAGMA table_info($tableUsers)');
        final hasWage = info.any((col) => (col['name'] as String?) == 'wage_per_booking');
        if (!hasWage) {
          if (kDebugMode) print('Adding column wage_per_booking to $tableUsers');
          await db.execute('ALTER TABLE $tableUsers ADD COLUMN wage_per_booking REAL');
        }

        // These columns were added in later schema changes. Ensure they exist
        // for databases upgraded from older versions.
        final hasCanManagePitches = info.any((col) => (col['name'] as String?) == 'can_manage_pitches');
        if (!hasCanManagePitches) {
          if (kDebugMode) print('Adding column can_manage_pitches to $tableUsers');
          await db.execute('ALTER TABLE $tableUsers ADD COLUMN can_manage_pitches INTEGER NOT NULL DEFAULT 0');
        }

        final hasCanManageCoaches = info.any((col) => (col['name'] as String?) == 'can_manage_coaches');
        if (!hasCanManageCoaches) {
          if (kDebugMode) print('Adding column can_manage_coaches to $tableUsers');
          await db.execute('ALTER TABLE $tableUsers ADD COLUMN can_manage_coaches INTEGER NOT NULL DEFAULT 0');
        }

        final hasCanManageBookings = info.any((col) => (col['name'] as String?) == 'can_manage_bookings');
        if (!hasCanManageBookings) {
          if (kDebugMode) print('Adding column can_manage_bookings to $tableUsers');
          await db.execute('ALTER TABLE $tableUsers ADD COLUMN can_manage_bookings INTEGER NOT NULL DEFAULT 0');
        }

        final hasCanViewReports = info.any((col) => (col['name'] as String?) == 'can_view_reports');
        if (!hasCanViewReports) {
          if (kDebugMode) print('Adding column can_view_reports to $tableUsers');
          await db.execute('ALTER TABLE $tableUsers ADD COLUMN can_view_reports INTEGER NOT NULL DEFAULT 0');
        }
      } catch (e) {
        // Do not fail the upgrade because of a secondary issue. If needed,
        // more robust logging could be added here.
        if (kDebugMode) print('Error while applying user table upgrades: $e');
      }

      // Also ensure bookings has the required new columns (staff_wage, coach_wage, period)
      try {
        final bookingInfo = await db.rawQuery('PRAGMA table_info($tableBookings)');
        final hasStaffWage = bookingInfo.any((col) => (col['name'] as String?) == 'staff_wage');
        if (!hasStaffWage) {
          if (kDebugMode) print('Adding column staff_wage to $tableBookings');
          await db.execute('ALTER TABLE $tableBookings ADD COLUMN staff_wage REAL');
        }

        final hasCoachWage = bookingInfo.any((col) => (col['name'] as String?) == 'coach_wage');
        if (!hasCoachWage) {
          if (kDebugMode) print('Adding column coach_wage to $tableBookings');
          await db.execute('ALTER TABLE $tableBookings ADD COLUMN coach_wage REAL');
        }

        final hasPeriod = bookingInfo.any((col) => (col['name'] as String?) == 'period');
        if (!hasPeriod) {
          if (kDebugMode) print('Adding column period to $tableBookings');
          await db.execute('ALTER TABLE $tableBookings ADD COLUMN period TEXT');
        }
      } catch (e) {
        if (kDebugMode) print('Error while applying bookings table upgrades: $e');
      }
      
      // For older DBs, ensure any additional columns used by Booking model exist.
      try {
        final bookingInfo = await db.rawQuery('PRAGMA table_info($tableBookings)');
        final expectedColumns = <String, String>{
          'team_name': 'TEXT',
          'customer_phone': 'TEXT',
        };

        for (final entry in expectedColumns.entries) {
          final name = entry.key;
          final colType = entry.value;
          final hasCol = bookingInfo.any((c) => (c['name'] as String?) == name);
          if (!hasCol) {
            if (kDebugMode) print('Adding column $name to $tableBookings');
            await db.execute('ALTER TABLE $tableBookings ADD COLUMN $name $colType');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error while applying bookings optional columns: $e');
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

  // CRUD عامة

  Future<int> insert(
    String table,
    Map<String, dynamic> values,
  ) async {
    final db = await database;

    values['is_dirty'] = values['is_dirty'] ?? 1;
    values['updated_at'] =
        values['updated_at'] ?? DateTime.now().toIso8601String();

    if (kDebugMode) {
      print('DB insert -> table: $table, values: $values');
    }
    final id = await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (kDebugMode) {
      print('DB insert <- id: $id');
    }
    return id;
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
    if (kDebugMode) {
      print('DB query -> table: $table, where: $where, args: $whereArgs, orderBy: $orderBy');
    }
    final rows = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    if (kDebugMode) {
      print('DB query <- rows: ${rows.length}');
    }
    return rows;
  }

  Future<Map<String, dynamic>?> getById(
    String table,
    int id,
  ) async {
    final db = await database;
    final result = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
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

    if (kDebugMode) {
      print('DB update -> table: $table, values: $values, where: $where, whereArgs: $whereArgs');
    }
    final result = await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (kDebugMode) {
      print('DB update <- result: $result');
    }
    return result;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    if (kDebugMode) {
      print('DB delete -> table: $table, where: $where, whereArgs: $whereArgs');
    }
    final result = await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    if (kDebugMode) {
      print('DB delete <- result: $result');
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  Future<void> rawExecute(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  // Seed Admin
  Future<void> seedAdminUser() async {
    final db = await database;
    // Try to find an existing admin by username. If it exists update it to ensure
    // the seeded credentials are set; otherwise insert a new admin record.
    final existingAdmin = await db.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    final adminValues = {
      'name': 'مدير النظام',
      'username': 'admin',
      'password': '123456',
      'phone': null,
      'email': null,
      'role': 'admin',
      'is_active': 1,
      'wage_per_booking': null,
      'can_manage_pitches': 1,
      'can_manage_coaches': 1,
      'can_manage_bookings': 1,
      'can_view_reports': 1,
      'is_dirty': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existingAdmin.isNotEmpty) {
      if (kDebugMode) print('Updating existing admin user to seeded credentials: ${existingAdmin.first}');
      await db.update(
        tableUsers,
        adminValues,
        where: 'username = ?',
        whereArgs: ['admin'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      final id = await db.insert(
      tableUsers,
        adminValues,
      conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (kDebugMode) print('Inserted admin user with id: $id');
    }
  }
}
