// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';



import '../../../../core/database/database_helper.dart';
import '../../../../data/models/ball.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/coach.dart';
import '../../../../data/models/pitch.dart';
import '../../../../data/models/user.dart';

class BookingProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<Pitch> _pitches = [];
  List<Ball> _balls = [];
  List<Coach> _coaches = [];

  bool _isLoading = false;
  String? _errorMessage;

  BookingProvider(DatabaseHelper databaseHelper, {DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  List<Pitch> get pitches => _pitches;
  List<Ball> get balls => _balls;
  List<Coach> get coaches => _coaches;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pitchesRows = await _dbHelper.getAll(
        DatabaseHelper.tablePitches,
        where: 'is_active = 1',
        orderBy: 'name ASC',
      );
      final ballsRows = await _dbHelper.getAll(
        DatabaseHelper.tableBalls,
        where: 'is_available = 1',
        orderBy: 'name ASC',
      );
      final coachesRows = await _dbHelper.getAll(
        DatabaseHelper.tableCoaches,
        where: 'is_active = 1',
        orderBy: 'name ASC',
      );

      _pitches = pitchesRows.map((e) => Pitch.fromMap(e)).toList();
      _balls = ballsRows.map((e) => Ball.fromMap(e)).toList();
      _coaches = coachesRows.map((e) => Coach.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading booking data: $e');
      }
      _errorMessage = 'حدث خطأ أثناء تحميل بيانات الحجز.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// (مدة الحجز بالساعات * سعر الساعة للملعب)
  double calculateTotalPrice({
    required double durationHours,
    required double pitchPricePerHour,
  }) {
    if (durationHours <= 0 || pitchPricePerHour <= 0) {
      return 0;
    }
    return durationHours * pitchPricePerHour;
  }

  /// (مدة الحجز * أجر المدرب بالساعة)
  double calculateCoachWage({
    required double durationHours,
    required double coachPricePerHour,
  }) {
    if (durationHours <= 0 || coachPricePerHour <= 0) {
      return 0;
    }
    return durationHours * coachPricePerHour;
  }

  /// أجر العامل لكل حجز (من الموديل نفسه، لا يعتمد على المدة)
  double? calculateStaffWage({
    required User staffUser,
  }) {
    return staffUser.wagePerBooking;
  }

  /// تحويل المبلغ إلى نص عربي بسيط (جزء صحيح فقط)
  String amountToArabicWords(double amount, {String currency = 'ريال'}) {
    final intValue = amount.round();
    if (intValue == 0) {
      return 'صفر $currency';
    }

    final units = [
      '',
      'واحد',
      'اثنان',
      'ثلاثة',
      'أربعة',
      'خمسة',
      'ستة',
      'سبعة',
      'ثمانية',
      'تسعة',
    ];
    final tens = [
      '',
      'عشرة',
      'عشرون',
      'ثلاثون',
      'أربعون',
      'خمسون',
      'ستون',
      'سبعون',
      'ثمانون',
      'تسعون',
    ];
    final teens = [
      'عشرة',
      'أحد عشر',
      'اثنا عشر',
      'ثلاثة عشر',
      'أربعة عشر',
      'خمسة عشر',
      'ستة عشر',
      'سبعة عشر',
      'ثمانية عشر',
      'تسعة عشر',
    ];

    String convertBelowHundred(int n) {
      if (n < 10) {
        return units[n];
      } else if (n < 20) {
        return teens[n - 10];
      } else {
        final t = n ~/ 10;
        final u = n % 10;
        if (u == 0) {
          return tens[t];
        } else {
          return '${units[u]} و ${tens[t]}';
        }
      }
    }

    String convertBelowThousand(int n) {
      final h = n ~/ 100;
      final r = n % 100;
      String result = '';
      if (h > 0) {
        if (h == 1) {
          result = 'مائة';
        } else if (h == 2) {
          result = 'مائتان';
        } else if (h >= 3 && h <= 9) {
          result = '${units[h]} مائة';
        }
      }
      if (r > 0) {
        final belowHundred = convertBelowHundred(r);
        if (result.isEmpty) {
          result = belowHundred;
        } else {
          result = '$belowHundred و $result';
        }
      }
      return result;
    }

    String words;
    if (intValue < 1000) {
      words = convertBelowThousand(intValue);
    } else if (intValue < 1000000) {
      final thousands = intValue ~/ 1000;
      final remainder = intValue % 1000;
      String thousandsPart;
      if (thousands == 1) {
        thousandsPart = 'ألف';
      } else if (thousands == 2) {
        thousandsPart = 'ألفان';
      } else if (thousands >= 3 && thousands <= 10) {
        thousandsPart = '${convertBelowThousand(thousands)} آلاف';
      } else {
        thousandsPart = '${convertBelowThousand(thousands)} ألف';
      }
      if (remainder == 0) {
        words = thousandsPart;
      } else {
        words = '$thousandsPart و ${convertBelowThousand(remainder)}';
      }
    } else {
      // للمبالغ الكبيرة جداً نكتفي بالتنسيق الرقمي
      final f = NumberFormat.decimalPattern('ar');
      return '${f.format(amount)} $currency';
    }

    return '$words $currency';
  }

  /// حفظ الحجز في قاعدة البيانات مع حساب السعر والأجور
  ///
  /// - createdByUser: الموظف الذي قام بالحجز
  /// - pitch: الملعب المختار
  /// - coach: المدرب (اختياري)
  /// - ball: الكرة (اختيارية)
  /// - durationHours: المدة بالساعات
  /// - isPaid: true => "حفظ ودفع" ، false => "حفظ كمعلق"
  Future<int?> createBooking({
    required User createdByUser,
    required Pitch pitch,
    Ball? ball,
    Coach? coach,
    required DateTime startDateTime,
    required double durationHours,
    required String? teamName,
    required String? customerPhone,
    required String? period,
    String? notes,
    bool isPaid = false,
  }) async {
    try {
      final endDateTime = startDateTime.add(
        Duration(
          minutes: (durationHours * 60).round(),
        ),
      );

      final pitchPricePerHour = pitch.pricePerHour ?? 0;
      final totalPrice = calculateTotalPrice(
        durationHours: durationHours,
        pitchPricePerHour: pitchPricePerHour,
      );

      double? coachWage;
      if (coach != null && coach.pricePerHour != null) {
        coachWage = calculateCoachWage(
          durationHours: durationHours,
          coachPricePerHour: coach.pricePerHour!,
        );
      }

      final staffWage = calculateStaffWage(staffUser: createdByUser);

      final booking = Booking(
        id: null,
        // حالياً نربط user_id بنفس الموظف (حتى يتم إضافة عميل لاحقاً)
        userId: createdByUser.id!,
        coachId: coach?.id,
        pitchId: pitch.id!,
        ballId: ball?.id,
        startTime: startDateTime,
        endTime: endDateTime,
        totalPrice: totalPrice,
        status: isPaid ? 'paid' : 'pending',
        notes: notes,
        teamName: teamName,
        customerPhone: customerPhone,
        period: period,
        createdByUserId: createdByUser.id!,
        staffWage: staffWage,
        coachWage: coachWage,
        isDirty: true,
        updatedAt: DateTime.now(),
      );

      final id = await _dbHelper.insert(
        DatabaseHelper.tableBookings,
        booking.toMap(),
      );

      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      _errorMessage = 'تعذر حفظ الحجز.';
      notifyListeners();
      return null;
    }
  }
}
