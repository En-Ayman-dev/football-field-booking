import 'package:intl/intl.dart';

class DailyReport {
  final DateTime date;
  // خريطة لتخزين عدد الساعات لكل ملعب (ID الملعب -> عدد الساعات)
  final Map<int, double> pitchHours;
  final double totalHours;
  final double totalAmount;
  final double totalStaffWages;
  final double totalCoachWages;
  final double depositedAmount; // المبلغ المورد
  final int paidBookingsCount;
  final String notes;

  DailyReport({
    required this.date,
    required this.pitchHours,
    required this.totalHours,
    required this.totalAmount,
    required this.totalStaffWages,
    required this.totalCoachWages,
    required this.depositedAmount,
    required this.paidBookingsCount,
    this.notes = '',
  });

  // حساب المبلغ المتبقي (صافي الربح قبل التوريد أو بعده حسب المنطق المحاسبي)
  // المبلغ المتبقي = الإجمالي - (أجور العمال + أجور المدربين + المبلغ المورد)
  double get remainingAmount =>
      totalAmount - (totalStaffWages + totalCoachWages + depositedAmount);

  // جلب اسم اليوم باللغة العربية
  String get dayName {
    return DateFormat('EEEE', 'ar').format(date);
  }

  // جلب التاريخ المنسق
  String get formattedDate {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  // تحويل الساعات العشرية إلى تنسيق (ساعات:دقائق) للطباعة (مثلاً 2.5 -> 2:30)
  static String formatDecimalHours(double decimalHours) {
    int hours = decimalHours.floor();
    int minutes = ((decimalHours - hours) * 60).round();
    return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}