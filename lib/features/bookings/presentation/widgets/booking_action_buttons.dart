// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/pdf_generator_helper.dart';
import '../../../../data/models/booking.dart';
import '../screens/booking_print_preview_screen.dart'; // استيراد شاشة المعاينة الجديدة

class BookingActionButtons {
  // دالة لعرض خيارات مقاسات الطباعة ثم الانتقال لشاشة المعاينة والربط بالطابعة
  static Future<void> showPrintOptions(
    BuildContext context, {
    required Booking booking,
    String? pitchName,
    String? coachName,
  }) async {
    final PrintSize? selectedSize = await showDialog<PrintSize>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('اختر مقاس الطباعة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('طابعة حرارية (80mm)'),
                  onTap: () => Navigator.pop(context, PrintSize.roll80mm),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('طابعة حرارية (72mm)'),
                  onTap: () => Navigator.pop(context, PrintSize.roll72mm),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('ورق A4'),
                  onTap: () => Navigator.pop(context, PrintSize.a4),
                ),
                ListTile(
                  leading: const Icon(Icons.note),
                  title: const Text('ورق A5'),
                  onTap: () => Navigator.pop(context, PrintSize.a5),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSize != null) {
      // الانتقال إلى شاشة المعاينة بدلاً من الطباعة المباشرة العمياء
      // هذه الشاشة توفر واجهة لفحص الاتصال واكتشاف الطابعات
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingPrintPreviewScreen(
            booking: booking,
            initialSize: selectedSize,
            pitchName: pitchName,
            coachName: coachName,
          ),
        ),
      );
    }
  }

  // دالة مشاركة الحجز كملف PDF
  static Future<void> shareBooking(
    Booking booking, {
    String? pitchName,
    String? coachName,
  }) async {
    // نستخدم مقاس A4 للمشاركة الافتراضية ليكون واضحاً
    final pdfBytes = await PdfGeneratorHelper.generateBookingPdf(
      booking: booking,
      size: PrintSize.a4,
      pitchName: pitchName,
      coachName: coachName,
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/booking_${booking.id}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'تفاصيل حجز فريق: ${booking.teamName ?? "بدون اسم"}',
    );
  }
}