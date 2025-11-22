import 'package:flutter/foundation.dart';


import '../../../../core/database/database_helper.dart';
import '../../../../data/models/coach.dart';

class CoachesProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<Coach> _coaches = [];
  bool _isLoading = false;
  String? _errorMessage;

  CoachesProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  List<Coach> get coaches => _coaches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCoaches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _dbHelper.getAll(
        DatabaseHelper.tableCoaches,
        orderBy: 'id DESC',
      );
      _coaches = rows.map((e) => Coach.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading coaches: $e');
      }
      _errorMessage = 'حدث خطأ أثناء تحميل المدربين.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOrUpdateCoach(Coach coach) async {
    try {
      if (coach.id == null) {
        final id =
            await _dbHelper.insert(DatabaseHelper.tableCoaches, coach.toMap());
        final newCoach = coach.copyWith(id: id);
        _coaches.insert(0, newCoach);
      } else {
        await _dbHelper.update(
          DatabaseHelper.tableCoaches,
          coach.toMap(),
          where: 'id = ?',
          whereArgs: [coach.id],
        );
        final index = _coaches.indexWhere((c) => c.id == coach.id);
        if (index != -1) {
          _coaches[index] = coach;
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error addOrUpdateCoach: $e');
      }
      _errorMessage = 'تعذر حفظ بيانات المدرب.';
      notifyListeners();
    }
  }

  Future<void> deleteCoach(int id) async {
    try {
      await _dbHelper.delete(
        DatabaseHelper.tableCoaches,
        where: 'id = ?',
        whereArgs: [id],
      );
      _coaches.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleteCoach: $e');
      }
      _errorMessage = 'تعذر حذف المدرب.';
      notifyListeners();
    }
  }

  Future<void> toggleCoachActive(Coach coach) async {
    final updated = coach.copyWith(isActive: !coach.isActive);
    await addOrUpdateCoach(updated);
  }
}
