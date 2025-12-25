import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/models/daily_report_model.dart';

class ReportsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<DailyReport> _reports = [];
  List<DailyReport> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// الدالة الأساسية لتوليد التقارير بناءً على فترة زمنية
  Future<void> generateReports(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. جلب البيانات الخام من قاعدة البيانات
      final rawBookings = await _dbHelper.getRawBookingsForReport(startDate, endDate);
      final rawDeposits = await _dbHelper.getApprovedDepositsForReport(startDate, endDate);

      // 2. معالجة البيانات وتجميعها لكل يوم
      _reports = _processReports(startDate, endDate, rawBookings, rawDeposits);
      
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء إعداد التقرير: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<DailyReport> _processReports(
    DateTime start,
    DateTime end,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> deposits,
  ) {
    List<DailyReport> dailyReports = [];

    // التكرار عبر كل يوم في الفترة المحددة
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final currentDate = start.add(Duration(days: i));
      
      // تصفية الحجوزات الخاصة بهذا اليوم فقط
      final dayBookings = bookings.where((b) {
        final bStart = DateTime.parse(b['start_time']);
        return bStart.year == currentDate.year &&
               bStart.month == currentDate.month &&
               bStart.day == currentDate.day;
      }).toList();

      // تصفية التوريدات الخاصة بهذا اليوم فقط
      final dayDeposits = deposits.where((d) {
        final dDate = DateTime.parse(d['created_at']);
        return dDate.year == currentDate.year &&
               dDate.month == currentDate.month &&
               dDate.day == currentDate.day;
      }).toList();

      // متغيرات التجميع لليوم
      Map<int, double> pitchHoursMap = {};
      double totalDayHours = 0;
      double totalDayAmount = 0;
      double totalStaffWages = 0;
      double totalCoachWages = 0;
      int paidCount = 0;
      String dayNotes = "";

      for (var b in dayBookings) {
        final startTime = DateTime.parse(b['start_time']);
        final endTime = DateTime.parse(b['end_time']);
        final pitchId = b['pitch_id'] as int;
        
        // حساب الساعات (الفرق بالدقائق مقسوماً على 60 للحصول على القيمة العشرية)
        final double duration = endTime.difference(startTime).inMinutes / 60.0;
        
        pitchHoursMap[pitchId] = (pitchHoursMap[pitchId] ?? 0) + duration;
        totalDayHours += duration;
        
        // تجميع المبالغ (نحسب فقط الحجوزات المسددة أو حسب سياسة النظام)
        totalDayAmount += (b['total_price'] as num?)?.toDouble() ?? 0;
        totalStaffWages += (b['staff_wage'] as num?)?.toDouble() ?? 0;
        totalCoachWages += (b['coach_wage'] as num?)?.toDouble() ?? 0;
        
        if (b['status'] == 'paid') paidCount++;
        if (b['notes'] != null && b['notes'].toString().isNotEmpty) {
          dayNotes += "${b['notes']}. ";
        }
      }

      // إجمالي المبلغ المورد لهذا اليوم
      double totalDeposited = dayDeposits.fold(0.0, (prev, element) => prev + (element['amount'] as num).toDouble());

      // إنشاء كائن التقرير اليومي
      dailyReports.add(DailyReport(
        date: currentDate,
        pitchHours: pitchHoursMap,
        totalHours: totalDayHours,
        totalAmount: totalDayAmount,
        totalStaffWages: totalStaffWages,
        totalCoachWages: totalCoachWages,
        depositedAmount: totalDeposited,
        paidBookingsCount: paidCount,
        notes: dayNotes,
      ));
    }

    return dailyReports;
  }
}