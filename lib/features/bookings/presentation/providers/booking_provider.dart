
// // ignore_for_file: depend_on_referenced_packages

// import 'package:flutter/foundation.dart';
// import 'package:intl/intl.dart';


// import '../../../../core/database/database_helper.dart';
// import '../../../../data/models/ball.dart';
// import '../../../../data/models/booking.dart';
// import '../../../../data/models/coach.dart';
// import '../../../../data/models/pitch.dart';
// import '../../../../data/models/user.dart';

// class BookingProvider extends ChangeNotifier {
//   final DatabaseHelper _dbHelper;

//   List<Pitch> _pitches = [];
//   List<Ball> _balls = [];
//   List<Coach> _coaches = [];
//   List<Booking> _bookings = [];

//   bool _isLoading = false;
//   String? _errorMessage;

//   DateTime? _currentFilterDate;
//   int? _currentFilterPitchId;
//   String? _currentFilterPeriod; // 'morning' / 'evening' / null (all)

//   BookingProvider(DatabaseHelper databaseHelper, {DatabaseHelper? dbHelper})
//       : _dbHelper = dbHelper ?? DatabaseHelper();

//   List<Pitch> get pitches => _pitches;
//   List<Ball> get balls => _balls;
//   List<Coach> get coaches => _coaches;
//   List<Booking> get bookings => _bookings;

//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   DateTime? get currentFilterDate => _currentFilterDate;
//   int? get currentFilterPitchId => _currentFilterPitchId;
//   String? get currentFilterPeriod => _currentFilterPeriod;

