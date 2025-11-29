// A small session manager that centralizes reading/writing the current user
// from SharedPreferences and allows checking login status synchronously.
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../../data/models/user.dart';

class SessionManager {
  SessionManager._private();
  static final SessionManager instance = SessionManager._private();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      if (userId != null) {
        final db = await DatabaseHelper().database;
        final map = await db.query(DatabaseHelper.tableUsers,
            where: 'id = ?', whereArgs: [userId], limit: 1);
        if (map.isNotEmpty) {
          _currentUser = User.fromMap(map.first);
        }
      }
    } catch (_) {
      _currentUser = null;
    }
  }

  Future<void> saveUser(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', user.id!);
    await prefs.setString('current_user_role', user.role);
    await prefs.setString('current_user_name', user.name);
    await prefs.setString('current_user_username', user.username);
  }

  Future<void> clear() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_role');
    await prefs.remove('current_user_name');
    await prefs.remove('current_user_username');
  }
}
