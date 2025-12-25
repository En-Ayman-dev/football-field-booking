import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/pitch.dart';
import '../../features/reports/data/models/daily_report_model.dart';

class ReportPdfHelper {
  /// دالة داخلية خاصة لبناء هيكل المستند لتوحيد التصميم بين الطباعة والمشاركة
  static Future<pw.Document> _buildDocument({
    required List<DailyReport> reports,
    required List<Pitch> pitches,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final arabicFontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final arabicFontBoldData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    
    final pw.Font arabicFont = pw.Font.ttf(arabicFontData);
    final pw.Font arabicFontBold = pw.Font.ttf(arabicFontBoldData);

    final df = DateFormat('yyyy/MM/dd', 'ar');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginBottom: 1.0 * PdfPageFormat.cm,
          marginTop: 1.0 * PdfPageFormat.cm,
          marginLeft: 1.0 * PdfPageFormat.cm,
          marginRight: 1.0 * PdfPageFormat.cm,
        ),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (context) => [
          _buildHeader(df.format(startDate), df.format(endDate), arabicFontBold),
          pw.SizedBox(height: 10),
          _buildReportTable(reports, pitches, arabicFont, arabicFontBold),
          pw.SizedBox(height: 10),
          _buildFooter(reports, arabicFontBold),
        ],
      ),
    );
    return pdf;
  }

  /// وظيفة 1: توليد التقرير وعرضه للمعاينة والطباعة
  static Future<void> generateAndPrintReport({
    required List<DailyReport> reports,
    required List<Pitch> pitches,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = await _buildDocument(
      reports: reports, 
      pitches: pitches, 
      startDate: startDate, 
      endDate: endDate
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_شامل_${DateFormat('yyyy-MM-dd').format(startDate)}.pdf',
    );
  }

  /// وظيفة 2: توليد التقرير ومشاركته كملف عبر التطبيقات الأخرى
  static Future<void> shareReport({
    required List<DailyReport> reports,
    required List<Pitch> pitches,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = await _buildDocument(
      reports: reports, 
      pitches: pitches, 
      startDate: startDate, 
      endDate: endDate
    );

    final bytes = await pdf.save();
    
    // حفظ الملف بشكل مؤقت في ذاكرة الهاتف لتتمكن من مشاركته
    final tempDir = await getTemporaryDirectory();
    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // استدعاء واجهة المشاركة الخاصة بنظام التشغيل
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: 'تقرير مبيعات وحجوزات الملاعب - الفترة من ${DateFormat('yyyy/MM/dd').format(startDate)}',
    );
  }

  static pw.Widget _buildHeader(String start, String end, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تقرير مبيعات وحجوزات الملاعب التفصيلي',
          style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue900),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'من تاريخ: $start إلى: $end',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _buildReportTable(
    List<DailyReport> reports, 
    List<Pitch> pitches, 
    pw.Font font, 
    pw.Font boldFont
  ) {
    List<String> headers = ['اليوم / التاريخ'];
    for (var p in pitches) {
      headers.add(p.name);
    }
    headers.addAll([
      'مجموع\nالساعات',
      'الإجمالي',
      'أجور\nعمال',
      'أجور\nمدربين',
      'المورد',
      'المتبقي',
      'حجوزات',
      'ملاحظات'
    ]);

    final reversedHeaders = headers.reversed.toList();

    return pw.TableHelper.fromTextArray(
      headers: reversedHeaders,
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: pw.TextStyle(font: font, fontSize: 7.5),
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      data: reports.map((r) {
        List<String> row = ['${r.dayName}\n${r.formattedDate}'];
        for (var p in pitches) {
          row.add(DailyReport.formatDecimalHours(r.pitchHours[p.id] ?? 0.0));
        }
        row.addAll([
          DailyReport.formatDecimalHours(r.totalHours),
          r.totalAmount.toStringAsFixed(2),
          r.totalStaffWages.toStringAsFixed(2),
          r.totalCoachWages.toStringAsFixed(2),
          r.depositedAmount.toStringAsFixed(2),
          r.remainingAmount.toStringAsFixed(2),
          r.paidBookingsCount.toString(),
          r.notes.isEmpty ? '-' : r.notes,
        ]);
        return row.reversed.toList();
      }).toList(),
      columnWidths: {
        reversedHeaders.length - 1: const pw.FixedColumnWidth(60),
        0: const pw.FlexColumnWidth(2), 
      },
    );
  }

  static pw.Widget _buildFooter(List<DailyReport> reports, pw.Font boldFont) {
    final double totalNet = reports.fold(0, (sum, item) => sum + item.remainingAmount);
    final double totalDeposited = reports.fold(0, (sum, item) => sum + item.depositedAmount);
    final double totalRevenue = reports.fold(0, (sum, item) => sum + item.totalAmount);

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryText('إجمالي الدخل: ${totalRevenue.toStringAsFixed(2)}', boldFont),
          _summaryText('إجمالي المورد: ${totalDeposited.toStringAsFixed(2)}', boldFont),
          _summaryText(
            'صافي المتبقي: ${totalNet.toStringAsFixed(2)} ريال', 
            boldFont, 
            color: PdfColors.blue800
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryText(String text, pw.Font font, {PdfColor color = PdfColors.black}) {
    return pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: color),
    );
  }
}