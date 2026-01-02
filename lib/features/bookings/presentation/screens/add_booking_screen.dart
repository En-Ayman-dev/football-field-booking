// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب
import '../../../../data/models/ball.dart';
import '../../../../data/models/coach.dart';
import '../../../../data/models/pitch.dart';
import '../../../../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  Pitch? _selectedPitch;
  Ball? _selectedBall;
  Coach? _selectedCoach;

  String? _teamName;
  String? _customerPhone;
  String? _period; // morning / evening

  TimeOfDay? _startTime;

  // --- التعديلات الجديدة للمدة ---
  double _inputDurationValue = 1; // القيمة التي يدخلها المستخدم (مثلاً 90)
  String _durationUnit = 'hours'; // 'hours' أو 'minutes'
  double _finalDurationInHours =
      1; // القيمة النهائية بالساعات (للحساب والتخزين)

  String? _notes;

  double _calculatedTotalPrice = 0;
  double? _calculatedCoachWage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickStartTime(BuildContext ctx) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: ctx,
      initialTime: _startTime ?? now,
      helpText: 'اختر وقت بداية الحجز',
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
      _recalculatePrices(ctx);
    }
  }

  // --- دالة مساعدة لحساب الساعات بناءً على الوحدة ---
  void _updateFinalDuration() {
    if (_durationUnit == 'minutes') {
      _finalDurationInHours = _inputDurationValue / 60.0;
    } else {
      _finalDurationInHours = _inputDurationValue;
    }
  }

  void _recalculatePrices(BuildContext ctx) {
    // 1. تحديث المدة النهائية بالساعات أولاً
    _updateFinalDuration();

    final bookingProvider = Provider.of<BookingProvider>(ctx, listen: false);

    if (_selectedPitch == null) {
      setState(() {
        _calculatedTotalPrice = 0;
        _calculatedCoachWage = null;
      });
      return;
    }

    final pitchPrice = _selectedPitch!.pricePerHour ?? 0;

    // 2. استخدام _finalDurationInHours في الحسابات
    final totalPrice = bookingProvider.calculateTotalPrice(
      durationHours: _finalDurationInHours,
      pitchPricePerHour: pitchPrice,
      period: _period,
      isIndoor: _selectedPitch!.isIndoor,
    );

    double? coachWage;
    if (_selectedCoach != null && _selectedCoach!.pricePerHour != null) {
      coachWage = bookingProvider.calculateCoachWage(
        durationHours: _finalDurationInHours,
        coachPricePerHour: _selectedCoach!.pricePerHour!,
      );
    }

    setState(() {
      _calculatedTotalPrice = totalPrice;
      _calculatedCoachWage = coachWage;
    });
  }

  Future<void> _submit(BuildContext ctx, {required bool isPaid}) async {
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(ctx, listen: false);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedPitch == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الملعب.')));
      return;
    }

    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار وقت بداية الحجز.')),
      );
      return;
    }

    final currentUser = auth.currentUser;
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد موظف مسجل الدخول حالياً.')),
      );
      return;
    }

    // Permissions: ensure user can manage bookings
    if (!currentUser.canManageBookings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ليس لديك صلاحية إنشاء الحجوزات.')),
      );
      return;
    }

    _formKey.currentState?.save();

    // تأكيد تحديث المدة قبل الحفظ النهائي
    _updateFinalDuration();

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final id = await bookingProvider.addBooking(
      createdByUser: currentUser,
      pitch: _selectedPitch!,
      ball: _selectedBall,
      coach: _selectedCoach,
      startDateTime: startDateTime,
      durationHours: _finalDurationInHours, // نرسل الساعات المحولة دائماً
      teamName: _teamName,
      customerPhone: _customerPhone,
      period: _period,
      notes: _notes,
      isPaid: isPaid,
    );

    if (!mounted) return;

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPaid
                ? 'تم حفظ الحجز ودفعه بنجاح (رقم: $id).'
                : 'تم حفظ الحجز كمعلق (رقم: $id).',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? 'تعذر حفظ الحجز.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BookingProvider>(
      create: (_) => BookingProvider(DatabaseHelper())..loadData(),
      child: Builder(
        builder: (providerContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  'إنشاء حجز جديد',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
              body: Consumer<BookingProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          // اختيار الملعب
                          DropdownButtonFormField<Pitch>(
                            decoration: InputDecoration(
                              labelText: 'الملعب',
                              labelStyle: TextStyle(fontSize: 13.sp),
                            ),
                            items: provider.pitches
                                .map(
                                  (p) => DropdownMenuItem<Pitch>(
                                    value: p,
                                    child: Text(
                                      p.name,
                                      style: TextStyle(fontSize: 13.sp),
                                    ),
                                  ),
                                )
                                .toList(),
                            initialValue: _selectedPitch,
                            onChanged: (value) {
                              setState(() {
                                _selectedPitch = value;
                              });
                              _recalculatePrices(providerContext);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'الرجاء اختيار الملعب.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 1.5.h),

                          // اختيار الكرة
                          DropdownButtonFormField<Ball>(
                            decoration: InputDecoration(
                              labelText: 'الكرة (اختياري)',
                              labelStyle: TextStyle(fontSize: 13.sp),
                            ),
                            items: [
                              DropdownMenuItem<Ball>(
                                value: null,
                                child: Text(
                                  'بدون كرة',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ),
                              ...provider.balls.map(
                                (b) => DropdownMenuItem<Ball>(
                                  value: b,
                                  child: Text(
                                    '${b.name} - الكمية: ${b.quantity}',
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ),
                              ),
                            ],
                            initialValue: _selectedBall,
                            onChanged: (value) {
                              setState(() {
                                _selectedBall = value;
                              });
                            },
                          ),
                          SizedBox(height: 1.5.h),

                          // اختيار المدرب
                          DropdownButtonFormField<Coach>(
                            decoration: InputDecoration(
                              labelText: 'المدرب (اختياري)',
                              labelStyle: TextStyle(fontSize: 13.sp),
                            ),
                            items: [
                              DropdownMenuItem<Coach>(
                                value: null,
                                child: Text(
                                  'بدون مدرب',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ),
                              ...provider.coaches.map(
                                (c) => DropdownMenuItem<Coach>(
                                  value: c,
                                  child: Text(
                                    c.pricePerHour != null
                                        ? '${c.name} (أجر الساعة: ${c.pricePerHour})'
                                        : c.name,
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ),
                              ),
                            ],
                            initialValue: _selectedCoach,
                            onChanged: (value) {
                              setState(() {
                                _selectedCoach = value;
                              });
                              _recalculatePrices(providerContext);
                            },
                          ),
                          SizedBox(height: 2.h),

                          // اسم الفريق
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'اسم الفريق',
                              labelStyle: TextStyle(fontSize: 13.sp),
                            ),
                            style: TextStyle(fontSize: 14.sp),
                            onSaved: (value) {
                              _teamName = value?.trim();
                            },
                          ),
                          SizedBox(height: 1.5.h),

                          // الهاتف
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'رقم الهاتف',
                              labelStyle: TextStyle(fontSize: 13.sp),
                            ),
                            style: TextStyle(fontSize: 14.sp),
                            keyboardType: TextInputType.phone,
                            onSaved: (value) {
                              _customerPhone = value?.trim();
                            },
                          ),
                          SizedBox(height: 1.5.h),

                          // الفترة
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'الفترة',
                              labelStyle: TextStyle(fontSize: 13.sp),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'morning',
                                child: Text(
                                  'صباحي',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'evening',
                                child: Text(
                                  'مسائي',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ),
                            ],
                            initialValue: _period,
                            onChanged: (value) {
                              setState(() {
                                _period = value;
                              });
                              _recalculatePrices(providerContext);
                            },
                          ),
                          SizedBox(height: 2.h),

                          // --- وقت البدء والمدة (معدل) ---
                          Row(
                            children: [
                              // وقت البدء
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: () => _pickStartTime(providerContext),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'وقت البدء',
                                      labelStyle: TextStyle(fontSize: 12.sp),
                                      border: const OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 1.h,
                                      ),
                                    ),
                                    child: Text(
                                      _startTime == null
                                          ? 'اختيار'
                                          : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 13.sp),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),

                              // المدة (رقم)
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: _inputDurationValue.toString(),
                                  decoration: InputDecoration(
                                    labelText: 'المدة',
                                    labelStyle: TextStyle(fontSize: 12.sp),
                                    border: const OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 2.w,
                                      vertical: 1.h,
                                    ),
                                  ),
                                  style: TextStyle(fontSize: 13.sp),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'مطلوب';
                                    }
                                    final d = double.tryParse(
                                      text.replaceAll(',', '.'),
                                    );
                                    if (d == null || d <= 0) {
                                      return 'خطأ';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    final text = value.trim();
                                    final d = double.tryParse(
                                      text.replaceAll(',', '.'),
                                    );
                                    setState(() {
                                      _inputDurationValue = d ?? 0;
                                    });
                                    _recalculatePrices(providerContext);
                                  },
                                  onSaved: (value) {
                                    final text = value?.trim() ?? '';
                                    final d = double.tryParse(
                                      text.replaceAll(',', '.'),
                                    );
                                    _inputDurationValue = d ?? 0;
                                  },
                                ),
                              ),
                              SizedBox(width: 2.w),

                              // المدة (وحدة القياس)
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 1.w,
                                      vertical: 1.h,
                                    ),
                                  ),
                                  initialValue: _durationUnit,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'hours',
                                      child: Text('ساعة'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'minutes',
                                      child: Text('دقيقة'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() {
                                        _durationUnit = v;
                                      });
                                      _recalculatePrices(providerContext);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),

                          // ملاحظات (اختياري)
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'ملاحظات (اختياري)',
                              labelStyle: TextStyle(fontSize: 13.sp),
                            ),
                            style: TextStyle(fontSize: 13.sp),
                            maxLines: 2,
                            onSaved: (value) {
                              _notes = value?.trim();
                            },
                          ),
                          SizedBox(height: 2.h),

                          // السعر المحسوب
                          _buildPricePreview(providerContext),
                          SizedBox(height: 3.h),

                          // الأزرار
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _submit(providerContext, isPaid: false),
                                  child: Text(
                                    'حفظ كمعلّق',
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _submit(providerContext, isPaid: true),
                                  child: Text(
                                    'حفظ ودفع',
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPricePreview(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context, listen: false);

    final price = _calculatedTotalPrice;
    final coachWage = _calculatedCoachWage;

    final priceWords = price > 0
        ? provider.amountToArabicWords(price, currency: 'ريال')
        : null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.sp)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'السعر المحسوب:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              'الإجمالي (رقماً): ${price.toStringAsFixed(2)} ريال',
              style: TextStyle(fontSize: 13.sp),
            ),
            if (priceWords != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                'الإجمالي (كتابة): $priceWords',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
              ),
            ],
            if (coachWage != null) ...[
              SizedBox(height: 1.h),
              Text(
                'أجر المدرب التقريبي: ${coachWage.toStringAsFixed(2)} ريال',
                style: TextStyle(fontSize: 12.sp, color: Colors.blue[800]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
