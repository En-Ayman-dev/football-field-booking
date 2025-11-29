// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../../core/database/database_helper.dart';
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
  double _durationHours = 1;

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

  void _recalculatePrices(BuildContext ctx) {
    final bookingProvider =
        Provider.of<BookingProvider>(ctx, listen: false);

    if (_selectedPitch == null) {
      setState(() {
        _calculatedTotalPrice = 0;
        _calculatedCoachWage = null;
      });
      return;
    }

    final pitchPrice = _selectedPitch!.pricePerHour ?? 0;
    final totalPrice = bookingProvider.calculateTotalPrice(
      durationHours: _durationHours,
      pitchPricePerHour: pitchPrice,
      period: _period,
      isIndoor: _selectedPitch!.isIndoor,
    );

    double? coachWage;
    if (_selectedCoach != null && _selectedCoach!.pricePerHour != null) {
      coachWage = bookingProvider.calculateCoachWage(
        durationHours: _durationHours,
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
    final bookingProvider =
        Provider.of<BookingProvider>(ctx, listen: false);

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

    // Permissions: ensure user can manage bookings
    if (!currentUser.canManageBookings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ليس لديك صلاحية إنشاء الحجوزات.'),
        ),
      );
      return;
    }

    _formKey.currentState?.save();

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
      durationHours: _durationHours,
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
          content: Text(
            bookingProvider.errorMessage ?? 'تعذر حفظ الحجز.',
          ),
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
            title: const Text('إنشاء حجز جديد'),
          ),
          body: Consumer<BookingProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Text(provider.errorMessage!),
                );
              }

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
                          _recalculatePrices(providerContext);
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
                          _recalculatePrices(providerContext);
                        },
                      ),
                      const SizedBox(height: 16),

                      // اسم الفريق
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'اسم الفريق',
                        ),
                        onSaved: (value) {
                          _teamName = value?.trim();
                        },
                      ),
                      const SizedBox(height: 12),

                      // الهاتف
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                        ),
                        keyboardType: TextInputType.phone,
                        onSaved: (value) {
                          _customerPhone = value?.trim();
                        },
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
                          _recalculatePrices(providerContext);
                        },
                      ),
                      const SizedBox(height: 16),

                      // وقت البدء والمدة
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickStartTime(providerContext),
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
                              initialValue: _durationHours.toString(),
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
                                _recalculatePrices(providerContext);
                              },
                              onSaved: (value) {
                                final text = value?.trim() ?? '';
                                final d = double.tryParse(
                                  text.replaceAll(',', '.'),
                                );
                                _durationHours = d ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ملاحظات (اختياري)
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                        ),
                        maxLines: 2,
                        onSaved: (value) {
                          _notes = value?.trim();
                        },
                      ),
                      const SizedBox(height: 16),

                      // السعر المحسوب
                      _buildPricePreview(providerContext),
                      const SizedBox(height: 24),

                      // الأزرار
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _submit(providerContext, isPaid: false),
                              child: const Text('حفظ كمعلّق'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _submit(providerContext, isPaid: true),
                              child: const Text('حفظ ودفع'),
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
    final provider =
        Provider.of<BookingProvider>(context, listen: false);

    final price = _calculatedTotalPrice;
    final coachWage = _calculatedCoachWage;

    final priceWords = price > 0
        ? provider.amountToArabicWords(price, currency: 'ريال')
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'السعر المحسوب:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
