import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // قائمة الجداول التي نريد مزامنتها
  final List<String> _tablesToSync = [
    DatabaseHelper.tableUsers,
    DatabaseHelper.tablePitches,
    DatabaseHelper.tableCoaches,
    DatabaseHelper.tableBalls,
    DatabaseHelper.tableBookings,
    DatabaseHelper.tableDepositRequests,
  ];

  /// دالة المزامنة الرئيسية (Delta Sync)
  /// تقوم فقط برفع البيانات التي تغيرت محلياً (is_dirty = 1)
  Future<void> syncNow() async {
    try {
      debugPrint("🔄 Start Syncing (Delta Sync)...");

      for (String table in _tablesToSync) {
        await _syncTable(table);
      }

      debugPrint("✅ Sync Completed Successfully.");
    } catch (e) {
      debugPrint("❌ Sync Failed: $e");
      rethrow; // نعيد رمي الخطأ ليتم التعامل معه في الواجهة
    }
  }

  /// منطق مزامنة جدول واحد
  Future<void> _syncTable(String tableName) async {
    // 1. جلب السجلات المعدلة فقط
    final dirtyRecords = await _dbHelper.getDirtyRecords(tableName);

    if (dirtyRecords.isEmpty) {
      debugPrint("Table [$tableName] is up to date.");
      return;
    }

    debugPrint("Found ${dirtyRecords.length} changes in [$tableName] to sync.");

    final CollectionReference collection = _firestore.collection(tableName);

    for (var record in dirtyRecords) {
      try {
        final int localId = record['id'];
        String? firebaseId = record['firebase_id'];
        final String? deletedAt = record['deleted_at'];

        // أخذ نسخة من البيانات وحذف الحقول التي لا نريد رفعها (مثل id المحلي)
        Map<String, dynamic> dataToUpload = Map.from(record);
        dataToUpload.remove('id'); 
        dataToUpload.remove('is_dirty');

        // حالة 1: السجل محذوف محلياً (Soft Delete)
        if (deletedAt != null) {
          if (firebaseId != null) {
            // نحذفه من الفايربيس أيضاً أو نحدث حالته
            await collection.doc(firebaseId).update({'deleted_at': deletedAt});
          }
          // نحدث المحلي بأنه متزامن
          await _dbHelper.markAsSynced(tableName, localId, firebaseId ?? 'deleted');
          continue;
        }

        // حالة 2: السجل جديد (ليس له firebase_id)
        if (firebaseId == null) {
          // إضافة مستند جديد والحصول على الـ ID
          DocumentReference docRef = await collection.add(dataToUpload);
          firebaseId = docRef.id;
          
          // تحديث السجل المحلي بالـ ID الجديد
          await _dbHelper.markAsSynced(tableName, localId, firebaseId);
          debugPrint("Created new record in [$tableName] -> Cloud ID: $firebaseId");
        } 
        // حالة 3: السجل موجود مسبقاً (تحديث)
        else {
          await collection.doc(firebaseId).set(dataToUpload, SetOptions(merge: true));
          await _dbHelper.markAsSynced(tableName, localId, firebaseId);
          debugPrint("Updated record in [$tableName] -> Cloud ID: $firebaseId");
        }

      } catch (e) {
        debugPrint("Error syncing record ID ${record['id']} in $tableName: $e");
        // نستمر في الحلقة ولا نوقف العملية بالكامل بسبب سجل واحد فاسد
      }
    }
  }
}