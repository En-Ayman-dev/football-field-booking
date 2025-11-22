import 'package:flutter/foundation.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../data/models/ball.dart';
import '../../../../data/models/pitch.dart';

// import 'package:arena_manager/core/database/database_helper.dart';
// import 'package:arena_manager/data/models/pitch.dart';
// import 'package:arena_manager/data/models/ball.dart';

class PitchBallProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<Pitch> _pitches = [];
  List<Ball> _balls = [];
  bool _isLoading = false;
  String? _errorMessage;

  PitchBallProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  List<Pitch> get pitches => _pitches;
  List<Ball> get balls => _balls;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([_loadPitches(), _loadBalls()]);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading pitches & balls: $e');
      }
      _errorMessage = 'حدث خطأ أثناء تحميل البيانات.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPitches() async {
    final rows =
        await _dbHelper.getAll(DatabaseHelper.tablePitches, orderBy: 'id DESC');
    _pitches = rows.map((e) => Pitch.fromMap(e)).toList();
  }

  Future<void> _loadBalls() async {
    final rows =
        await _dbHelper.getAll(DatabaseHelper.tableBalls, orderBy: 'id DESC');
    _balls = rows.map((e) => Ball.fromMap(e)).toList();
  }

  Future<void> addOrUpdatePitch(Pitch pitch) async {
    try {
      if (pitch.id == null) {
        final id =
            await _dbHelper.insert(DatabaseHelper.tablePitches, pitch.toMap());
        final newPitch = pitch.copyWith(id: id);
        _pitches.insert(0, newPitch);
      } else {
        await _dbHelper.update(
          DatabaseHelper.tablePitches,
          pitch.toMap(),
          where: 'id = ?',
          whereArgs: [pitch.id],
        );
        final index = _pitches.indexWhere((p) => p.id == pitch.id);
        if (index != -1) {
          _pitches[index] = pitch;
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error addOrUpdatePitch: $e');
      }
      _errorMessage = 'تعذر حفظ بيانات الملعب.';
      notifyListeners();
    }
  }

  Future<void> deletePitch(int id) async {
    try {
      await _dbHelper.delete(
        DatabaseHelper.tablePitches,
        where: 'id = ?',
        whereArgs: [id],
      );
      _pitches.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deletePitch: $e');
      }
      _errorMessage = 'تعذر حذف الملعب.';
      notifyListeners();
    }
  }

  Future<void> togglePitchActive(Pitch pitch) async {
    final updated = pitch.copyWith(isActive: !pitch.isActive);
    await addOrUpdatePitch(updated);
  }

  Future<void> addOrUpdateBall(Ball ball) async {
    try {
      if (ball.id == null) {
        final id =
            await _dbHelper.insert(DatabaseHelper.tableBalls, ball.toMap());
        final newBall = ball.copyWith(id: id);
        _balls.insert(0, newBall);
      } else {
        await _dbHelper.update(
          DatabaseHelper.tableBalls,
          ball.toMap(),
          where: 'id = ?',
          whereArgs: [ball.id],
        );
        final index = _balls.indexWhere((b) => b.id == ball.id);
        if (index != -1) {
          _balls[index] = ball;
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error addOrUpdateBall: $e');
      }
      _errorMessage = 'تعذر حفظ بيانات الكرة.';
      notifyListeners();
    }
  }

  Future<void> deleteBall(int id) async {
    try {
      await _dbHelper.delete(
        DatabaseHelper.tableBalls,
        where: 'id = ?',
        whereArgs: [id],
      );
      _balls.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleteBall: $e');
      }
      _errorMessage = 'تعذر حذف الكرة.';
      notifyListeners();
    }
  }

  Future<void> toggleBallAvailable(Ball ball) async {
    final updated = ball.copyWith(isAvailable: !ball.isAvailable);
    await addOrUpdateBall(updated);
  }
}
