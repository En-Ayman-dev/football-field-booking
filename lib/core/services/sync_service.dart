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
  // ملاحظة: الترتيب هنا مهم جداً عند الاستيراد (Pull) لضمان صحة العلاقات (Foreign Keys)
  final List<String> _tablesToSync = [
    DatabaseHelper.tableSettings, // <-- تمت إضافة جدول الإعدادات كأولوية
    DatabaseHelper.tableUsers,
    DatabaseHelper.tablePitches,
    DatabaseHelper.tableCoaches,
    DatabaseHelper.tableBalls,
    DatabaseHelper.tableBookings,
    DatabaseHelper.tableDepositRequests,
  ];

  /// دالة المزامنة (رفع التغييرات المحلية إلى السحابة)
  Future<void> syncNow() async {
    try {
      debugPrint("🔄 Start Syncing (Push Delta)...");

      for (String table in _tablesToSync) {
        await _syncTable(table);
      }

      debugPrint("✅ Sync Completed Successfully.");
    } catch (e) {
      debugPrint("❌ Sync Failed: $e");
      rethrow;
    }
  }

  /// دالة جلب البيانات من السحابة (استيراد كامل)
  /// تستخدم لاستعادة البيانات أو مزامنة جهاز جديد
  Future<void> pullFromCloud() async {
    try {
      debugPrint("📥 Start Pulling from Cloud (Full Restore)...");

      for (String table in _tablesToSync) {
        await _pullTable(table);
      }

      debugPrint("✅ Pull Completed Successfully.");
    } catch (e) {
      debugPrint("❌ Pull Failed: $e");
      rethrow;
    }
  }

  /// منطق مزامنة جدول واحد (Push)
  Future<void> _syncTable(String tableName) async {
    final dirtyRecords = await _dbHelper.getDirtyRecords(tableName);

    if (dirtyRecords.isEmpty) {
      // debugPrint("Table [$tableName] is up to date.");
      return;
    }

    debugPrint("Found ${dirtyRecords.length} changes in [$tableName] to sync.");

    final CollectionReference collection = _firestore.collection(tableName);

    for (var record in dirtyRecords) {
      try {
        final int localId = record['id'];
        String? firebaseId = record['firebase_id'];
        final String? deletedAt = record['deleted_at'];

        Map<String, dynamic> dataToUpload = Map.from(record);
        dataToUpload.remove('id');
        dataToUpload.remove('is_dirty');

        // حالة 1: السجل محذوف محلياً
        if (deletedAt != null) {
          if (firebaseId != null) {
            await collection.doc(firebaseId).update({'deleted_at': deletedAt});
          }
          await _dbHelper.markAsSynced(
            tableName,
            localId,
            firebaseId ?? 'deleted',
          );
          continue;
        }

        // حالة 2: سجل جديد
        if (firebaseId == null) {
          DocumentReference docRef = await collection.add(dataToUpload);
          firebaseId = docRef.id;

          await _dbHelper.markAsSynced(tableName, localId, firebaseId);
          debugPrint(
            "Created new record in [$tableName] -> Cloud ID: $firebaseId",
          );
        }
        // حالة 3: تحديث سجل موجود
        else {
          await collection
              .doc(firebaseId)
              .set(dataToUpload, SetOptions(merge: true));
          await _dbHelper.markAsSynced(tableName, localId, firebaseId);
          debugPrint("Updated record in [$tableName] -> Cloud ID: $firebaseId");
        }
      } catch (e) {
        debugPrint("Error syncing record ID ${record['id']} in $tableName: $e");
      }
    }
  }

  /// منطق جلب جدول واحد من السحابة (Pull)
  Future<void> _pullTable(String tableName) async {
    try {
      final CollectionReference collection = _firestore.collection(tableName);
      // نجلب فقط البيانات غير المحذوفة (أو يمكنك جلب الكل والتحقق من deleted_at محلياً)
      // هنا سنجلب الكل للتبسيط ونترك DatabaseHelper يتعامل مع deleted_at إذا وجد
      final QuerySnapshot snapshot = await collection.get();

      if (snapshot.docs.isEmpty) {
        debugPrint("Cloud table [$tableName] is empty.");
        return;
      }

      debugPrint(
        "📥 Fetching [$tableName]: Found ${snapshot.docs.length} records.",
      );

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['firebase_id'] = doc.id; // نضمن وجود المعرف السحابي

        // معالجة الحقول الخاصة (مثل Timestamp)
        // SQLite لا تدعم كائنات Timestamp الخاصة بفايربيس، لذا نحولها لنص
        final keys = data.keys.toList();
        for (var key in keys) {
          final value = data[key];
          if (value is Timestamp) {
            data[key] = value.toDate().toIso8601String();
          }
        }

        // استدعاء دالة الدمج الذكي في قاعدة البيانات
        await _dbHelper.upsertFromCloud(tableName, data);
      }
    } catch (e) {
      debugPrint("Error pulling table [$tableName]: $e");
      rethrow;
    }
  }
}
