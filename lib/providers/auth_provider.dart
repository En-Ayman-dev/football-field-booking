// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:football_field_booking_1/data/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/session/session_manager.dart';

import '../core/database/database_helper.dart';



class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;

  /// تحميل المستخدم الحالي من SharedPreferences عند بدء التطبيق
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId != null) {
        final map =
            await _dbHelper.getById(DatabaseHelper.tableUsers, userId);
        if (map != null) {
          _currentUser = User.fromMap(map);
        } else {
          await _clearSession();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading current user: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل الدخول
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = await _dbHelper.database;

      final result = await db.query(
        DatabaseHelper.tableUsers,
        where: 'username = ? AND password = ? AND is_active = 1',
        whereArgs: [username, password],
        limit: 1,
      );

      if (result.isEmpty) {
        _currentUser = null;
        _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = User.fromMap(result.first);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', _currentUser!.id!);
      await prefs.setString('current_user_role', _currentUser!.role);
      await prefs.setString('current_user_name', _currentUser!.name);
      await prefs.setString('current_user_username', _currentUser!.username);

      // Update session manager so initial route decisions and other parts
      // of the app can read current user without repeating the database query.
      await SessionManager.instance.saveUser(_currentUser!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during login: $e');
      }
      _errorMessage = 'حدث خطأ أثناء محاولة تسجيل الدخول.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
    await SessionManager.instance.clear();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_role');
    await prefs.remove('current_user_name');
    await prefs.remove('current_user_username');
  }
}
