// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../../data/models/booking.dart';
import '../../../../data/models/coach.dart';
import '../../../../data/models/pitch.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/database/database_helper.dart';
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

  // --- الدوال البرمجية ---
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
    // نمرر التاريخ المختار للشاشة لسهولة الإدخال
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddBookingScreen()));
    // تحديث القائمة عند العودة
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
          // السماح بالإضافة للأدمن أو من لديه صلاحية
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
                                padding: EdgeInsets.only(bottom: 10.h), 
                                itemCount: provider.bookings.length,
                                itemBuilder: (context, index) {
                                  final booking = provider.bookings[index];
                                  // محاولة العثور على الملعب المرتبط
                                  final pitch = provider.pitches.firstWhere(
                                    (p) => p.id == booking.pitchId,
                                    orElse: () => Pitch(id: booking.pitchId, name: 'ملعب ${booking.pitchId}', location: null, pricePerHour: null, isIndoor: false, isActive: true, isDirty: false, updatedAt: booking.updatedAt),
                                  );
                                  // محاولة العثور على المدرب
                                  final coach = (booking.coachId != null && provider.coaches.isNotEmpty) 
                                      ? provider.coaches.firstWhere((c) => c.id == booking.coachId, orElse: () => Coach(name: 'غير معروف', phone: '', specialization: '', pricePerHour: 0, isActive: true, isDirty: false, updatedAt: DateTime.now()))
                                      : null;

                                  return _buildBookingCard(
                                    context: context, 
                                    booking: booking, 
                                    pitch: pitch, 
                                    coachName: coach?.name
                                  );
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

  Widget _buildBookingCard({required BuildContext context, required Booking booking, required Pitch pitch, String? coachName}) {
    final timeFormat = DateFormat('HH:mm', 'ar');
    final startText = timeFormat.format(booking.startTime);
    final endText = timeFormat.format(booking.endTime);
    
    // --- منطق الألوان الجديد ---
    Color statusColor;
    String statusText = '';
    
    if (booking.status == 'cancelled') {
      statusColor = Colors.red;
      statusText = ' (ملغي)';
    } else if (booking.status == 'paid') {
      statusColor = Colors.green; // مدفوع
    } else {
      statusColor = Colors.orange; // معلق (pending)
    }
    // ---------------------------

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.sp)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الشريط الملون الجانبي يوضح الحالة
            Container(width: 2.w, color: statusColor),
            
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                title: Row(
                  children: [
                    Text(
                      booking.teamName?.isEmpty ?? true ? 'بدون اسم فريق' : booking.teamName!,
                      style: TextStyle(
                        fontSize: 15.sp, 
                        fontWeight: FontWeight.bold,
                        // إضافة خط شطب على الاسم إذا كان ملغياً
                        decoration: booking.status == 'cancelled' ? TextDecoration.lineThrough : null,
                        color: booking.status == 'cancelled' ? Colors.grey : null,
                      ),
                    ),
                    if (statusText.isNotEmpty)
                      Text(statusText, style: TextStyle(fontSize: 12.sp, color: statusColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 0.5.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardIconText(Icons.access_time, '$startText - $endText'),
                      _buildCardIconText(Icons.stadium_outlined, pitch.name),
                      _buildCardIconText(
                        Icons.payments_outlined, 
                        '${booking.totalPrice?.toStringAsFixed(2)} ريال', 
                        isBold: true,
                        // جعل السعر باهتاً إذا كان ملغياً
                        color: booking.status == 'cancelled' ? Colors.grey : Colors.black
                      ),
                    ],
                  ),
                ),
                // --- هنا التغيير الجذري ---
                // استبدال القائمة القديمة بزر يستدعي BookingActionButtons
                trailing: IconButton(
                  icon: Icon(Icons.more_vert, size: 22.sp),
                  onPressed: () {
                    // استدعاء القائمة الموحدة الجديدة
                    BookingActionButtons.showBookingOptions(
                      context,
                      booking: booking,
                      pitchName: pitch.name,
                      coachName: coachName,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIconText(IconData icon, String text, {bool isBold = false, Color color = Colors.black}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey),
          SizedBox(width: 2.w),
          Text(text, style: TextStyle(fontSize: 12.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}