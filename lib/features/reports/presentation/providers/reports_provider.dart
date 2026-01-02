import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/models/daily_report_model.dart';

class ReportsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- التقرير العام (القديم) ---
  List<DailyReport> _reports = [];
  List<DailyReport> get reports => _reports;

  // --- التقرير التفصيلي (الجديد) ---
  List<EmployeeDetailedReport> _employeeReports = [];
  List<CoachDetailedReport> _coachReports = [];

  List<EmployeeDetailedReport> get employeeReports => _employeeReports;
  List<CoachDetailedReport> get coachReports => _coachReports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// الدالة الأساسية لتوليد التقرير العام (اليومي)
  Future<void> generateReports(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawBookings = await _dbHelper.getRawBookingsForReport(
        startDate,
        endDate,
      );
      final rawDeposits = await _dbHelper.getApprovedDepositsForReport(
        startDate,
        endDate,
      );

      _reports = _processReports(startDate, endDate, rawBookings, rawDeposits);
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء إعداد التقرير العام: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// الدالة الجديدة لتوليد التقرير التفصيلي (موظفين ومدربين)
  Future<void> generateDetailedReports(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. جلب البيانات الشاملة (تشمل الملغاة والموظفين والمدربين)
      final rawData = await _dbHelper.getBookingsForDetailedReport(
        startDate,
        endDate,
      );

      // 2. تصفير القوائم القديمة
      _employeeReports = [];
      _coachReports = [];

      // 3. خرائط للتجميع
      Map<int, EmployeeDetailedReport> employeesMap = {};
      Map<int, CoachDetailedReport> coachesMap = {};

      for (var row in rawData) {
        // --- معالجة بيانات الموظف ---
        final userId = row['created_by_user_id'] as int;
        final userName = row['employee_name'] as String? ?? 'مستخدم #$userId';
        final status = row['status'] as String; // paid, pending, cancelled
        final isDeposited = (row['is_deposited'] as int? ?? 0) == 1;
        final bookingId = row['id'] as int;

        // التأكد من وجود الموظف في الخريطة
        if (!employeesMap.containsKey(userId)) {
          employeesMap[userId] = EmployeeDetailedReport(
            id: userId,
            name: userName,
            totalSales: 0,
            totalWages: 0,
            paidBookingsCount: 0,
            cancelledBookings: [],
            pendingDepositionCount: 0,
          );
        }

        final empReport = employeesMap[userId]!;

        if (status == 'cancelled') {
          empReport.cancelledBookings.add(bookingId);
        } else if (status == 'paid') {
          final price = (row['total_price'] as num?)?.toDouble() ?? 0.0;
          final wage =
              (row['staff_wage'] as num?)?.toDouble() ??
              0.0; // أجر الموظف عن هذا الحجز

          empReport.totalSales += price;
          empReport.totalWages += wage; // نجمع الأجر فقط إذا كان مدفوعاً
          empReport.paidBookingsCount++;

          if (!isDeposited) {
            empReport.pendingDepositionCount++;
          }
        } else {
          // الحالات الأخرى (pending)
          // يمكن إضافتها هنا إذا أردت إحصاءها
        }

        // --- معالجة بيانات المدرب ---
        final coachId = row['coach_id'] as int?;
        if (coachId != null) {
          final coachName = row['coach_name'] as String? ?? 'مدرب #$coachId';

          if (!coachesMap.containsKey(coachId)) {
            coachesMap[coachId] = CoachDetailedReport(
              id: coachId,
              name: coachName,
              totalWages: 0,
              bookingsCount: 0,
            );
          }

          final coachReport = coachesMap[coachId]!;
          // نجمع أجر المدرب سواء دفع الزبون أم لا (حسب سياستك، هنا افترضنا الاستحقاق بمجرد الحجز إلا إذا ألغي)
          // أو يمكن جعله مشروطاً بـ status != 'cancelled'
          if (status != 'cancelled') {
            final cWage = (row['coach_wage'] as num?)?.toDouble() ?? 0.0;
            coachReport.totalWages += cWage;
            coachReport.bookingsCount++;
          }
        }
      }

      // تحويل الخرائط إلى قوائم
      _employeeReports = employeesMap.values.toList();
      _coachReports = coachesMap.values.toList();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء إعداد التقرير التفصيلي: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- (الدالة المعدلة لمعالجة التقرير اليومي) ---
  List<DailyReport> _processReports(
    DateTime start,
    DateTime end,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> deposits,
  ) {
    List<DailyReport> dailyReports = [];

    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final currentDate = start.add(Duration(days: i));

      final dayBookings = bookings.where((b) {
        final bStart = DateTime.parse(b['start_time']);
        return bStart.year == currentDate.year &&
            bStart.month == currentDate.month &&
            bStart.day == currentDate.day;
      }).toList();

      final dayDeposits = deposits.where((d) {
        final dDate = DateTime.parse(d['created_at']);
        return dDate.year == currentDate.year &&
            dDate.month == currentDate.month &&
            dDate.day == currentDate.day;
      }).toList();

      Map<int, double> pitchHoursMap = {};

      // --- المتغيرات الجديدة للتفصيل ---
      double totalMorningHours = 0;
      double totalEveningHours = 0;
      double totalMorningAmount = 0;
      double totalEveningAmount = 0;
      // ---------------------------------

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

        final double duration = endTime.difference(startTime).inMinutes / 60.0;
        final double price = (b['total_price'] as num?)?.toDouble() ?? 0;
        final String? period = b['period'] as String?; // جلب الفترة

        // تجميع الساعات لكل ملعب
        pitchHoursMap[pitchId] = (pitchHoursMap[pitchId] ?? 0) + duration;

        // --- المنطق الجديد: التوزيع حسب الفترة ---
        if (period == 'morning') {
          totalMorningHours += duration;
          totalMorningAmount += price;
        } else if (period == 'evening') {
          totalEveningHours += duration;
          totalEveningAmount += price;
        } else {
          // في حال لم تحدد فترة (بيانات قديمة)، نعتبرها افتراضياً مع المسائي أو الصباحي حسب الوقت
          // أو نضيفها للإجمالي فقط. هنا سنضيفها حسب ساعة البدء كحل ذكي
          if (startTime.hour < 12) {
            totalMorningHours += duration;
            totalMorningAmount += price;
          } else {
            totalEveningHours += duration;
            totalEveningAmount += price;
          }
        }
        // ----------------------------------------

        totalDayHours += duration;
        totalDayAmount += price;
        totalStaffWages += (b['staff_wage'] as num?)?.toDouble() ?? 0;
        totalCoachWages += (b['coach_wage'] as num?)?.toDouble() ?? 0;

        if (b['status'] == 'paid') paidCount++;
        if (b['notes'] != null && b['notes'].toString().isNotEmpty) {
          dayNotes += "${b['notes']}. ";
        }
      }

      double totalDeposited = dayDeposits.fold(
        0.0,
        (prev, element) => prev + (element['amount'] as num).toDouble(),
      );

      dailyReports.add(
        DailyReport(
          date: currentDate,
          pitchHours: pitchHoursMap,
          // تمرير القيم المفصلة الجديدة
          totalMorningHours: totalMorningHours,
          totalEveningHours: totalEveningHours,
          totalMorningAmount: totalMorningAmount,
          totalEveningAmount: totalEveningAmount,
          // القيم الإجمالية
          totalHours: totalDayHours,
          totalAmount: totalDayAmount,
          totalStaffWages: totalStaffWages,
          totalCoachWages: totalCoachWages,
          depositedAmount: totalDeposited,
          paidBookingsCount: paidCount,
          notes: dayNotes,
        ),
      );
    }

    return dailyReports;
  }
}

// --- نماذج البيانات الخاصة بالتقرير التفصيلي (Internal Models) ---

class EmployeeDetailedReport {
  final int id;
  final String name;
  double totalSales; // إجمالي المبيعات التي حققها
  double totalWages; // إجمالي أجوره المستحقة
  int paidBookingsCount; // عدد الحجوزات المدفوعة
  List<int> cancelledBookings; // أرقام الحجوزات الملغاة
  int pendingDepositionCount; // عدد الحجوزات المدفوعة التي لم تورد بعد

  EmployeeDetailedReport({
    required this.id,
    required this.name,
    required this.totalSales,
    required this.totalWages,
    required this.paidBookingsCount,
    required this.cancelledBookings,
    required this.pendingDepositionCount,
  });
}

class CoachDetailedReport {
  final int id;
  final String name;
  double totalWages; // إجمالي أجور التدريب
  int bookingsCount; // عدد الحجوزات التي درب فيها

  CoachDetailedReport({
    required this.id,
    required this.name,
    required this.totalWages,
    required this.bookingsCount,
  });
}
