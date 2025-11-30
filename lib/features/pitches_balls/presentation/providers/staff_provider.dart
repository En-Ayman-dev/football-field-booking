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
      _errorMessage = 'جارٍ حفظ بيانات أخرى. الرجاء الانتظار.';
      notifyListeners();
      return false;
    }
    _isSaving = true;
    notifyListeners();

    try {
      final db = await _dbHelper.database;

      // 1. التحقق من تكرار اسم المستخدم (خارج المعاملة لتبسيط الأمور)
      final List<Map<String, dynamic>> existingUsers = await db.query(
        DatabaseHelper.tableUsers,
        where: 'username = ?',
        whereArgs: [user.username],
        limit: 1,
      );

      if (existingUsers.isNotEmpty) {
        final existingUser = User.fromMap(existingUsers.first);
        // إذا كان معرف المستخدم مختلفاً، فهذا يعني أنه مستخدم آخر بنفس الاسم
        if (user.id == null || existingUser.id != user.id) {
          _errorMessage = 'اسم المستخدم موجود مسبقًا. الرجاء اختيار اسم مستخدم آخر.';
          _isSaving = false;
          notifyListeners();
          return false;
        }
      }

      // 2. تنفيذ الإضافة أو التحديث
      if (user.id == null) {
        if (kDebugMode) {
          print('Inserting NEW user: ${user.toMap()}');
        }
        
        final id = await db.insert(
          DatabaseHelper.tableUsers,
          user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (id > 0) {
          final newUser = user.copyWith(id: id);
          _staff.insert(0, newUser);
          if (kDebugMode) print('User inserted successfully with ID: $id');
        } else {
          throw Exception('Insert failed, ID is 0 or less');
        }

      } else {
        if (kDebugMode) {
          print('Updating user ID ${user.id}: ${user.toMap()}');
        }

        final updatedCount = await db.update(
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
          if (kDebugMode) print('User updated successfully. Rows affected: $updatedCount');
        }
      }

      _isSaving = false;
      notifyListeners();
      return true;

    } catch (e) {
      if (kDebugMode) {
        print('Error addOrUpdateStaff: $e');
      }
      _errorMessage = 'تعذر حفظ بيانات الموظف.';
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