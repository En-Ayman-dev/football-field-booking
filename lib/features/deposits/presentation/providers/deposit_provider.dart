// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../data/models/deposit_request.dart';
import '../../../../data/models/user.dart';

class DepositProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<DepositRequest> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  DepositProvider({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  List<DepositRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchRequests({bool forAdmin = false, int? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String where = '';
      List<Object?> whereArgs = [];
      if (!forAdmin) {
        if (userId == null) {
          _requests = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
        where = 'user_id = ?';
        whereArgs = [userId];
      }

      final rows = await _dbHelper.getAll(
        DatabaseHelper.tableDepositRequests,
        where: where.isNotEmpty ? where : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );

      _requests = rows.map((r) => DepositRequest.fromMap(r)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching deposit requests: $e');
      _errorMessage = 'حدث خطأ أثناء تحميل طلبات التوريد.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest({required User user, required double amount, String? note}) async {
    try {
      final id = await _dbHelper.insert(DatabaseHelper.tableDepositRequests, {
        'user_id': user.id,
        'amount': amount,
        'note': note,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (id > 0) {
        await fetchRequests(forAdmin: false, userId: user.id);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error creating deposit request: $e');
      _errorMessage = 'تعذر إنشاء طلب التوريد.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRequestStatus({required int id, required String status, int? processedBy}) async {
    try {
      final values = {
        'status': status,
        'processed_by': processedBy,
        'processed_at': DateTime.now().toIso8601String(),
      };
      await _dbHelper.update(DatabaseHelper.tableDepositRequests, values, where: 'id = ?', whereArgs: [id]);
      // Update local cache if present
      final idx = _requests.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final updated = _requests[idx].copyWith(status: status, processedBy: processedBy, processedAt: DateTime.now());
        _requests[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating deposit request status: $e');
      _errorMessage = 'تعذر تحديث حالة الطلب.';
      notifyListeners();
      return false;
    }
  }
}
