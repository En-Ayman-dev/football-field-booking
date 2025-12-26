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

  // السعر الافتراضي للساعة من جدول settings
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
      await _dbHelper.rawExecute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        );
      ''');

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
      // Backwards compatibility
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
    }
  }

  /// تحميل بيانات الموارد
  Future<void> loadData() async {
    _errorMessage = null;
    notifyListeners();

    try {
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

    double fallback = 0;
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
    
    if (fallback == 0) {
      fallback = _defaultHourPriceMorning ?? _defaultHourPrice ?? 0;
      if (period != null && period == 'evening') {
        fallback = _defaultHourPriceEvening ?? fallback;
      }
    }
    
    if (period != null && period == 'evening') {
      fallback = _defaultHourPriceEvening ?? fallback;
    }
    
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

    if ((fallback <= 0) && pitchPricePerHour > 0) {
      if (kDebugMode) print('calculateTotalPrice: using pitch price $pitchPricePerHour (period=$period, isIndoor=$isIndoor)');
      return durationHours * pitchPricePerHour;
    }

    if (fallback <= 0) return 0;
    if (kDebugMode) print('calculateTotalPrice: using fallback $fallback (period=$period, isIndoor=$isIndoor)');
    return durationHours * fallback;
  }

  double calculateCoachWage({
    required double durationHours,
    required double coachPricePerHour,
  }) {
    if (durationHours <= 0 || coachPricePerHour <= 0) {
      return 0;
    }
    return durationHours * coachPricePerHour;
  }

  double? calculateStaffWage({
    required User staffUser,
  }) {
    return staffUser.wagePerBooking;
  }

  String amountToArabicWords(double amount, {String currency = 'ريال'}) {
    final intValue = amount.round();
    if (intValue == 0) {
      return 'صفر $currency';
    }

    final units = [
      '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة',
    ];
    final tens = [
      '', 'عشرة', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون',
    ];
    final teens = [
      'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر',
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
  //      إضافة حجز
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

      // --- التحقق من التوفر باستخدام دالة DatabaseHelper ---
      // ملاحظة: نقوم بتحويل التواريخ لنصوص لأن الدالة تتوقع String في SQL
      final isAvailable = await _dbHelper.isPitchAvailable(
        pitchId: pitch.id!,
        startTime: startDateTime.toIso8601String(),
        endTime: endDateTime.toIso8601String(),
      );

      if (!isAvailable) {
        _errorMessage = 'هذا الملعب محجوز بالفعل في هذه الفترة الزمنية.';
        notifyListeners();
        return null;
      }
      // ----------------------------------------------------

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

      // --- التحقق من التوفر عند التحديث (مع استثناء الحجز الحالي) ---
      final isAvailable = await _dbHelper.isPitchAvailable(
        pitchId: pitch.id!,
        startTime: startDateTime.toIso8601String(),
        endTime: endDateTime.toIso8601String(),
        excludeBookingId: existingBooking.id,
      );

      if (!isAvailable) {
        _errorMessage = 'هذا الملعب محجوز بالفعل في هذه الفترة الزمنية.';
        notifyListeners();
        return false;
      }
      // -----------------------------------------------------------

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

  Future<void> fetchBookings({
    DateTime? date,
    int? pitchId,
    String? period,
    bool keepExistingFiltersIfNull = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    _currentFilterDate = date ?? _currentFilterDate ?? DateTime.now();
    if (keepExistingFiltersIfNull) {
      _currentFilterPitchId = pitchId ?? _currentFilterPitchId;
      _currentFilterPeriod = period ?? _currentFilterPeriod;
    } else {
      _currentFilterPitchId = pitchId;
      _currentFilterPeriod = period;
    }

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

  Future<void> refreshBookings() async {
    await fetchBookings();
  }

  Future<void> updateBookingStatus(int id, String status) async {
    try {
      await _dbHelper.update(
        DatabaseHelper.tableBookings,
        {
          'status': status,
          'is_dirty': 1, // تم إضافة is_dirty ليتم مزامنة تغيير الحالة
          'updated_at': DateTime.now().toIso8601String(),
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