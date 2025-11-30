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

  Future<bool> login(String inputName, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedInput = inputName.trim();
    final normalizedPassword = password.trim();

    try {
      final db = await _dbHelper.database;
      
      // البحث باسم المستخدم أو الاسم الكامل
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableUsers,
        where: 'username = ? OR name = ?',
        whereArgs: [normalizedInput, normalizedInput],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        // محاولة تحويل البيانات (هنا كان يحدث الانهيار سابقاً)
        final user = User.fromMap(maps.first);

        if (user.password == normalizedPassword) {
          if (!user.isActive) {
            _errorMessage = 'عذراً، هذا الحساب تم تعطيله.';
            _isLoading = false;
            notifyListeners();
            return false;
          }

          _currentUser = user;
          await SessionManager.instance.saveUser(user);

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'كلمة المرور غير صحيحة.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'لا يوجد حساب بهذا الاسم.';
      }
    } catch (e) {
      // ⚠️ هام: عرض رسالة الخطأ الحقيقية للمستخدم للمساعدة في التشخيص
      _errorMessage = 'خطأ نظام (APK Error): $e';
      if (kDebugMode) print('Database login error: $e');
    }

    // حساب الطوارئ
    if (normalizedInput == 'admin' && normalizedPassword == '123456') {
      _currentUser = User(
        id: 1,
        name: 'مدير النظام (طوارئ)',
        username: 'admin',
        password: '123456',
        phone: null,
        email: null,
        role: 'admin',
        isActive: true,
        wagePerBooking: null,
        canManagePitches: true,
        canManageCoaches: true,
        canManageBookings: true,
        canViewReports: true,
        isDirty: false,
        updatedAt: DateTime.now(),
      );
      
      try {
        await SessionManager.instance.saveUser(_currentUser!);
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    }

    if (_errorMessage == null) {
       _errorMessage = 'بيانات الدخول غير صحيحة.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

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