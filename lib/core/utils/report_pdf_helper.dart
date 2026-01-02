// ignore_for_file: deprecated_member_use

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
import '../../features/reports/presentation/providers/reports_provider.dart'; // لاستيراد الموديلات التفصيلية

class ReportPdfHelper {
  // --- تحميل الخطوط والصور (Singleton لتقليل الحمل) ---
  static pw.Font? _arabicFont;
  static pw.Font? _arabicFontBold;
  static pw.MemoryImage? _logoImage;

  static Future<void> _loadResources() async {
    if (_arabicFont != null) return;

    final arabicFontData = await rootBundle.load(
      "assets/fonts/Cairo-Regular.ttf",
    );
    final arabicFontBoldData = await rootBundle.load(
      "assets/fonts/Cairo-Bold.ttf",
    );
    final logoData = await rootBundle.load("assets/images/logo.jpg");

    _arabicFont = pw.Font.ttf(arabicFontData);
    _arabicFontBold = pw.Font.ttf(arabicFontBoldData);
    _logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  }

  // ==========================================================
  // 1. التقرير العام (اليومي) - تم تحديثه للهيكلية الجديدة
  // ==========================================================

  static Future<void> generateAndPrintReport({
    required List<DailyReport> reports,
    required List<Pitch> pitches,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _loadResources();
    final pdf = await _buildGeneralDocument(
      reports,
      pitches,
      startDate,
      endDate,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'تقرير_عام_${DateFormat('yyyy-MM-dd').format(startDate)}.pdf',
    );
  }

  static Future<void> shareReport({
    required List<DailyReport> reports,
    required List<Pitch> pitches,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _loadResources();
    final pdf = await _buildGeneralDocument(
      reports,
      pitches,
      startDate,
      endDate,
    );
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/report_general.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'التقرير اليومي العام');
  }

  static Future<pw.Document> _buildGeneralDocument(
    List<DailyReport> reports,
    List<Pitch> pitches,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();
    final df = DateFormat('yyyy/MM/dd', 'ar');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginBottom: 0.5 * PdfPageFormat.cm,
          marginTop: 0.5 * PdfPageFormat.cm,
          marginLeft: 0.5 * PdfPageFormat.cm,
          marginRight: 0.5 * PdfPageFormat.cm,
        ),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont!,
          bold: _arabicFontBold!,
        ),
        build: (context) => [
          _buildHeader(
            'تقرير مبيعات وحجوزات الملاعب (يومي)',
            df.format(start),
            df.format(end),
            _arabicFontBold!,
            _logoImage!,
          ),
          pw.SizedBox(height: 5),
          _buildGeneralTable(reports, pitches, _arabicFont!, _arabicFontBold!),
          pw.SizedBox(height: 5),
          _buildGeneralFooter(reports, _arabicFontBold!),
        ],
      ),
    );
    return pdf;
  }

  // ==========================================================
  // 2. التقرير التفصيلي (الجديد) - الاحترافي
  // ==========================================================

  static Future<void> generateAndPrintDetailedReport({
    required List<EmployeeDetailedReport> employees,
    required List<CoachDetailedReport> coaches,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _loadResources();
    final pdf = await _buildDetailedDocument(
      employees,
      coaches,
      startDate,
      endDate,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'تقرير_تفصيلي_${DateFormat('yyyy-MM-dd').format(startDate)}.pdf',
    );
  }

  static Future<void> shareDetailedReport({
    required List<EmployeeDetailedReport> employees,
    required List<CoachDetailedReport> coaches,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _loadResources();
    final pdf = await _buildDetailedDocument(
      employees,
      coaches,
      startDate,
      endDate,
    );
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/report_detailed.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'التقرير التفصيلي للموظفين والمدربين');
  }

  static Future<pw.Document> _buildDetailedDocument(
    List<EmployeeDetailedReport> employees,
    List<CoachDetailedReport> coaches,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();
    final df = DateFormat('yyyy/MM/dd', 'ar');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, // Portrait للكشف الطويل
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont!,
          bold: _arabicFontBold!,
        ),
        build: (context) => [
          _buildHeader(
            'كشف حساب تفصيلي (موظفين / مدربين)',
            df.format(start),
            df.format(end),
            _arabicFontBold!,
            _logoImage!,
          ),
          pw.SizedBox(height: 20),

          // 1. قسم الموظفين
          pw.Text(
            'أولاً: كشف حساب الموظفين',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.TableHelper.fromTextArray(
            headers: [
              'الموظف',
              'عدد الحجوزات',
              'إجمالي المبيعات',
              'الأجر المستحق',
              'حجوزات ملغاة',
              'غير مورد (عدد)',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            data: employees
                .map(
                  (e) => [
                    e.name,
                    e.paidBookingsCount.toString(),
                    '${e.totalSales.toStringAsFixed(2)} ريال',
                    '${e.totalWages.toStringAsFixed(2)} ريال',
                    e.cancelledBookings.isNotEmpty
                        ? e.cancelledBookings.join(', ')
                        : '-',
                    e.pendingDepositionCount > 0
                        ? '${e.pendingDepositionCount}'
                        : '-',
                  ],
                )
                .toList(),
          ),

          pw.SizedBox(height: 20),

          // 2. قسم المدربين
          pw.Text(
            'ثانياً: كشف حساب المدربين',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.TableHelper.fromTextArray(
            headers: ['المدرب', 'عدد الحصص التدريبية', 'إجمالي الأجر المستحق'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.orange800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            data: coaches
                .map(
                  (c) => [
                    c.name,
                    c.bookingsCount.toString(),
                    '${c.totalWages.toStringAsFixed(2)} ريال',
                  ],
                )
                .toList(),
          ),

          pw.SizedBox(height: 30),

          // 3. الملخص الختامي
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'إجمالي أجور الموظفين:  ${employees.fold(0.0, (s, e) => s + e.totalWages).toStringAsFixed(2)} ريال',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'إجمالي أجور المدربين:  ${coaches.fold(0.0, (s, c) => s + c.totalWages).toStringAsFixed(2)} ريال',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تم الاستخراج في: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  // ==========================================================
  // Helpers (مكونات مشتركة)
  // ==========================================================

  static pw.Widget _buildHeader(
    String title,
    String start,
    String end,
    pw.Font boldFont,
    pw.MemoryImage logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 18,
            color: PdfColors.blue900,
          ),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 2),
        pw.Container(
          height: 100,
          width: 350,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),

        pw.SizedBox(height: 5),

        pw.Text(
          'من تاريخ: $start   إلى: $end',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 5),
        pw.Divider(thickness: 1.5, color: PdfColors.blue900),
      ],
    );
  }

  static pw.Widget _buildGeneralTable(
    List<DailyReport> reports,
    List<Pitch> pitches,
    pw.Font font,
    pw.Font boldFont,
  ) {
    List<String> headers = ['اليوم / التاريخ'];
    for (var p in pitches) {
      headers.add(p.name);
    }
    // --- تعديل العناوين للأعمدة الجديدة ---
    headers.addAll([
      'ساعات\n(ص)',
      'ساعات\n(م)',
      'إجمالي\n(ص)',
      'إجمالي\n(م)',
      'الإجمالي\nالكلي',
      'أجور\nعمال',
      'أجور\nمدربين',
      'المورد',
      'المتبقي',
      'حجوزات',
      'ملاحظات',
    ]);

    // بما أننا نستخدم RTL، يجب عكس الترتيب ليتوافق مع الجدول العربي
    // ولكن في PDF Helper، اتجاه Column هو RTL، لذا قد لا نحتاج لعكس القوائم يدوياً إذا كانت TableHelper تدعم ذلك
    // لكن للأمان وللتوافق مع الكود السابق، سنعكس القائمة لتظهر الأعمدة من اليمين لليسار
    final reversedHeaders = headers.reversed.toList();

    return pw.TableHelper.fromTextArray(
      headers: reversedHeaders,
      headerStyle: pw.TextStyle(
        font: boldFont,
        fontSize: 7, // تصغير الخط قليلاً لاستيعاب الأعمدة الكثيرة
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: pw.TextStyle(font: font, fontSize: 6.5), // تصغير الخط للخلايا
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      data: reports.map((r) {
        List<String> row = ['${r.dayName}\n${r.formattedDate}'];
        for (var p in pitches) {
          row.add(DailyReport.formatDecimalHours(r.pitchHours[p.id] ?? 0.0));
        }
        // --- إضافة البيانات الجديدة ---
        row.addAll([
          DailyReport.formatDecimalHours(r.totalMorningHours),
          DailyReport.formatDecimalHours(r.totalEveningHours),
          r.totalMorningAmount.toStringAsFixed(0), // بدون كسور لتوفير المساحة
          r.totalEveningAmount.toStringAsFixed(0),
          r.totalAmount.toStringAsFixed(0),
          r.totalStaffWages.toStringAsFixed(0),
          r.totalCoachWages.toStringAsFixed(0),
          r.depositedAmount.toStringAsFixed(0),
          r.remainingAmount.toStringAsFixed(0),
          r.paidBookingsCount.toString(),
          r.notes.isEmpty ? '-' : r.notes,
        ]);
        return row.reversed.toList();
      }).toList(),
      columnWidths: {
        reversedHeaders.length - 1: const pw.FixedColumnWidth(50), // الملاحظات
        0: const pw.FlexColumnWidth(2), // التاريخ
      },
    );
  }

  static pw.Widget _buildGeneralFooter(
    List<DailyReport> reports,
    pw.Font boldFont,
  ) {
    final double totalNet = reports.fold(
      0,
      (sum, item) => sum + item.remainingAmount,
    );
    final double totalDeposited = reports.fold(
      0,
      (sum, item) => sum + item.depositedAmount,
    );
    final double totalRevenue = reports.fold(
      0,
      (sum, item) => sum + item.totalAmount,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryText(
            'إجمالي الدخل: ${totalRevenue.toStringAsFixed(2)}',
            boldFont,
          ),
          _summaryText(
            'إجمالي المورد: ${totalDeposited.toStringAsFixed(2)}',
            boldFont,
          ),
          _summaryText(
            'صافي المتبقي: ${totalNet.toStringAsFixed(2)} ريال',
            boldFont,
            color: PdfColors.blue800,
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryText(
    String text,
    pw.Font font, {
    PdfColor color = PdfColors.black,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    );
  }
}