//   /// تحميل بيانات الموارد (ملاعب / كرات / مدربين) لاستخدامها في النماذج والقوائم
//   Future<void> loadData() async {
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       final pitchesRows = await _dbHelper.getAll(
//         DatabaseHelper.tablePitches,
//         where: 'is_active = 1',
//         orderBy: 'name ASC',
//       );
//       final ballsRows = await _dbHelper.getAll(
//         DatabaseHelper.tableBalls,
//         where: 'is_available = 1',
//         orderBy: 'name ASC',
//       );
//       final coachesRows = await _dbHelper.getAll(
//         DatabaseHelper.tableCoaches,
//         where: 'is_active = 1',
//         orderBy: 'name ASC',
//       );

//       _pitches = pitchesRows.map((e) => Pitch.fromMap(e)).toList();
//       _balls = ballsRows.map((e) => Ball.fromMap(e)).toList();
//       _coaches = coachesRows.map((e) => Coach.fromMap(e)).toList();
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error loading booking resources: $e');
//       }
//       _errorMessage = 'حدث خطأ أثناء تحميل بيانات الموارد.';
//     } finally {
//       notifyListeners();
//     }
//   }

//   /// (مدة الحجز بالساعات * سعر الساعة للملعب)
//   double calculateTotalPrice({
//     required double durationHours,
//     required double pitchPricePerHour,
//   }) {
//     if (durationHours <= 0 || pitchPricePerHour <= 0) {
//       return 0;
//     }
//     return durationHours * pitchPricePerHour;
//   }

//   /// (مدة الحجز * أجر المدرب بالساعة)
//   double calculateCoachWage({
//     required double durationHours,
//     required double coachPricePerHour,
//   }) {
//     if (durationHours <= 0 || coachPricePerHour <= 0) {
//       return 0;
//     }
//     return durationHours * coachPricePerHour;
//   }

//   /// أجر العامل لكل حجز (من الموديل نفسه، لا يعتمد على المدة)
//   double? calculateStaffWage({
//     required User staffUser,
//   }) {
//     return staffUser.wagePerBooking;
//   }

//   /// تحويل المبلغ إلى نص عربي بسيط (جزء صحيح فقط)
//   String amountToArabicWords(double amount, {String currency = 'ريال'}) {
//     final intValue = amount.round();
//     if (intValue == 0) {
//       return 'صفر $currency';
//     }

//     final units = [
//       '',
//       'واحد',
//       'اثنان',
//       'ثلاثة',
//       'أربعة',
//       'خمسة',
//       'ستة',
//       'سبعة',
//       'ثمانية',
//       'تسعة',
//     ];
//     final tens = [
//       '',
//       'عشرة',
//       'عشرون',
//       'ثلاثون',
//       'أربعون',
//       'خمسون',
//       'ستون',
//       'سبعون',
//       'ثمانون',
//       'تسعون',
//     ];
//     final teens = [
//       'عشرة',
//       'أحد عشر',
//       'اثنا عشر',
//       'ثلاثة عشر',
//       'أربعة عشر',
//       'خمسة عشر',
//       'ستة عشر',
//       'سبعة عشر',
//       'ثمانية عشر',
//       'تسعة عشر',
//     ];

//     String convertBelowHundred(int n) {
//       if (n < 10) {
//         return units[n];
//       } else if (n < 20) {
//         return teens[n - 10];
//       } else {
//         final t = n ~/ 10;
//         final u = n % 10;
//         if (u == 0) {
//           return tens[t];
//         } else {
//           return '${units[u]} و ${tens[t]}';
//         }
//       }
//     }

//     String convertBelowThousand(int n) {
//       final h = n ~/ 100;
//       final r = n % 100;
//       String result = '';
//       if (h > 0) {
//         if (h == 1) {
//           result = 'مائة';
//         } else if (h == 2) {
//           result = 'مائتان';
//         } else if (h >= 3 && h <= 9) {
//           result = '${units[h]} مائة';
//         }
//       }
//       if (r > 0) {
//         final belowHundred = convertBelowHundred(r);
//         if (result.isEmpty) {
//           result = belowHundred;
//         } else {
//           result = '$belowHundred و $result';
//         }
//       }
//       return result;
//     }

//     String words;
//     if (intValue < 1000) {
//       words = convertBelowThousand(intValue);
//     } else if (intValue < 1000000) {
//       final thousands = intValue ~/ 1000;
//       final remainder = intValue % 1000;
//       String thousandsPart;
//       if (thousands == 1) {
//         thousandsPart = 'ألف';
//       } else if (thousands == 2) {
//         thousandsPart = 'ألفان';
//       } else if (thousands >= 3 && thousands <= 10) {
//         thousandsPart = '${convertBelowThousand(thousands)} آلاف';
//       } else {
//         thousandsPart = '${convertBelowThousand(thousands)} ألف';
//       }
//       if (remainder == 0) {
//         words = thousandsPart;
//       } else {
//         words = '$thousandsPart و ${convertBelowThousand(remainder)}';
//       }
//     } else {
//       final f = NumberFormat.decimalPattern('ar');
//       return '${f.format(amount)} $currency';
//     }

//     return '$words $currency';
//   }

//   /// حفظ الحجز في قاعدة البيانات مع حساب السعر والأجور
//   ///
//   /// - createdByUser: الموظف الذي قام بالحجز
//   /// - pitch: الملعب المختار
//   /// - coach: المدرب (اختياري)
//   /// - ball: الكرة (اختيارية)
//   /// - durationHours: المدة بالساعات
//   /// - isPaid: true => "حفظ ودفع" ، false => "حفظ كمعلق"
//   Future<int?> createBooking({
//     required User createdByUser,
//     required Pitch pitch,
//     Ball? ball,
//     Coach? coach,
//     required DateTime startDateTime,
//     required double durationHours,
//     required String? teamName,
//     required String? customerPhone,
//     required String? period,
//     String? notes,
//     bool isPaid = false,
//   }) async {
//     try {
//       final endDateTime = startDateTime.add(
//         Duration(
//           minutes: (durationHours * 60).round(),
//         ),
//       );

//       final pitchPricePerHour = pitch.pricePerHour ?? 0;
//       final totalPrice = calculateTotalPrice(
//         durationHours: durationHours,
//         pitchPricePerHour: pitchPricePerHour,
//       );

//       double? coachWage;
//       if (coach != null && coach.pricePerHour != null) {
//         coachWage = calculateCoachWage(
//           durationHours: durationHours,
//           coachPricePerHour: coach.pricePerHour!,
//         );
//       }

//       final staffWage = calculateStaffWage(staffUser: createdByUser);

//       final booking = Booking(
//         id: null,
//         userId: createdByUser.id!,
//         coachId: coach?.id,
//         pitchId: pitch.id!,
//         ballId: ball?.id,
//         startTime: startDateTime,
//         endTime: endDateTime,
//         totalPrice: totalPrice,
//         status: isPaid ? 'paid' : 'pending',
//         notes: notes,
//         teamName: teamName,
//         customerPhone: customerPhone,
//         period: period,
//         createdByUserId: createdByUser.id!,
//         staffWage: staffWage,
//         coachWage: coachWage,
//         isDirty: true,
//         updatedAt: DateTime.now(),
//       );

//       final id = await _dbHelper.insert(
//         DatabaseHelper.tableBookings,
//         booking.toMap(),
//       );

//       return id;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error creating booking: $e');
//       }
//       _errorMessage = 'تعذر حفظ الحجز.';
//       notifyListeners();
//       return null;
//     }
//   }

//   // =========================
//   //   إدارة قائمة الحجوزات
//   // =========================

//   /// جلب الحجوزات مع دعم الفلاتر:
//   /// - date: يوم محدد (افتراضي: اليوم)
//   /// - pitchId: رقم الملعب (إن وجد) - إن كان null => كل الملاعب
//   /// - period: 'morning' / 'evening' / null => الكل
//   Future<void> fetchBookings({
//     DateTime? date,
//     int? pitchId,
//     String? period,
//   }) async {
//     _isLoading = true;
//     _errorMessage = null;

//     // تحديث الفلاتر الحالية
//     _currentFilterDate = date ?? _currentFilterDate ?? DateTime.now();
//     _currentFilterPitchId = pitchId ?? _currentFilterPitchId;
//     _currentFilterPeriod = period ?? _currentFilterPeriod;

//     notifyListeners();

//     try {
//       final day = DateTime(
//         _currentFilterDate!.year,
//         _currentFilterDate!.month,
//         _currentFilterDate!.day,
//       );
//       final nextDay = day.add(const Duration(days: 1));

//       String where = 'start_time >= ? AND start_time < ?';
//       final whereArgs = <Object?>[
//         day.toIso8601String(),
//         nextDay.toIso8601String(),
//       ];

//       if (_currentFilterPitchId != null) {
//         where += ' AND pitch_id = ?';
//         whereArgs.add(_currentFilterPitchId);
//       }

//       final rows = await _dbHelper.getAll(
//         DatabaseHelper.tableBookings,
//         where: where,
//         whereArgs: whereArgs,
//         orderBy: 'start_time ASC',
//       );

//       var loaded = rows.map((e) => Booking.fromMap(e)).toList();

//       // فلترة الفترة (صباحي/مسائي) في الذاكرة
//       if (_currentFilterPeriod != null &&
//           _currentFilterPeriod != 'all') {
//         loaded = loaded.where((b) {
//           final hour = b.startTime.hour;
//           if (_currentFilterPeriod == 'morning') {
//             return hour < 12;
//           } else if (_currentFilterPeriod == 'evening') {
//             return hour >= 12;
//           }
//           return true;
//         }).toList();
//       }

//       _bookings = loaded;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error fetching bookings: $e');
//       }
//       _errorMessage = 'حدث خطأ أثناء جلب الحجوزات.';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// إعادة تحميل الحجوزات باستخدام نفس الفلاتر الحالية
//   Future<void> refreshBookings() async {
//     await fetchBookings();
//   }

//   /// تحديث حالة الحجز (مثلاً من pending إلى paid)
//   Future<void> updateBookingStatus(int id, String status) async {
//     try {
//       await _dbHelper.update(
//         DatabaseHelper.tableBookings,
//         {
//           'status': status,
//         },
//         where: 'id = ?',
//         whereArgs: [id],
//       );

//       final index = _bookings.indexWhere((b) => b.id == id);
//       if (index != -1) {
//         _bookings[index] = _bookings[index].copyWith(status: status);
//         notifyListeners();
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error updating booking status: $e');
//       }
//       _errorMessage = 'تعذر تحديث حالة الحجز.';
//       notifyListeners();
//     }
//   }

//   /// حذف حجز (من المفترض أن يتم استدعاؤها من واجهة المدير فقط)
//   Future<void> deleteBooking(int id) async {
//     try {
//       await _dbHelper.delete(
//         DatabaseHelper.tableBookings,
//         where: 'id = ?',
//         whereArgs: [id],
//       );
//       _bookings.removeWhere((b) => b.id == id);
//       notifyListeners();
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error deleting booking: $e');
//       }
//       _errorMessage = 'تعذر حذف الحجز.';
//       notifyListeners();
//     }
//   }
// }
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/settings/settings_notifier.dart';
import '../../../../data/models/ball.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/coach.dart';
import '../../../../data/models/pitch.dart';
import '../../../../data/models/user.dart';

class BookingProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final SettingsNotifier? _settingsNotifier;

  List<Pitch> _pitches = [];
  List<Ball> _balls = [];
  List<Coach> _coaches = [];
  List<Booking> _bookings = [];

  bool _isLoading = false;
  String? _errorMessage;

  DateTime? _currentFilterDate;
  int? _currentFilterPitchId;
  String? _currentFilterPeriod; // 'morning' / 'evening' / null (all)

  // السعر الافتراضي للساعة من جدول settings (default_hour_price_morning / default_hour_price_evening)
  double? _defaultHourPrice;
  double? _defaultHourPriceMorning;
  double? _defaultHourPriceEvening;
  double? _defaultHourPriceMorningIndoor;
  double? _defaultHourPriceEveningIndoor;
  double? _defaultHourPriceMorningOutdoor;
  double? _defaultHourPriceEveningOutdoor;

  BookingProvider(DatabaseHelper databaseHelper, {DatabaseHelper? dbHelper, SettingsNotifier? settingsNotifier})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _settingsNotifier = settingsNotifier {
    // Subscribe to settings updates so we can reload defaults
    _settingsNotifier?.addListener(_onSettingsUpdated);
  }

  List<Pitch> get pitches => _pitches;
  List<Ball> get balls => _balls;
  List<Coach> get coaches => _coaches;
  List<Booking> get bookings => _bookings;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime? get currentFilterDate => _currentFilterDate;
  int? get currentFilterPitchId => _currentFilterPitchId;
  String? get currentFilterPeriod => _currentFilterPeriod;

  // Getter للسعر الافتراضي حتى تستخدمه شاشة النموذج
  double? get defaultHourPrice => _defaultHourPrice;
  double? get defaultHourPriceMorning => _defaultHourPriceMorning;
  double? get defaultHourPriceEvening => _defaultHourPriceEvening;
  double? get defaultHourPriceMorningIndoor => _defaultHourPriceMorningIndoor;
  double? get defaultHourPriceEveningIndoor => _defaultHourPriceEveningIndoor;
  double? get defaultHourPriceMorningOutdoor => _defaultHourPriceMorningOutdoor;
  double? get defaultHourPriceEveningOutdoor => _defaultHourPriceEveningOutdoor;

  /// تحميل قيمة default_hour_price من جدول settings (إن وجدت)
  Future<void> _loadDefaultHourPrice() async {
    try {
      // إنشاء جدول settings إذا لم يكن موجوداً
      await _dbHelper.rawExecute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        );
      ''');

      // Load both morning/evening values. Keep backward compatibility with single key default_hour_price
      final rowsAll = await _dbHelper.rawQuery('SELECT key,value FROM settings WHERE key IN (?, ?, ?, ?, ?, ?, ?)', ['default_hour_price', 'default_hour_price_morning', 'default_hour_price_evening', 'default_hour_price_morning_indoor', 'default_hour_price_evening_indoor', 'default_hour_price_morning_outdoor', 'default_hour_price_evening_outdoor']);
      final map = {for (var r in rowsAll) r['key']?.toString(): r['value']?.toString()};
      if (map['default_hour_price_morning'] != null && map['default_hour_price_morning']!.isNotEmpty) {
        _defaultHourPriceMorning = double.tryParse(map['default_hour_price_morning']!.replaceAll(',', '.'));
      }
      if (map['default_hour_price_evening'] != null && map['default_hour_price_evening']!.isNotEmpty) {
        _defaultHourPriceEvening = double.tryParse(map['default_hour_price_evening']!.replaceAll(',', '.'));
      }
      if (map['default_hour_price_morning_indoor'] != null && map['default_hour_price_morning_indoor']!.isNotEmpty) {
        _defaultHourPriceMorningIndoor = double.tryParse(map['default_hour_price_morning_indoor']!.replaceAll(',', '.'));
      }
      if (map['default_hour_price_evening_indoor'] != null && map['default_hour_price_evening_indoor']!.isNotEmpty) {
        _defaultHourPriceEveningIndoor = double.tryParse(map['default_hour_price_evening_indoor']!.replaceAll(',', '.'));
      }
      if (map['default_hour_price_morning_outdoor'] != null && map['default_hour_price_morning_outdoor']!.isNotEmpty) {
        _defaultHourPriceMorningOutdoor = double.tryParse(map['default_hour_price_morning_outdoor']!.replaceAll(',', '.'));
      }
      if (map['default_hour_price_evening_outdoor'] != null && map['default_hour_price_evening_outdoor']!.isNotEmpty) {
        _defaultHourPriceEveningOutdoor = double.tryParse(map['default_hour_price_evening_outdoor']!.replaceAll(',', '.'));
      }
      // Backwards compatibility: single default_hour_price
      if (_defaultHourPriceMorning == null && _defaultHourPriceEvening == null && map['default_hour_price'] != null && map['default_hour_price']!.isNotEmpty) {
        final v = double.tryParse(map['default_hour_price']!.replaceAll(',', '.'));
        _defaultHourPrice = v;
        _defaultHourPriceMorning = v;
        _defaultHourPriceEvening = v;
      }
      if (kDebugMode) print('Loaded default prices: morning=$_defaultHourPriceMorning, evening=$_defaultHourPriceEvening, morningIndoor=$_defaultHourPriceMorningIndoor, eveningIndoor=$_defaultHourPriceEveningIndoor, morningOutdoor=$_defaultHourPriceMorningOutdoor, eveningOutdoor=$_defaultHourPriceEveningOutdoor, legacy=$_defaultHourPrice');
    } catch (e) {
      if (kDebugMode) {
        print('Error loading default_hour_price: $e');
      }
      // لا نعرض رسالة للمستخدم هنا؛ فقط نكمل بدون قيمة افتراضية
    }
  }

  /// تحميل بيانات الموارد (ملاعب / كرات / مدربين) لاستخدامها في النماذج والقوائم
  Future<void> loadData() async {
    _errorMessage = null;
    notifyListeners();

    try {
      // تحميل إعداد السعر الافتراضي قبل الموارد
      await _loadDefaultHourPrice();

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
        print('Error loading booking resources: $e');
      }
      _errorMessage = 'حدث خطأ أثناء تحميل بيانات الموارد.';
    } finally {
      notifyListeners();
    }
  }

  void _onSettingsUpdated() {
    reloadSettings();
  }

  /// Reload only the settings (default hour prices) without reloading all resources.
  Future<void> reloadSettings() async {
    try {
      await _loadDefaultHourPrice();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error reloading booking settings: $e');
    }
  }

  @override
  void dispose() {
    _settingsNotifier?.removeListener(_onSettingsUpdated);
    super.dispose();
  }

  /// (مدة الحجز بالساعات * سعر الساعة للملعب)
  double calculateTotalPrice({
    required double durationHours,
    required double pitchPricePerHour,
    String? period,
    bool? isIndoor,
  }) {
    if (durationHours <= 0) return 0;

    // Determine price from settings with per-type overrides taking precedence
    double fallback = 0;
    // Check per-type per-period override first
    if (isIndoor == true) {
      final p = (period == 'evening') ? _defaultHourPriceEveningIndoor : _defaultHourPriceMorningIndoor;
      if (p != null && p > 0) {
        fallback = p;
      }
    } else if (isIndoor == false) {
      final p = (period == 'evening') ? _defaultHourPriceEveningOutdoor : _defaultHourPriceMorningOutdoor;
      if (p != null && p > 0) {
        fallback = p;
      }
    }
    // If we don't have a per-type override, check general per-period settings
    if (fallback == 0) {
      fallback = _defaultHourPriceMorning ?? _defaultHourPrice ?? 0;
      if (period != null && period == 'evening') {
        fallback = _defaultHourPriceEvening ?? fallback;
      }
    }
    if (period != null && period == 'evening') {
      fallback = _defaultHourPriceEvening ?? fallback;
    }
    // If specific indoor/outdoor per-period price exists use it
    if (isIndoor == true) {
      final p = (period == 'evening') ? _defaultHourPriceEveningIndoor : _defaultHourPriceMorningIndoor;
      if (p != null && p > 0) {
        fallback = p;
      }
    } else if (isIndoor == false) {
      final p = (period == 'evening') ? _defaultHourPriceEveningOutdoor : _defaultHourPriceMorningOutdoor;
      if (p != null && p > 0) {
        fallback = p;
      }
    }
    // If no setting found yet, use pitch's own price if provided
    if ((fallback <= 0) && pitchPricePerHour > 0) {
      if (kDebugMode) print('calculateTotalPrice: using pitch price $pitchPricePerHour (period=$period, isIndoor=$isIndoor)');
      return durationHours * pitchPricePerHour;
    }

    if (fallback <= 0) return 0;
    if (kDebugMode) print('calculateTotalPrice: using fallback $fallback (period=$period, isIndoor=$isIndoor)');
    return durationHours * fallback;
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
      final f = NumberFormat.decimalPattern('ar');
      return '${f.format(amount)} $currency';
    }

    return '$words $currency';
  }


  // =========================
  //      إضافة حجز (Snapshot)
  // =========================

  Future<int?> addBooking({
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

      // سعر الساعة الفعلي المستخدم (snapshot). calculateTotalPrice will use pitch price if set, otherwise fall back to settings depending on period
      final totalPrice = calculateTotalPrice(
        durationHours: durationHours,
        pitchPricePerHour: pitch.pricePerHour ?? 0,
        period: period,
        isIndoor: pitch.isIndoor,
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

      if (kDebugMode) print('DB inserting booking -> ${booking.toMap()}');
      // Insert inside a transaction to avoid lock/errors during concurrent ops
      final db = await _dbHelper.database;
      final id = await db.transaction<int>((txn) async {
        final insertedId = await txn.insert(
          DatabaseHelper.tableBookings,
          booking.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return insertedId;
      });

      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding booking: $e');
      }
      _errorMessage = kDebugMode ? 'تعذر حفظ الحجز. (خطأ: ${e.toString()})' : 'تعذر حفظ الحجز.';
      notifyListeners();
      return null;
    }
  }

  /// حفظ الحجز في قاعدة البيانات مع حساب السعر والأجور
  ///
  /// - createdByUser: الموظف الذي قام بالحجز
  /// - pitch: الملعب المختار
  /// - coach: المدرب (اختياري)
  /// - ball: الكرة (اختيارية)
  /// - durationHours: المدة بالساعات
  /// - isPaid: true => "حفظ ودفع" ، false => "حفظ كمعلق"
  // Future<int?> createBooking({
  //   required User createdByUser,
  //   required Pitch pitch,
  //   Ball? ball,
  //   Coach? coach,
  //   required DateTime startDateTime,
  //   required double durationHours,
  //   required String? teamName,
  //   required String? customerPhone,
  //   required String? period,
  //   String? notes,
  //   bool isPaid = false,
  // }) async {
  //   try {
  //     final endDateTime = startDateTime.add(
  //       Duration(
  //         minutes: (durationHours * 60).round(),
  //       ),
  //     );

  //     // هنا تم تعديل الحساب ليستخدم default_hour_price إذا لم يكن للملعب سعر
  //     final pitchPricePerHour = pitch.pricePerHour ?? _defaultHourPrice ?? 0;
  //     final totalPrice = calculateTotalPrice(
  //       durationHours: durationHours,
  //       pitchPricePerHour: pitchPricePerHour,
  //     );

  //     double? coachWage;
  //     if (coach != null && coach.pricePerHour != null) {
  //       coachWage = calculateCoachWage(
  //         durationHours: durationHours,
  //         coachPricePerHour: coach.pricePerHour!,
  //       );
  //     }

  //     final staffWage = calculateStaffWage(staffUser: createdByUser);

  //     // Snapshot: حفظ staff_wage و coach_wage كقيم ثابتة
  //     final booking = Booking(
  //       id: null,
  //       userId: createdByUser.id!,
  //       coachId: coach?.id,
  //       pitchId: pitch.id!,
  //       ballId: ball?.id,
  //       startTime: startDateTime,
  //       endTime: endDateTime,
  //       totalPrice: totalPrice,
  //       status: isPaid ? 'paid' : 'pending',
  //       notes: notes,
  //       teamName: teamName,
  //       customerPhone: customerPhone,
  //       period: period,
  //       createdByUserId: createdByUser.id!,
  //       staffWage: staffWage,
  //       coachWage: coachWage,
  //       isDirty: true,
  //       updatedAt: DateTime.now(),
  //     );

  //     final id = await _dbHelper.insert(
  //       DatabaseHelper.tableBookings,
  //       booking.toMap(),
  //     );

  //     return id;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error creating booking: $e');
  //     }
  //     _errorMessage = 'تعذر حفظ الحجز.';
  //     notifyListeners();
  //     return null;
  //   }
  // }

  /// تعديل حجز قائم مع إعادة حساب المبالغ (Edit Booking)
  ///
  /// لا يغيّر createdByUserId ولا status، فقط البيانات الأخرى والحسابات.
  Future<bool> updateBooking({
    required Booking existingBooking,
    required User updatedByUser,
    required Pitch pitch,
    Ball? ball,
    Coach? coach,
    required DateTime startDateTime,
    required double durationHours,
    required String? teamName,
    required String? customerPhone,
    required String? period,
    String? notes,
  }) async {
    try {
      final endDateTime = startDateTime.add(
        Duration(
          minutes: (durationHours * 60).round(),
        ),
      );

      // نفس منطق createBooking: نستخدم سعر الملعب أو الافتراضي
      final totalPrice = calculateTotalPrice(
        durationHours: durationHours,
        pitchPricePerHour: pitch.pricePerHour ?? 0,
        period: period,
        isIndoor: pitch.isIndoor,
      );

      double? coachWage;
      if (coach != null && coach.pricePerHour != null) {
        coachWage = calculateCoachWage(
          durationHours: durationHours,
          coachPricePerHour: coach.pricePerHour!,
        );
      }

      final staffWage = calculateStaffWage(staffUser: updatedByUser);

      final updatedBooking = existingBooking.copyWith(
        coachId: coach?.id,
        pitchId: pitch.id!,
        ballId: ball?.id,
        startTime: startDateTime,
        endTime: endDateTime,
        totalPrice: totalPrice,
        notes: notes,
        teamName: teamName,
        customerPhone: customerPhone,
        period: period,
        staffWage: staffWage,
        coachWage: coachWage,
        isDirty: true,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.update(
        DatabaseHelper.tableBookings,
        updatedBooking.toMap(),
        where: 'id = ?',
        whereArgs: [existingBooking.id],
      );

      // تحديث القائمة الحالية في الواجهة إن وجدت
      final index = _bookings.indexWhere((b) => b.id == existingBooking.id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating booking: $e');
      }
      _errorMessage = 'تعذر تحديث الحجز.';
      notifyListeners();
      return false;
    }
  }

  // =========================
  //   إدارة قائمة الحجوزات
  // =========================

  /// جلب الحجوزات مع دعم الفلاتر:
  /// - date: يوم محدد (افتراضي: اليوم)
  /// - pitchId: رقم الملعب (إن وجد) - إن كان null => كل الملاعب
  /// - period: 'morning' / 'evening' / null => الكل
  Future<void> fetchBookings({
    DateTime? date,
    int? pitchId,
    String? period,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // تحديث الفلاتر الحالية
    _currentFilterDate = date ?? _currentFilterDate ?? DateTime.now();
    _currentFilterPitchId = pitchId ?? _currentFilterPitchId;
    _currentFilterPeriod = period ?? _currentFilterPeriod;

    notifyListeners();

    try {
      final day = DateTime(
        _currentFilterDate!.year,
        _currentFilterDate!.month,
        _currentFilterDate!.day,
      );
      final nextDay = day.add(const Duration(days: 1));

      String where = 'start_time >= ? AND start_time < ?';
      final whereArgs = <Object?>[
        day.toIso8601String(),
        nextDay.toIso8601String(),
      ];

      if (_currentFilterPitchId != null) {
        where += ' AND pitch_id = ?';
        whereArgs.add(_currentFilterPitchId);
      }

      final rows = await _dbHelper.getAll(
        DatabaseHelper.tableBookings,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'start_time ASC',
      );

      var loaded = rows.map((e) => Booking.fromMap(e)).toList();

      // فلترة الفترة (صباحي/مسائي) في الذاكرة
      if (_currentFilterPeriod != null &&
          _currentFilterPeriod != 'all') {
        loaded = loaded.where((b) {
          final hour = b.startTime.hour;
          if (_currentFilterPeriod == 'morning') {
            return hour < 12;
          } else if (_currentFilterPeriod == 'evening') {
            return hour >= 12;
          }
          return true;
        }).toList();
      }

      _bookings = loaded;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching bookings: $e');
      }
      _errorMessage = 'حدث خطأ أثناء جلب الحجوزات.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إعادة تحميل الحجوزات باستخدام نفس الفلاتر الحالية
  Future<void> refreshBookings() async {
    await fetchBookings();
  }

  /// تحديث حالة الحجز (مثلاً من pending إلى paid)
  Future<void> updateBookingStatus(int id, String status) async {
    try {
      await _dbHelper.update(
        DatabaseHelper.tableBookings,
        {
          'status': status,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating booking status: $e');
      }
      _errorMessage = 'تعذر تحديث حالة الحجز.';
      notifyListeners();
    }
  }

  /// حذف حجز (من المفترض أن يتم استدعاؤها من واجهة المدير فقط)
  Future<void> deleteBooking(int id) async {
    try {
      await _dbHelper.delete(
        DatabaseHelper.tableBookings,
        where: 'id = ?',
        whereArgs: [id],
      );
      _bookings.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting booking: $e');
      }
      _errorMessage = 'تعذر حذف الحجز.';
      notifyListeners();
    }
  }
}
