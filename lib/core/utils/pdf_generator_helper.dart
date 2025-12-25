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
  }) async {
    final pdf = pw.Document();

    // تحميل الخطوط محلياً (تأكد من وجودها في assets/fonts)
    final ByteData fontDataRegular = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ByteData fontDataBold = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    
    final arabicFont = pw.Font.ttf(fontDataRegular);
    final arabicFontBold = pw.Font.ttf(fontDataBold);

    final format = _getPageFormat(size);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min, // مهم جداً للطابعات الحرارية
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(booking, size),
                pw.Divider(thickness: 1),
                _buildInfoRow("اسم الفريق:", booking.teamName ?? "غير محدد"),
                _buildInfoRow("الهاتف:", booking.customerPhone ?? "غير محدد"),
                _buildInfoRow("الملعب:", pitchName ?? "رقم ${booking.pitchId}"),
                _buildInfoRow("التاريخ:", intl.DateFormat('yyyy-MM-dd').format(booking.startTime)),
                _buildInfoRow("الوقت:", "${intl.DateFormat('HH:mm').format(booking.startTime)} - ${intl.DateFormat('HH:mm').format(booking.endTime)}"),
                pw.SizedBox(height: 10),
                _buildInfoRow("السعر الإجمالي:", "${booking.totalPrice?.toStringAsFixed(2) ?? '0.00'} ريال", isBold: true),
                pw.Divider(),
                if (booking.notes != null && booking.notes!.isNotEmpty)
                  _buildInfoRow("ملاحظات:", booking.notes!),
                
                // تم استبدال pw.Spacer() بـ pw.SizedBox ثابت لحل مشكلة الارتفاع غير المحدود
                pw.SizedBox(height: 30), 
                
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text("شكراً لاختياركم ملاعبنا", style: pw.TextStyle(fontSize: 8)),
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
      case PrintSize.a4: return PdfPageFormat.a4;
      case PrintSize.a5: return PdfPageFormat.a5;
      // نستخدم ارتفاع infinity للإيصالات ولكن مع Column min-size
      case PrintSize.roll80mm: 
        return const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);
      case PrintSize.roll72mm: 
        return const PdfPageFormat(72 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);
    }
  }

  static pw.Widget _buildHeader(Booking booking, PrintSize size) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text("إيصال حجز ملعب", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text("رقم الحجز: #${booking.id ?? 'جديد'}", style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  static Future<void> previewAndPrint(Booking booking, PrintSize size, {String? pitchName, String? coachName}) async {
    final pdfData = await generateBookingPdf(
      booking: booking,
      size: size,
      pitchName: pitchName,
      coachName: coachName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Booking_${booking.id}.pdf',
    );
  }
}