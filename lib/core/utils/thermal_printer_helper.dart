import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../../features/reports/data/models/daily_report_model.dart';

class ThermalPrinterHelper {
  static BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // إعدادات عرض الصورة (380 مناسب لأغلب الطابعات 58mm و 80mm)
  static const int receiptWidth = 380;
  static const double baseFontSize = 20.0;
  static const double titleFontSize = 26.0;

  static Future<List<BluetoothDevice>> getPairedDevices() async {
    return await bluetooth.getBondedDevices();
  }

  // التحقق من الاتصال (تم الحفاظ على التحسين السابق)
  static Future<bool> connect(BluetoothDevice device) async {
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) return true;
      await bluetooth.connect(device);
      return true;
    } catch (e) {
      debugPrint("ThermalPrinterHelper: Connection Error -> $e");
      return false;
    }
  }

  // ===========================================================================
  // دالة طباعة التقارير (محولة لنظام الصور)
  // ===========================================================================
  static Future<void> printReport({
    required List<DailyReport> reports,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) return;

    final df = DateFormat('yyyy/MM/dd', 'ar');
    double totalRevenue = reports.fold(
      0,
      (sum, item) => sum + item.totalAmount,
    );

    // 1. توليد صورة التقرير
    final Uint8List imageBytes = await _generateReportImage(
      reports,
      totalRevenue,
      df.format(startDate),
      df.format(endDate),
    );

    // 2. إرسال الصورة للطابعة
    await bluetooth.printImageBytes(imageBytes);
    await bluetooth.printNewLine();
    await bluetooth.paperCut();
  }

  // ===========================================================================
  // دالة طباعة حجز فردي (محولة لنظام الصور)
  // ===========================================================================
  static Future<void> printSingleBooking({
    required String pitchName,
    required String customerName,
    required String date,
    required String startTime,
    required String endTime,
    required double amount,
    required bool isPaid,
    String? employeeName, // --- جديد: اسم الموظف ---
  }) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) return;

    // 1. توليد صورة الإيصال
    final Uint8List imageBytes = await _generateSingleBookingImage(
      pitchName: pitchName,
      customerName: customerName,
      date: date,
      startTime: startTime,
      endTime: endTime,
      amount: amount,
      isPaid: isPaid,
      employeeName: employeeName, // تمرير الاسم
    );

    // 2. إرسال الصورة للطابعة
    await bluetooth.printImageBytes(imageBytes);
    await bluetooth.printNewLine();
    await bluetooth.paperCut();
  }

  // ===========================================================================
  // محرك الرسم (القلب النابض للحل) - يقوم برسم البيانات كصورة
  // ===========================================================================

  /// رسم إيصال الحجز الفردي
  static Future<Uint8List> _generateSingleBookingImage({
    required String pitchName,
    required String customerName,
    required String date,
    required String startTime,
    required String endTime,
    required double amount,
    required bool isPaid,
    String? employeeName, // --- جديد ---
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final Paint paint = Paint()..color = Colors.white;

    // تقدير الطول: هيدر + 7 أسطر بيانات (أضفنا سطر المستخدم) + فوتر
    double height = 600.0; // زيادة الطول قليلاً
    canvas.drawRect(
      Rect.fromLTWH(0, 0, receiptWidth.toDouble(), height),
      paint,
    );

    double yOffset = 20.0;
    final logo = await _loadLogoFromAssets('assets/images/logo.jpg');
    yOffset = _drawLogo(canvas, logo, yOffset, targetWidth: 140);

    // العنوان
    yOffset = _drawText(
      canvas,
      "Arena Manager ",
      yOffset,
      fontSize: titleFontSize,
      isBold: true,
      isCentered: true,
    );
    yOffset = _drawText(
      canvas,
      " إيصال حجز ملعب نادي مدينة ذمار",
      yOffset,
      fontSize: 22,
      isBold: true,
      isCentered: true,
    );
    yOffset = _drawDivider(canvas, yOffset);

    // البيانات
    yOffset = _drawKeyValue(canvas, "الملعب:", pitchName, yOffset);
    yOffset = _drawKeyValue(canvas, "العميل:", customerName, yOffset);
    yOffset = _drawKeyValue(canvas, "التاريخ:", date, yOffset);
    yOffset = _drawKeyValue(canvas, "الوقت:", "$startTime - $endTime", yOffset);

    yOffset = _drawDivider(canvas, yOffset);

    // المبلغ والحالة
    yOffset = _drawText(
      canvas,
      "المبلغ المطلوب",
      yOffset,
      isCentered: true,
      fontSize: 18,
    );
    yOffset = _drawText(
      canvas,
      "${amount.toStringAsFixed(2)} ريال",
      yOffset,
      isCentered: true,
      isBold: true,
      fontSize: 28,
    );

    // --- إضافة اسم المستخدم (الموظف) هنا ليكون واضحاً ---
    if (employeeName != null && employeeName.isNotEmpty) {
      yOffset += 5;
      yOffset = _drawText(
        canvas,
        "المستخدم: $employeeName",
        yOffset,
        isCentered: true,
        fontSize: 18,
        isBold: true,
      ); // خط عريض وواضح
    }
    // ---------------------------------------------------

    String statusText = isPaid ? "تم السداد" : "غير مسدد";
    yOffset = _drawText(
      canvas,
      "الحالة: $statusText",
      yOffset,
      isCentered: true,
      fontSize: 20,
    );

    yOffset = _drawDivider(canvas, yOffset);
    _drawText(
      canvas,
      "نتمنى لكم وقتاً ممتعاً",
      yOffset,
      isCentered: true,
      fontSize: 16,
    );

    // تحويل الرسم إلى بايتات
    final picture = recorder.endRecording();
    final img = await picture.toImage(receiptWidth, height.toInt());
    // final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return await _toMonochromePng(img);
  }

  /// رسم تقرير العمليات
  static Future<Uint8List> _generateReportImage(
    List<DailyReport> reports,
    double totalRevenue,
    String start,
    String end,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final Paint paint = Paint()..color = Colors.white;

    // حساب الطول الديناميكي بناءً على عدد التقارير
    // هيدر (150) + (عدد التقارير * 60) + فوتر (100)
    double height = 300.0 + (reports.length * 70.0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, receiptWidth.toDouble(), height),
      paint,
    );

    double yOffset = 20.0;

    final logo = await _loadLogoFromAssets('assets/images/logo.jpg');
    yOffset = _drawLogo(canvas, logo, yOffset, targetWidth: 140);

    // الهيدر
    yOffset = _drawText(
      canvas,
      "Arena Manager",
      yOffset,
      fontSize: titleFontSize,
      isBold: true,
      isCentered: true,
    );
    yOffset = _drawText(
      canvas,
      "تقرير مالي نادي مدينة ذمار ",
      yOffset,
      fontSize: 22,
      isBold: true,
      isCentered: true,
    );
    yOffset = _drawText(
      canvas,
      "$start :إلى $end",
      yOffset,
      isCentered: true,
      fontSize: 16,
    );
    yOffset = _drawDivider(canvas, yOffset);

    // الجدول
    for (var report in reports) {
      yOffset = _drawKeyValue(
        canvas,
        report.formattedDate,
        "",
        yOffset,
        isBoldKey: true,
      );
      yOffset = _drawKeyValue(
        canvas,
        "الدخل:",
        report.totalAmount.toStringAsFixed(2),
        yOffset,
      );
      yOffset += 5; // مسافة صغيرة
      _drawDashedLine(canvas, yOffset);
      yOffset += 5;
    }

    // الفوتر
    yOffset += 10;
    yOffset = _drawDivider(canvas, yOffset);
    yOffset = _drawText(
      canvas,
      "الإجمالي الكلي",
      yOffset,
      isCentered: true,
      fontSize: 18,
    );
    yOffset = _drawText(
      canvas,
      "${totalRevenue.toStringAsFixed(2)} ريال",
      yOffset,
      isCentered: true,
      isBold: true,
      fontSize: 28,
    );
    _drawDivider(canvas, yOffset + 30);

    final picture = recorder.endRecording();
    final img = await picture.toImage(receiptWidth, height.toInt());
    // final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return await _toMonochromePng(img);

    // return byteData!.buffer.asUint8List();
  }

  // --- أدوات الرسم المساعدة ---

  static double _drawText(
    Canvas canvas,
    String text,
    double y, {
    bool isBold = false,
    bool isCentered = false,
    double fontSize = baseFontSize,
  }) {
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontFamily: 'Cairo', // استخدام خط التطبيق العربي
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.rtl, // ضروري جداً للعربية
      textAlign: isCentered ? TextAlign.center : TextAlign.right,
    );
    textPainter.layout(minWidth: 0, maxWidth: receiptWidth.toDouble());

    double x = isCentered
        ? (receiptWidth - textPainter.width) / 2
        : receiptWidth - textPainter.width - 10; // 10 margin right

    textPainter.paint(canvas, Offset(x, y));
    return y + textPainter.height + 5; // إرجاع الموقع الجديد
  }

  static double _drawKeyValue(
    Canvas canvas,
    String key,
    String value,
    double y, {
    bool isBoldKey = false,
  }) {
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: baseFontSize,
      fontFamily: 'Cairo',
      fontWeight: isBoldKey ? FontWeight.bold : FontWeight.normal,
    );

    // رسم المفتاح (يمين)
    final keyPainter = TextPainter(
      text: TextSpan(text: key, style: textStyle),
      textDirection: ui.TextDirection.rtl,
    );
    keyPainter.layout(maxWidth: receiptWidth / 2);
    keyPainter.paint(canvas, Offset(receiptWidth - keyPainter.width - 10, y));

    // رسم القيمة (يسار)
    final valuePainter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      textDirection: ui.TextDirection.ltr, // الأرقام والإنجليزي LTR
    );
    valuePainter.layout(maxWidth: receiptWidth / 2);
    valuePainter.paint(canvas, Offset(10, y));

    return y + keyPainter.height + 5;
  }

  static double _drawDivider(Canvas canvas, double y) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, y + 10),
      Offset(receiptWidth.toDouble(), y + 10),
      paint,
    );
    return y + 20;
  }

  static void _drawDashedLine(Canvas canvas, double y) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    double dashWidth = 5, dashSpace = 5, startX = 0;
    while (startX < receiptWidth) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  static Future<Uint8List> _toMonochromePng(ui.Image img) async {
    const int scale = 2; // 2 = أوضح وأثخن
    const int threshold = 150; // أقل = حبر أكثر/سمك أكثر

    // 1) تكبير الصورة (يركّز الحواف ويزيد سماكة الحرف بعد التحويل)
    final recorderUp = ui.PictureRecorder();
    final canvasUp = Canvas(recorderUp);
    canvasUp.scale(scale.toDouble(), scale.toDouble());
    canvasUp.drawImage(img, Offset.zero, Paint());
    final ui.Image highRes = await recorderUp.endRecording().toImage(
      img.width * scale,
      img.height * scale,
    );

    // 2) استخراج RGBA
    final byteData = await highRes.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final Uint8List rgba = byteData!.buffer.asUint8List();

    // 3) تحويل قوي إلى أبيض/أسود (Binarize)
    for (int i = 0; i < rgba.length; i += 4) {
      final int r = rgba[i];
      final int g = rgba[i + 1];
      final int b = rgba[i + 2];

      final int luma = ((r * 299) + (g * 587) + (b * 114)) ~/ 1000;
      final int v = (luma < threshold) ? 0 : 255;

      rgba[i] = v;
      rgba[i + 1] = v;
      rgba[i + 2] = v;
      rgba[i + 3] = 255;
    }

    // 4) تحويل البكسلات المعدلة إلى Image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      highRes.width,
      highRes.height,
      ui.PixelFormat.rgba8888,
      (ui.Image result) {
        completer.complete(result);
      },
    );
    final ui.Image monoHighRes = await completer.future;

    // 5) تصغير للصورة الأصلية (مع الحفاظ على سماكة أفضل)
    final recorderDown = ui.PictureRecorder();
    final canvasDown = Canvas(recorderDown);

    final src = Rect.fromLTWH(
      0,
      0,
      monoHighRes.width.toDouble(),
      monoHighRes.height.toDouble(),
    );
    final dst = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );

    canvasDown.drawImageRect(monoHighRes, src, dst, Paint());
    final ui.Image finalImg = await recorderDown.endRecording().toImage(
      img.width,
      img.height,
    );

    // 6) إخراج PNG
    final out = await finalImg.toByteData(format: ui.ImageByteFormat.png);
    return out!.buffer.asUint8List();
  }

  static ui.Image? _cachedLogo;

  static Future<ui.Image> _loadLogoFromAssets(String assetPath) async {
    if (_cachedLogo != null) return _cachedLogo!;
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _cachedLogo = frame.image;
    return _cachedLogo!;
  }

  static double _drawLogo(
    Canvas canvas,
    ui.Image logo,
    double y, {
    double targetWidth = 140, // عرض اللوجو على الورق
    double marginTop = 10,
    bool isCentered = true,
  }) {
    final double x = isCentered ? (receiptWidth - targetWidth) / 2 : 10;
    final double ratio = targetWidth / logo.width;
    final double targetHeight = logo.height * ratio;

    final src = Rect.fromLTWH(
      0,
      0,
      logo.width.toDouble(),
      logo.height.toDouble(),
    );
    final dst = Rect.fromLTWH(x, y + marginTop, targetWidth, targetHeight);

    canvas.drawImageRect(logo, src, dst, Paint());
    return y + marginTop + targetHeight + 10; // يرجع yOffset بعد اللوجو
  }
}
