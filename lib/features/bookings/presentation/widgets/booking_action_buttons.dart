// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui' as pw;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/pdf_generator_helper.dart';
import '../../../../core/utils/thermal_printer_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../data/models/booking.dart';
import '../../../../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../screens/booking_print_preview_screen.dart';
import '../screens/booking_form_screen.dart';

class BookingActionButtons {
  /// دالة شاملة لعرض خيارات إدارة الحجز (تسديد، تعديل، إلغاء، حذف، طباعة، مشاركة)
  static void showBookingOptions(
    BuildContext context, {
    required Booking booking,
    String? pitchName,
    String? coachName,
  }) {
    // التحقق من الصلاحيات والحالة
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.currentUser?.role == 'admin';
    final isCancelled = booking.status == 'cancelled';
    final isPaid = booking.status == 'paid';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // يسمح بالتحكم في التمرير وحجم الشيت
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: pw.TextDirection.rtl,
          // --- التعديل 1: إضافة SingleChildScrollView لمنع الـ Overflow ---
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20.sp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "إدارة الحجز #${booking.id}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  Text(
                    isCancelled ? "(ملغي)" : (isPaid ? "(مدفوع)" : "(معلق)"),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isCancelled
                          ? Colors.red
                          : (isPaid ? Colors.green : Colors.orange),
                    ),
                  ),
                  const Divider(),

                  // 1. زر تسديد المبلغ (يظهر فقط إذا كان الحجز معلقاً وغير ملغي)
                  if (!isPaid && !isCancelled)
                    ListTile(
                      leading: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                      title: const Text("تسديد المبلغ"),
                      subtitle: const Text("تحويل الحالة إلى مدفوع"),
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmAction(
                          context,
                          "تأكيد الدفع",
                          "هل تريد تحويل حالة هذا الحجز إلى مدفوع؟",
                          () {
                            Provider.of<BookingProvider>(
                              context,
                              listen: false,
                            ).updateBookingStatus(booking.id!, 'paid');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تم تسديد الحجز بنجاح"),
                              ),
                            );
                          },
                        );
                      },
                    ),

                  // 2. زر التعديل (معطل إذا كان الحجز ملغياً)
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text("تعديل الحجز"),
                    enabled: !isCancelled,
                    subtitle: isCancelled
                        ? const Text("لا يمكن تعديل حجز ملغي")
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (!isCancelled) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingFormScreen(existingBooking: booking),
                          ),
                        );
                      }
                    },
                  ),

                  // 3. زر الإلغاء (يظهر فقط إذا لم يكن ملغياً)
                  if (!isCancelled)
                    ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.orange),
                      title: const Text("إلغاء الحجز"),
                      subtitle: const Text(
                        "تحويل الحالة إلى ملغي (لا يُحسب مالياً)",
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmAction(
                          context,
                          "تأكيد الإلغاء",
                          "هل أنت متأكد من إلغاء هذا الحجز؟\nلن يتم احتساب سعره في التقارير ولن يحجز الوقت في الملعب.",
                          () {
                            Provider.of<BookingProvider>(
                              context,
                              listen: false,
                            ).updateBookingStatus(booking.id!, 'cancelled');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تم إلغاء الحجز بنجاح"),
                              ),
                            );
                          },
                        );
                      },
                    ),

                  // 4. زر الحذف النهائي (يظهر للأدمن فقط)
                  if (isAdmin)
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text("حذف نهائي"),
                      subtitle: const Text("صلاحية خاصة بالأدمن"),
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmAction(
                          context,
                          "حذف الحجز",
                          "هل أنت متأكد؟ سيتم حذف الحجز نهائياً من قاعدة البيانات ولا يمكن التراجع عنه.",
                          () {
                            Provider.of<BookingProvider>(
                              context,
                              listen: false,
                            ).deleteBooking(booking.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("تم حذف الحجز")),
                            );
                          },
                        );
                      },
                    ),

                  const Divider(),

                  // 5. خيارات الطباعة
                  ListTile(
                    leading: const Icon(Icons.print, color: Colors.purple),
                    title: const Text("طباعة الإيصال"),
                    onTap: () {
                      Navigator.pop(ctx);
                      showPrintOptions(
                        context,
                        booking: booking,
                        pitchName: pitchName,
                        coachName: coachName,
                      );
                    },
                  ),

                  // 6. خيارات المشاركة
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.green),
                    title: const Text("مشاركة PDF"),
                    onTap: () {
                      Navigator.pop(ctx);
                      shareBooking(
                        booking,
                        pitchName: pitchName,
                        coachName: coachName,
                      );
                    },
                  ),

                  // --- التعديل 2: إضافة مساحة في الأسفل ---
                  SizedBox(height: 30.sp),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// دالة مساعدة لتأكيد الإجراءات الحساسة
  static void _confirmAction(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: pw.TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("تراجع"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: const Text(
                "تأكيد",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            title: Text(
              'خيارات الطباعة',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // خيار الطباعة المباشرة عبر البلوتوث
                ListTile(
                  leading: const Icon(
                    Icons.bluetooth_connected,
                    color: Colors.teal,
                  ),
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
  static Future<void> _showThermalPrinterPicker(
    BuildContext context,
    Booking booking,
    String pitchName,
  ) async {
    // إظهار مؤشر تحميل صغير أثناء جلب الأجهزة
    List<BluetoothDevice> devices =
        await ThermalPrinterHelper.getPairedDevices();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp)),
      ),
      builder: (context) => Directionality(
        textDirection: pw.TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "اختر الطابعة المقترنة",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
              const Divider(),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "لا توجد أجهزة مقترنة. يرجى الاقتران من إعدادات الهاتف.",
                  ),
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
                      _connectAndPrintDirectly(
                        context,
                        devices[index],
                        booking,
                        pitchName,
                      );
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
  static Future<void> _connectAndPrintDirectly(
    BuildContext context,
    BluetoothDevice device,
    Booking booking,
    String pitchName,
  ) async {
    // 1. إعلام المستخدم ببدء العملية
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("جاري فحص حالة الطابعة..."),
        duration: Duration(seconds: 1),
      ),
    );

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("خطأ أثناء إرسال البيانات: $e")),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "فشل الاتصال بالطابعة. يرجى التحقق من تشغيل البلوتوث.",
            ),
            backgroundColor: Colors.red,
          ),
        );
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

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'تفاصيل حجز فريق: ${booking.teamName ?? "بدون اسم"}');
  }
}
