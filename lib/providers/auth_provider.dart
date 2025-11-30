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
  /// تسجيل الدخول (وضع طوارئ: بدون قاعدة بيانات)
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedUsername = username.trim();

      // ✅ حساب الأدمن الثابت: يدخل بدون أي تعامل مع قاعدة البيانات
      if (normalizedUsername == 'admin' && password == '123456') {
        _currentUser = User(
          id: 1,
          name: 'مدير النظام',
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

        _isLoading = false;
        notifyListeners();
        return true;
      }

      // باقي الحسابات (لو عندك عملاء/موظفين ثانيين) نعتبرها الآن غير صحيحة
      _currentUser = null;
      _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error during login (emergency mode): $e');
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
