import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;
import '../../../data/models/booking.dart';

enum PrintSize { a4, a5, roll80mm, roll72mm }

class PdfGeneratorHelper {
  static Future<Uint8List> generateBookingPdf({
    required Booking booking,
    required PrintSize size,
    String? pitchName,
    String? coachName,
    String? employeeName, // --- جديد: اسم الموظف ---
  }) async {
    final pdf = pw.Document();

    // تحميل الخطوط محلياً
    final ByteData fontDataRegular = await rootBundle.load(
      "assets/fonts/Cairo-Regular.ttf",
    );
    final ByteData fontDataBold = await rootBundle.load(
      "assets/fonts/Cairo-Bold.ttf",
    );

    // --- (جديد) تحميل شعار الملعب ---
    final ByteData logoData = await rootBundle.load("assets/images/logo.jpg");
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    // -------------------------------

    final arabicFont = pw.Font.ttf(fontDataRegular);
    final arabicFontBold = pw.Font.ttf(fontDataBold);

    final format = _getPageFormat(size);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min, // مهم جداً للطابعات الحرارية
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // تمرير الشعار للهيدر
                _buildHeader(booking, size, logoImage),

                pw.Divider(thickness: 1),
                _buildInfoRow("اسم الفريق:", booking.teamName ?? "غير محدد"),
                _buildInfoRow("الهاتف:", booking.customerPhone ?? "غير محدد"),
                _buildInfoRow("الملعب:", pitchName ?? "رقم ${booking.pitchId}"),
                _buildInfoRow(
                  "التاريخ:",
                  intl.DateFormat('yyyy-MM-dd').format(booking.startTime),
                ),
                _buildInfoRow(
                  "الوقت:",
                  "${intl.DateFormat('HH:mm').format(booking.startTime)} - ${intl.DateFormat('HH:mm').format(booking.endTime)}",
                ),
                pw.SizedBox(height: 10),
                _buildInfoRow(
                  "السعر الإجمالي:",
                  "${booking.totalPrice?.toStringAsFixed(2) ?? '0.00'} ريال",
                  isBold: true,
                ),

                // --- إضافة اسم المستخدم (الموظف) ---
                if (employeeName != null && employeeName.isNotEmpty)
                  _buildInfoRow("المستخدم:", employeeName),

                // -----------------------------------
                pw.Divider(),
                if (booking.notes != null && booking.notes!.isNotEmpty)
                  _buildInfoRow("ملاحظات:", booking.notes!),

                // تم استبدال pw.Spacer() بـ pw.SizedBox ثابت لحل مشكلة الارتفاع غير المحدود
                pw.SizedBox(height: 30),

                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "شكراً لاختياركم ملاعبنا",
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.SizedBox(height: 10), // مسافة أمان في نهاية الورقة
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static PdfPageFormat _getPageFormat(PrintSize size) {
    switch (size) {
      case PrintSize.a4:
        return PdfPageFormat.a4;
      case PrintSize.a5:
        return PdfPageFormat.a5;
      // نستخدم ارتفاع infinity للإيصالات ولكن مع Column min-size
      case PrintSize.roll80mm:
        return const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        );
      case PrintSize.roll72mm:
        return const PdfPageFormat(
          72 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        );
    }
  }

  // تم تعديل الدالة لاستقبال الشعار
  // استبدل دالة _buildHeader القديمة بهذه الدالة الجديدة
  static pw.Widget _buildHeader(
    Booking booking,
    PrintSize size,
    pw.MemoryImage logo,
  ) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // 1. الشعار (تم ضبط الحجم ليناسب الشعار العريض)
          pw.Container(
            height: 70,
            width: 200,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),

          pw.SizedBox(height: 5),

          // 2. اسم النادي (باللون الأزرق الداكن كما في الصورة)
          pw.Text(
            "نادي مدينة ذمار",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900, // لون مشابه للصورة
            ),
          ),

          // 3. الترفيهي الرياضي
          pw.Text(
            "الترفيهي الرياضي",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),

          pw.SizedBox(height: 4),

          // 4. أرقام التواصل
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              "للحجز والاستفسار: 737367059 - 781080577",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 5),

          // 5. عنوان الإيصال (تم تصغيره قليلاً ليكون ثانوياً)
          pw.Text(
            "رقم الحجز: #${booking.id ?? 'جديد'}",
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),

          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> previewAndPrint(
    Booking booking,
    PrintSize size, {
    String? pitchName,
    String? coachName,
    String? employeeName, // --- جديد: تمرير الاسم ---
  }) async {
    final pdfData = await generateBookingPdf(
      booking: booking,
      size: size,
      pitchName: pitchName,
      coachName: coachName,
      employeeName: employeeName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Booking_${booking.id}.pdf',
    );
  }
}
