import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncUiHelper {
  /// دالة مساعدة لتنفيذ المزامنة (الرفع - Push) مع عرض واجهة التحميل
  /// [onSuccess] : دالة اختيارية تنفذ عند النجاح
  static Future<void> triggerSync(BuildContext context, {VoidCallback? onSuccess}) async {
    // 1. إظهار رسالة التحميل (غير قابلة للإغلاق)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("جاري رفع البيانات للسحابة...\nيرجى الانتظار")),
          ],
        ),
      ),
    );

    try {
      // 2. تنفيذ المزامنة
      await SyncService().syncNow();

      // 3. إغلاق Dialog والنجاح
      if (context.mounted) {
        Navigator.of(context).pop(); // إغلاق الـ Dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تمت مزامنة البيانات بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (onSuccess != null) onSuccess();
      }
    } catch (e) {
      // 4. التعامل مع الخطأ
      if (context.mounted) {
        Navigator.of(context).pop(); // إغلاق الـ Dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل المزامنة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}