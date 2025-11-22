import 'package:flutter/foundation.dart';


import '../../../../core/database/database_helper.dart';
import '../../../../data/models/user.dart';

class StaffProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<User> _staff = [];
  bool _isLoading = false;
  String? _errorMessage;

  StaffProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  List<User> get staff => _staff;
  bool get isLoading => _isLoading;
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

  Future<void> addOrUpdateStaff(User user) async {
    try {
      if (user.id == null) {
        final id =
            await _dbHelper.insert(DatabaseHelper.tableUsers, user.toMap());
        final newUser = user.copyWith(id: id);
        _staff.insert(0, newUser);
      } else {
        await _dbHelper.update(
          DatabaseHelper.tableUsers,
          user.toMap(),
          where: 'id = ?',
          whereArgs: [user.id],
        );
        final index = _staff.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _staff[index] = user;
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error addOrUpdateStaff: $e');
      }
      _errorMessage = 'تعذر حفظ بيانات الموظف.';
      notifyListeners();
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

  Future<void> toggleStaffActive(User user) async {
    final updated = user.copyWith(isActive: !user.isActive);
    await addOrUpdateStaff(updated);
  }
}
