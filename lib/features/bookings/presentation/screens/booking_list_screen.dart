// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;


import '../../../../data/models/booking.dart';
import '../../../../data/models/pitch.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../providers/booking_provider.dart';
import 'add_booking_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedPitchId; // null = الكل, 1, 2
  String _selectedPeriod = 'all'; // all / morning / evening

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'اختر التاريخ',
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      final provider = Provider.of<BookingProvider>(context, listen: false);
      await provider.fetchBookings(
        date: _selectedDate,
        pitchId: _selectedPitchId,
        period: _selectedPeriod == 'all' ? null : _selectedPeriod,
      );
    }
  }

  Future<void> _openAddBooking(BuildContext context) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddBookingScreen()));
    // بعد العودة من شاشة إضافة حجز نعيد تحميل القائمة مع نفس الفلاتر
    await provider.fetchBookings(
      date: _selectedDate,
      pitchId: _selectedPitchId,
      period: _selectedPeriod == 'all' ? null : _selectedPeriod,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BookingProvider>(
      create: (_) => BookingProvider(DatabaseHelper())
        ..loadData()
        ..fetchBookings(
          date: _selectedDate,
          pitchId: _selectedPitchId,
          period: _selectedPeriod == 'all' ? null : _selectedPeriod,
        ),
      child: Builder(
        builder: (providerContext) {
          return Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Scaffold(
              appBar: AppBar(title: const Text('قائمة الحجوزات')),
              body: Consumer<BookingProvider>(
                builder: (context, provider, _) {
              final auth = Provider.of<AuthProvider>(context);
              final isAdmin = auth.isAdmin;

              if (provider.isLoading && provider.bookings.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null && provider.bookings.isEmpty) {
                return Center(child: Text(provider.errorMessage!));
              }

              return Column(
                children: [
                  _buildFiltersBar(context, provider),
                  const Divider(height: 0),
                  Expanded(
                    child: provider.bookings.isEmpty
                        ? const Center(
                            child: Text('لا توجد حجوزات لهذا اليوم.'),
                          )
                        : ListView.builder(
                            itemCount: provider.bookings.length,
                            itemBuilder: (context, index) {
                              final booking = provider.bookings[index];
                              final pitch = provider.pitches.firstWhere(
                                (p) => p.id == booking.pitchId,
                                orElse: () => Pitch(
                                  id: booking.pitchId,
                                  name: 'ملعب ${booking.pitchId}',
                                  location: null,
                                  pricePerHour: null,
                                  isIndoor: false,
                                  isActive: true,
                                  isDirty: false,
                                  updatedAt: booking.updatedAt,
                                ),
                              );
                              return _buildBookingCard(
                                context: context,
                                booking: booking,
                                pitch: pitch,
                                isAdmin: isAdmin,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
                
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _openAddBooking(providerContext),
                child: const Icon(Icons.add),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context, BookingProvider provider) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                // التاريخ
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isToday
                                ? 'اليوم (${dateFormat.format(_selectedDate)})'
                                : dateFormat.format(_selectedDate),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // الملعب
                Expanded(
                  child: 
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'الملعب',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    initialValue: _selectedPitchId,
                    items: const [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('كل الملاعب'),
                      ),
                      DropdownMenuItem<int?>(value: 1, child: Text('ملعب 1')),
                      DropdownMenuItem<int?>(value: 2, child: Text('ملعب 2')),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        _selectedPitchId = value;
                      });
                      await provider.fetchBookings(
                        date: _selectedDate,
                        pitchId: _selectedPitchId,
                        period: _selectedPeriod == 'all'
                            ? null
                            : _selectedPeriod,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // الفترة (Chips)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPeriodChip(
                    label: 'الكل',
                    value: 'all',
                    provider: provider,
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    label: 'صباحي',
                    value: 'morning',
                    provider: provider,
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    label: 'مسائي',
                    value: 'evening',
                    provider: provider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required String value,
    required BookingProvider provider,
  }) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (!selected) return;
        setState(() {
          _selectedPeriod = value;
        });
        await provider.fetchBookings(
          date: _selectedDate,
          pitchId: _selectedPitchId,
          period: _selectedPeriod == 'all' ? null : _selectedPeriod,
        );
      },
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required Booking booking,
    required Pitch pitch,
    required bool isAdmin,
  }) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm', 'ar');
    final startText = timeFormat.format(booking.startTime);
    final endText = timeFormat.format(booking.endTime);

    final totalPrice = booking.totalPrice ?? 0;

    Color statusColor;
    if (booking.status == 'paid') {
      statusColor = Colors.green;
    } else {
      // نعتبر الباقي pending
      statusColor = Colors.amber;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(width: 5, height: 80, color: statusColor),
          Expanded(
            child: ListTile(
              title: Text(
                booking.teamName == null || booking.teamName!.isEmpty
                    ? 'بدون اسم فريق'
                    : booking.teamName!,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الوقت: $startText - $endText'),
                  Text('الملعب: ${pitch.name}'),
                  Text('المبلغ: ${totalPrice.toStringAsFixed(2)} ريال'),
                ],
              ),
              trailing: _buildBookingActionsMenu(
                context: context,
                booking: booking,
                isAdmin: isAdmin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingActionsMenu({
    required BuildContext context,
    required Booking booking,
    required bool isAdmin,
  }) {
    final provider = Provider.of<BookingProvider>(context, listen: false);

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'pay') {
          if (booking.status == 'paid') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الحجز مدفوع بالفعل.')),
            );
            return;
          }
          await provider.updateBookingStatus(booking.id!, 'paid');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تسديد المبلغ للحجز.')),
            );
          }
        } else if (value == 'edit') {
          // لم يتم بناء شاشة تعديل تفصيلية حتى الآن
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('شاشة تعديل الحجز لم تُنفذ بعد.')),
            );
          }
        } else if (value == 'print') {
          // طباعة في الكونسول فقط كما هو مطلوب
          debugPrint('--- طباعة الحجز ---');
          debugPrint('ID: ${booking.id}');
          debugPrint('Team: ${booking.teamName}');
          debugPrint('Pitch ID: ${booking.pitchId}');
          debugPrint('Start: ${booking.startTime}');
          debugPrint('End: ${booking.endTime}');
          debugPrint('Total: ${booking.totalPrice}');
          debugPrint('Status: ${booking.status}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال بيانات الحجز للطباعة (Console).'),
              ),
            );
          }
        } else if (value == 'delete') {
          if (!isAdmin) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الحذف متاح للمدير فقط.')),
              );
            }
            return;
          }
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: ui.TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تأكيد الحذف'),
                content: const Text(
                  'هل أنت متأكد من حذف هذا الحجز؟ لا يمكن التراجع.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'حذف',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (confirm == true) {
            await provider.deleteBooking(booking.id!);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف الحجز بنجاح.')),
              );
            }
          }
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        items.add(
          const PopupMenuItem(value: 'pay', child: Text('تسديد المبلغ')),
        );
        items.add(const PopupMenuItem(value: 'edit', child: Text('تعديل')));
        items.add(const PopupMenuItem(value: 'print', child: Text('طباعة')));
        if (isAdmin) {
          items.add(
            const PopupMenuItem(
              value: 'delete',
              child: Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          );
        }
        return items;
      },
    );
  }
}
