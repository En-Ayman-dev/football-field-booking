// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../../data/models/booking.dart';
import '../../../../data/models/pitch.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب
import '../providers/booking_provider.dart';
import '../widgets/booking_action_buttons.dart';
import 'add_booking_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedPitchId;
  String _selectedPeriod = 'all';

  // --- الدوال البرمجية (بدون تغيير في المنطق) ---
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
      setState(() => _selectedDate = picked);
      final provider = Provider.of<BookingProvider>(context, listen: false);
      await provider.fetchBookings(
        date: _selectedDate,
        pitchId: _selectedPitchId,
        period: _selectedPeriod == 'all' ? null : _selectedPeriod,
        keepExistingFiltersIfNull: false,
      );
    }
  }

  Future<void> _openAddBooking(BuildContext context) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddBookingScreen()));
    await provider.fetchBookings(
      date: _selectedDate,
      pitchId: _selectedPitchId,
      period: _selectedPeriod == 'all' ? null : _selectedPeriod,
      keepExistingFiltersIfNull: false,
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد', style: TextStyle(fontSize: 16.sp)),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
    }
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
          keepExistingFiltersIfNull: false,
        ),
      child: Builder(
        builder: (providerContext) {
          final auth0 = Provider.of<AuthProvider>(providerContext);
          final canAddBooking = auth0.isAdmin || (auth0.currentUser?.canManageBookings ?? false);
          
          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                title: Text('قائمة الحجوزات', style: TextStyle(fontSize: 18.sp)),
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout, size: 22.sp),
                    onPressed: () => _performLogout(context),
                  ),
                ],
              ),
              body: Consumer<BookingProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.bookings.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      _buildFiltersBar(context, provider),
                      Divider(height: 1.h, thickness: 1),
                      Expanded(
                        child: provider.bookings.isEmpty
                            ? Center(child: Text('لا توجد حجوزات لهذا اليوم.', style: TextStyle(fontSize: 14.sp)))
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: 10.h), // مساحة للفلوتنج بوتن
                                itemCount: provider.bookings.length,
                                itemBuilder: (context, index) {
                                  final booking = provider.bookings[index];
                                  final pitch = provider.pitches.firstWhere(
                                    (p) => p.id == booking.pitchId,
                                    orElse: () => Pitch(id: booking.pitchId, name: 'ملعب ${booking.pitchId}', location: null, pricePerHour: null, isIndoor: false, isActive: true, isDirty: false, updatedAt: booking.updatedAt),
                                  );
                                  return _buildBookingCard(context: context, booking: booking, pitch: pitch, isAdmin: auth0.isAdmin);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
              floatingActionButton: canAddBooking
                  ? FloatingActionButton(
                      onPressed: () => _openAddBooking(providerContext),
                      child: Icon(Icons.add, size: 24.sp),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context, BookingProvider provider) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    return Card(
      margin: EdgeInsets.all(3.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        labelStyle: TextStyle(fontSize: 12.sp),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateFormat.format(_selectedDate), style: TextStyle(fontSize: 12.sp)),
                          Icon(Icons.calendar_today_outlined, size: 16.sp),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: 'الملعب',
                      labelStyle: TextStyle(fontSize: 12.sp),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    ),
                    initialValue: _selectedPitchId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('كل الملاعب')),
                      ...provider.pitches.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.name, style: TextStyle(fontSize: 12.sp)))),
                    ],
                    onChanged: (value) async {
                      setState(() => _selectedPitchId = value);
                      await provider.fetchBookings(date: _selectedDate, pitchId: _selectedPitchId, period: _selectedPeriod == 'all' ? null : _selectedPeriod, keepExistingFiltersIfNull: false);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            SizedBox(
              height: 5.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPeriodChip(label: 'الكل', value: 'all', provider: provider),
                  SizedBox(width: 2.w),
                  _buildPeriodChip(label: 'صباحي', value: 'morning', provider: provider),
                  SizedBox(width: 2.w),
                  _buildPeriodChip(label: 'مسائي', value: 'evening', provider: provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip({required String label, required String value, required BookingProvider provider}) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.sp)),
      selected: isSelected,
      onSelected: (selected) async {
        if (!selected) return;
        setState(() => _selectedPeriod = value);
        await provider.fetchBookings(date: _selectedDate, pitchId: _selectedPitchId, period: _selectedPeriod == 'all' ? null : _selectedPeriod, keepExistingFiltersIfNull: false);
      },
    );
  }

  Widget _buildBookingCard({required BuildContext context, required Booking booking, required Pitch pitch, required bool isAdmin}) {
    final _ = Theme.of(context);
    final timeFormat = DateFormat('HH:mm', 'ar');
    final startText = timeFormat.format(booking.startTime);
    final endText = timeFormat.format(booking.endTime);
    
    Color statusColor = booking.status == 'paid' ? AppTheme.success : AppTheme.warning;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.sp)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight( // يضمن أن الشريط الجانبي يمتد حسب محتوى الكارت
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 1.5.w, color: statusColor),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                title: Text(
                  booking.teamName?.isEmpty ?? true ? 'بدون اسم فريق' : booking.teamName!,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 0.5.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardIconText(Icons.access_time, '$startText - $endText'),
                      _buildCardIconText(Icons.stadium_outlined, pitch.name),
                      _buildCardIconText(Icons.payments_outlined, '${booking.totalPrice?.toStringAsFixed(2)} ريال', isBold: true),
                    ],
                  ),
                ),
                trailing: _buildBookingActionsMenu(context: context, booking: booking, pitchName: pitch.name, isAdmin: isAdmin),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIconText(IconData icon, String text, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey),
          SizedBox(width: 2.w),
          Text(text, style: TextStyle(fontSize: 12.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildBookingActionsMenu({required BuildContext context, required Booking booking, required String pitchName, required bool isAdmin}) {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20.sp),
      onSelected: (value) async {
        if (value == 'pay') {
          if (booking.status == 'paid') return;
          await provider.updateBookingStatus(booking.id!, 'paid');
        } else if (value == 'print') {
          await BookingActionButtons.showPrintOptions(context, booking: booking, pitchName: pitchName);
        } else if (value == 'share') {
          await BookingActionButtons.shareBooking(booking, pitchName: pitchName);
        } else if (value == 'delete') {
          if (!isAdmin) return;
          final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('حذف الحجز'), content: const Text('هل أنت متأكد؟'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))]));
          if (confirm == true) await provider.deleteBooking(booking.id!);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pay', child: Text('تسديد المبلغ')),
        const PopupMenuItem(value: 'print', child: Text('طباعة')),
        const PopupMenuItem(value: 'share', child: Text('مشاركة')),
        if (isAdmin) const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
      ],
    );
  }
}