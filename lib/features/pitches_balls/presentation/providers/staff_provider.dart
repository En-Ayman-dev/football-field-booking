import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';


import '../../../../core/database/database_helper.dart';
import '../../../../data/models/user.dart';

class StaffProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<User> _staff = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  StaffProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  List<User> get staff => _staff;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _dbHelper.getAll(
        DatabaseHelper.tableUsers,
        where: 'role = ?',
        whereArgs: ['staff'],
        orderBy: 'id DESC',
      );
      _staff = rows.map((e) => User.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading staff: $e');
      }
      _errorMessage = 'حدث خطأ أثناء تحميل الموظفين.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any error message currently stored in the provider
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> addOrUpdateStaff(User user) async {
    if (_isSaving) {
      // Prevent concurrent save operations
      _errorMessage = 'جارٍ حفظ بيانات أخرى. الرجاء الانتظار.';
      notifyListeners();
      return false;
    }
    _isSaving = true;
    notifyListeners();
    try {
      // Run unique-check + insert/update inside a single DB transaction to
      // avoid race conditions (and avoid nested DatabaseHelper calls which
      // use the same DB instance and can deadlock under contention).
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        // Ensure username is unique (except for the same record on update)
        final rows = await txn.query(
          DatabaseHelper.tableUsers,
          where: 'username = ?',
          whereArgs: [user.username],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final existingUser = User.fromMap(rows.first);
          if (user.id == null || existingUser.id != user.id) {
            // Throw to abort the transaction and be handled below
            throw Exception('UNIQUE_USERNAME');
          }
        }

        if (user.id == null) {
          if (kDebugMode) {
            print('Inserting user map: ${user.toMap()}');
          }
          final id = await txn.insert(
            DatabaseHelper.tableUsers,
            user.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          final newUser = user.copyWith(id: id);
          _staff.insert(0, newUser);
        } else {
          if (kDebugMode) {
            print('Updating user id ${user.id} with map: ${user.toMap()}');
          }
          final updatedCount = await txn.update(
            DatabaseHelper.tableUsers,
            user.toMap(),
            where: 'id = ?',
            whereArgs: [user.id],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          if (updatedCount > 0) {
            final index = _staff.indexWhere((u) => u.id == user.id);
            if (index != -1) {
              _staff[index] = user;
            }
          }
        }
      });
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        print('Error addOrUpdateStaff: $e');
        print(st);
      }
      if (e.toString().contains('UNIQUE') || e.toString().contains('unique')) {
        _errorMessage = 'اسم المستخدم موجود مسبقًا. الرجاء اختيار اسم مستخدم آخر.';
      } else {
        // For debugging we may show the underlying DB message while in debug mode
        _errorMessage = kDebugMode ? 'تعذر حفظ بيانات الموظف. (خطأ: ${e.toString()})' : 'تعذر حفظ بيانات الموظف.';
      }
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteStaff(int id) async {
    try {
      await _dbHelper.delete(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [id],
      );
      _staff.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleteStaff: $e');
      }
      _errorMessage = 'تعذر حذف الموظف.';
      notifyListeners();
    }
  }

  Future<bool> toggleStaffActive(User user) async {
    final updated = user.copyWith(isActive: !user.isActive);
    return await addOrUpdateStaff(updated);
  }
}
