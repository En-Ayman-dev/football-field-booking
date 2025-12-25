// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui' as pw;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; 
import '../../../../core/utils/pdf_generator_helper.dart';
import '../../../../core/utils/thermal_printer_helper.dart'; 
import '../../../../core/utils/responsive_helper.dart';
import '../../../../data/models/booking.dart';
import '../screens/booking_print_preview_screen.dart';

class BookingActionButtons {
  // دالة لعرض خيارات مقاسات الطباعة ثم الانتقال لشاشة المعاينة أو الطباعة المباشرة
  static Future<void> showPrintOptions(
    BuildContext context, {
    required Booking booking,
    String? pitchName,
    String? coachName,
  }) async {
    final dynamic selectedOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: pw.TextDirection.rtl,
          child: AlertDialog(
            title: Text('خيارات الطباعة', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // خيار الطباعة المباشرة عبر البلوتوث
                ListTile(
                  leading: const Icon(Icons.bluetooth_connected, color: Colors.teal),
                  title: const Text('طباعة حرارية مباشرة (Bluetooth)'),
                  subtitle: const Text('اتصال فوري وطباعة'),
                  onTap: () => Navigator.pop(context, 'direct_thermal'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('معاينة طابعة حرارية (80mm)'),
                  onTap: () => Navigator.pop(context, PrintSize.roll80mm),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('معاينة طابعة حرارية (72mm)'),
                  onTap: () => Navigator.pop(context, PrintSize.roll72mm),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('معاينة ورق A4'),
                  onTap: () => Navigator.pop(context, PrintSize.a4),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedOption == 'direct_thermal') {
      _showThermalPrinterPicker(context, booking, pitchName ?? "ملعب غير محدد");
    } else if (selectedOption is PrintSize) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingPrintPreviewScreen(
            booking: booking,
            initialSize: selectedOption,
            pitchName: pitchName,
            coachName: coachName,
          ),
        ),
      );
    }
  }

  /// حوار اختيار الطابعة الحرارية والاتصال بها
  static Future<void> _showThermalPrinterPicker(BuildContext context, Booking booking, String pitchName) async {
    // إظهار مؤشر تحميل صغير أثناء جلب الأجهزة
    List<BluetoothDevice> devices = await ThermalPrinterHelper.getPairedDevices();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp))),
      builder: (context) => Directionality(
        textDirection: pw.TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("اختر الطابعة المقترنة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              const Divider(),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("لا توجد أجهزة مقترنة. يرجى الاقتران من إعدادات الهاتف."),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(devices[index].name ?? "جهاز مجهول"),
                    onTap: () async {
                      Navigator.pop(context);
                      _connectAndPrintDirectly(context, devices[index], booking, pitchName);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تنفيذ الاتصال والطباعة الفورية مع معالجة الأخطاء المحسنة
  static Future<void> _connectAndPrintDirectly(BuildContext context, BluetoothDevice device, Booking booking, String pitchName) async {
    // 1. إعلام المستخدم ببدء العملية
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("جاري فحص حالة الطابعة..."),
      duration: Duration(seconds: 1),
    ));
    
    // 2. محاولة الاتصال (المحرك الآن يفحص إذا كان الجهاز متصلاً مسبقاً)
    bool connected = await ThermalPrinterHelper.connect(device);
    
    if (connected) {
      final timeFormat = DateFormat('HH:mm', 'ar');
      final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

      try {
        // 3. تنفيذ الطباعة
        await ThermalPrinterHelper.printSingleBooking(
          pitchName: pitchName,
          customerName: booking.teamName ?? "بدون اسم",
          date: dateFormat.format(booking.startTime),
          startTime: timeFormat.format(booking.startTime),
          endTime: timeFormat.format(booking.endTime),
          amount: booking.totalPrice ?? 0.0,
          isPaid: booking.status == 'paid',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ أثناء إرسال البيانات: $e")));
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("فشل الاتصال بالطابعة. يرجى التحقق من تشغيل البلوتوث."),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // دالة مشاركة الحجز كملف PDF
  static Future<void> shareBooking(
    Booking booking, {
    String? pitchName,
    String? coachName,
  }) async {
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