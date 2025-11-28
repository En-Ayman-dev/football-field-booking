// ignore_for_file: unnecessary_null_comparison, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../../core/database/database_helper.dart';
import '../../../../data/models/ball.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/coach.dart';
import '../../../../data/models/pitch.dart';
import '../../../../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class BookingFormScreen extends StatefulWidget {
  final Booking? existingBooking;

  const BookingFormScreen({
    super.key,
    this.existingBooking,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Pitch? _selectedPitch;
  Ball? _selectedBall;
  Coach? _selectedCoach;

  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _durationController =
      TextEditingController(text: '1');
  final TextEditingController _notesController = TextEditingController();

  String? _period; // morning / evening
  TimeOfDay? _startTime;
  double _durationHours = 1;

  double _calculatedTotalPrice = 0;
  double? _calculatedCoachWage;

  bool _initializedFromExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBooking != null) {
      // سنقوم بتعبئة التفاصيل بعد تحميل البيانات (pitches/coaches/balls)
      _durationHours =
          widget.existingBooking!.endTime.difference(widget.existingBooking!.startTime).inMinutes / 60.0;
      _durationController.text =
          _durationHours.toStringAsFixed(_durationHours.truncateToDouble() == _durationHours ? 0 : 2);
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _phoneController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? now,
      helpText: 'اختر وقت بداية الحجز',
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
      _recalculatePrices();
    }
  }

  void _initializeFromExistingIfNeeded(BookingProvider provider) {
    if (_initializedFromExisting || widget.existingBooking == null) {
      return;
    }

    final booking = widget.existingBooking!;
    _teamNameController.text = booking.teamName ?? '';
    _phoneController.text = booking.customerPhone ?? '';
    _notesController.text = booking.notes ?? '';
    _period = booking.period;

    _startTime = TimeOfDay(
      hour: booking.startTime.hour,
      minute: booking.startTime.minute,
    );

    // اختيار الملعب / الكرة / المدرب من القوائم المحمّلة
    _selectedPitch = provider.pitches
        .where((p) => p.id == booking.pitchId)
        .cast<Pitch?>()
        .firstWhere(
          (p) => p != null,
          orElse: () => null,
        );

    _selectedBall = provider.balls
        .where((b) => b.id == booking.ballId)
        .cast<Ball?>()
        .firstWhere(
          (b) => b != null,
          orElse: () => null,
        );

    _selectedCoach = provider.coaches
        .where((c) => c.id == booking.coachId)
        .cast<Coach?>()
        .firstWhere(
          (c) => c != null,
          orElse: () => null,
        );

    _calculatedTotalPrice = booking.totalPrice ?? 0;
    _calculatedCoachWage = booking.coachWage;

    _initializedFromExisting = true;
  }

  void _recalculatePrices() {
    final provider =
        Provider.of<BookingProvider>(context, listen: false);

    if (_selectedPitch == null) {
      setState(() {
        _calculatedTotalPrice = 0;
        _calculatedCoachWage = null;
      });
      return;
    }

    final effectivePricePerHour =
        _selectedPitch!.pricePerHour ?? provider.defaultHourPrice ?? 0;
    final totalPrice = provider.calculateTotalPrice(
      durationHours: _durationHours,
      pitchPricePerHour: effectivePricePerHour,
    );

    double? coachWage;
    if (_selectedCoach != null && _selectedCoach!.pricePerHour != null) {
      coachWage = provider.calculateCoachWage(
        durationHours: _durationHours,
        coachPricePerHour: _selectedCoach!.pricePerHour!,
      );
    }

    setState(() {
      _calculatedTotalPrice = totalPrice;
      _calculatedCoachWage = coachWage;
    });
  }

  Future<void> _submit({required bool isPaid}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider =
        Provider.of<BookingProvider>(context, listen: false);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedPitch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الملعب.'),
        ),
      );
      return;
    }

    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار وقت بداية الحجز.'),
        ),
      );
      return;
    }

    final currentUser = auth.currentUser;
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد موظف مسجل الدخول حالياً.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final teamName = _teamNameController.text.trim().isEmpty
        ? null
        : _teamNameController.text.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    bool success = false;
    int? insertedId;

    if (widget.existingBooking == null) {
      // إضافة حجز جديد
      insertedId = await provider.addBooking(
        createdByUser: currentUser,
        pitch: _selectedPitch!,
        ball: _selectedBall,
        coach: _selectedCoach,
        startDateTime: startDateTime,
        durationHours: _durationHours,
        teamName: teamName,
        customerPhone: phone,
        period: _period,
        notes: notes,
        isPaid: isPaid,
      );
      success = insertedId != null;
    } else {
      // تعديل حجز قائم
      success = await provider.updateBooking(
        existingBooking: widget.existingBooking!,
        updatedByUser: currentUser,
        pitch: _selectedPitch!,
        ball: _selectedBall,
        coach: _selectedCoach,
        startDateTime: startDateTime,
        durationHours: _durationHours,
        teamName: teamName,
        customerPhone: phone,
        period: _period,
        notes: notes,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingBooking == null
                ? (isPaid
                    ? 'تم حفظ الحجز ودفعه بنجاح (رقم: $insertedId).'
                    : 'تم حفظ الحجز كمعلق (رقم: $insertedId).')
                : 'تم تحديث بيانات الحجز بنجاح.',
          ),
        ),
      );
      Navigator.of(context).pop(true); // نعيد true لنعلم القوائم بضرورة التحديث
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ بيانات الحجز.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BookingProvider>(
      create: (_) => BookingProvider(DatabaseHelper())..loadData(),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.existingBooking == null
                  ? 'إنشاء حجز جديد'
                  : 'تعديل الحجز',
            ),
          ),
          body: Consumer<BookingProvider>(
            builder: (context, provider, _) {
              if (provider.pitches.isEmpty && provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (provider.errorMessage != null &&
                  provider.pitches.isEmpty) {
                return Center(
                  child: Text(provider.errorMessage!),
                );
              }

              // تعبئة القيم من الحجز القديم بعد تحميل الموارد
              _initializeFromExistingIfNeeded(provider);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // اختيار الملعب
                      DropdownButtonFormField<Pitch>(
                        decoration: const InputDecoration(
                          labelText: 'الملعب',
                        ),
                        items: provider.pitches
                            .map(
                              (p) => DropdownMenuItem<Pitch>(
                                value: p,
                                child: Text(p.name),
                              ),
                            )
                            .toList(),
                        initialValue: _selectedPitch,
                        onChanged: (value) {
                          setState(() {
                            _selectedPitch = value;
                          });
                          _recalculatePrices();
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'الرجاء اختيار الملعب.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // اختيار الكرة
                      DropdownButtonFormField<Ball>(
                        decoration: const InputDecoration(
                          labelText: 'الكرة (اختياري)',
                        ),
                        items: [
                          const DropdownMenuItem<Ball>(
                            value: null,
                            child: Text('بدون كرة'),
                          ),
                          ...provider.balls.map(
                            (b) => DropdownMenuItem<Ball>(
                              value: b,
                              child: Text('${b.name} - الكمية: ${b.quantity}'),
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
                      const SizedBox(height: 12),

                      // اختيار المدرب
                      DropdownButtonFormField<Coach>(
                        decoration: const InputDecoration(
                          labelText: 'المدرب (اختياري)',
                        ),
                        items: [
                          const DropdownMenuItem<Coach>(
                            value: null,
                            child: Text('بدون مدرب'),
                          ),
                          ...provider.coaches.map(
                            (c) => DropdownMenuItem<Coach>(
                              value: c,
                              child: Text(
                                c.pricePerHour != null
                                    ? '${c.name} (أجر الساعة: ${c.pricePerHour})'
                                    : c.name,
                              ),
                            ),
                          ),
                        ],
                        initialValue: _selectedCoach,
                        onChanged: (value) {
                          setState(() {
                            _selectedCoach = value;
                          });
                          _recalculatePrices();
                        },
                      ),
                      const SizedBox(height: 16),

                      // اسم الفريق
                      TextFormField(
                        controller: _teamNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الفريق',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // الهاتف
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      // الفترة
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'الفترة',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'morning',
                            child: Text('صباحي'),
                          ),
                          DropdownMenuItem(
                            value: 'evening',
                            child: Text('مسائي'),
                          ),
                        ],
                        initialValue: _period,
                        onChanged: (value) {
                          setState(() {
                            _period = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // وقت البدء والمدة
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickStartTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'وقت البدء',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _startTime == null
                                      ? 'اضغط للاختيار'
                                      : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'المدة (بالساعات)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'أدخل المدة.';
                                }
                                final d = double.tryParse(
                                  text.replaceAll(',', '.'),
                                );
                                if (d == null || d <= 0) {
                                  return 'أدخل مدة صحيحة أكبر من صفر.';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final text = value.trim();
                                final d = double.tryParse(
                                  text.replaceAll(',', '.'),
                                );
                                setState(() {
                                  _durationHours = d ?? 0;
                                });
                                _recalculatePrices();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ملاحظات (اختياري)
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // السعر المحسوب
                      _buildPricePreview(provider),
                      const SizedBox(height: 24),

                      if (widget.existingBooking == null)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _submit(isPaid: false),
                                child: const Text('حفظ كمعلّق'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _submit(isPaid: true),
                                child: const Text('حفظ ودفع'),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _submit(
                              isPaid: widget.existingBooking!.status ==
                                  'paid',
                            ),
                            child: const Text('تحديث الحجز'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPricePreview(BookingProvider provider) {
    final price = _calculatedTotalPrice;
    final coachWage = _calculatedCoachWage;

    final priceWords = price > 0
        ? provider.amountToArabicWords(price, currency: 'ريال')
        : null;

    final timeFormat = DateFormat('HH:mm', 'ar');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مُلخص الحجز:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_startTime != null)
              Text(
                'البداية: ${timeFormat.format(DateTime(0, 1, 1, _startTime!.hour, _startTime!.minute))}',
              ),
            Text('المدة: $_durationHours ساعة'),
            const SizedBox(height: 8),
            Text('الإجمالي (رقماً): ${price.toStringAsFixed(2)} ريال'),
            if (priceWords != null) ...[
              const SizedBox(height: 4),
              Text('الإجمالي (كتابة): $priceWords'),
            ],
            if (coachWage != null) ...[
              const SizedBox(height: 8),
              Text(
                'أجر المدرب التقريبي: ${coachWage.toStringAsFixed(2)} ريال',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
