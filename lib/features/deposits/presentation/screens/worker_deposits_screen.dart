// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import 'dart:ui' as ui;

import '../../../../core/utils/responsive_helper.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/models/booking.dart';
import '../providers/deposit_provider.dart';

class WorkerDepositsScreen extends StatefulWidget {
  const WorkerDepositsScreen({super.key});

  @override
  State<WorkerDepositsScreen> createState() => _WorkerDepositsScreenState();
}

class _WorkerDepositsScreenState extends State<WorkerDepositsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // قائمة الحجوزات المختارة للتوريد (نستخدم Set لمنع التكرار)
  final Set<int> _selectedBookingIds = {};
  double _totalSelectedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // تحميل البيانات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<DepositProvider>(
          context,
          listen: false,
        ).fetchWorkerData(auth.currentUser!.id!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // تحديد/إلغاء تحديد حجز واحد
  void _toggleBookingSelection(Booking booking, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedBookingIds.add(booking.id!);
        // ملاحظة: totalPrice هنا هو المبلغ الصافي القادم من الـ Provider
        _totalSelectedAmount += (booking.totalPrice ?? 0);
      } else {
        _selectedBookingIds.remove(booking.id!);
        _totalSelectedAmount -= (booking.totalPrice ?? 0);
      }
    });
  }

  // تحديد/إلغاء تحديد الكل
  void _selectAll(List<Booking> allBookings) {
    setState(() {
      if (_selectedBookingIds.length == allBookings.length) {
        // إلغاء تحديد الكل
        _selectedBookingIds.clear();
        _totalSelectedAmount = 0;
      } else {
        // تحديد الكل
        _selectedBookingIds.clear();
        _totalSelectedAmount = 0;
        for (var b in allBookings) {
          _selectedBookingIds.add(b.id!);
          _totalSelectedAmount += (b.totalPrice ?? 0);
        }
      }
    });
  }

  // تنفيذ عملية التوريد
  Future<void> _submitDeposit() async {
    if (_selectedBookingIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'تأكيد التوريد',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل تود توريد مبلغ ${_totalSelectedAmount.toStringAsFixed(2)} ريال لـ ${_selectedBookingIds.length} حجوزات؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'تأكيد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<DepositProvider>(context, listen: false);

      final success = await provider.submitDepositRequestWithBookings(
        userId: auth.currentUser!.id!,
        amount: _totalSelectedAmount,
        bookingIds: _selectedBookingIds.toList(),
        note: 'توريد ${_selectedBookingIds.length} حجوزات',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب التوريد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // تصفير الاختيارات
        setState(() {
          _selectedBookingIds.clear();
          _totalSelectedAmount = 0;
        });
        // الانتقال لتبويب السجل
        _tabController.animateTo(1);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'حدث خطأ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DepositProvider>(context);
    final bookings = provider.workerPaidBookings;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('التوريد المالي', style: TextStyle(fontSize: 18.sp)),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'توريد جديد'),
              Tab(text: 'سجل التوريدات'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // --- التبويب الأول: توريد جديد ---
            Column(
              children: [
                // 1. إشعار الحجوزات المعلقة
                if (provider.pendingBookingsCount > 0)
                  MaterialBanner(
                    backgroundColor: Colors.orange.shade50,
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    content: Text(
                      'لديك ${provider.pendingBookingsCount} حجوزات معلقة. يجب تسديدها أولاً لتظهر هنا.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(
                            context,
                          ).hideCurrentMaterialBanner();
                        },
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),

                // 2. زر تحديد الكل (يظهر فقط إذا وجدت حجوزات)
                if (bookings.isNotEmpty)
                  Container(
                    color: Colors.grey.shade100,
                    child: CheckboxListTile(
                      title: Text(
                        "تحديد الكل (${bookings.length})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      value:
                          _selectedBookingIds.length == bookings.length &&
                          bookings.isNotEmpty,
                      onChanged: (v) => _selectAll(bookings),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.green,
                    ),
                  ),

                // 3. قائمة الحجوزات القابلة للتوريد
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 40.sp,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                "لا توجد مبالغ مدفوعة جاهزة للتوريد",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: bookings.length,
                          separatorBuilder: (ctx, i) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            final isSelected = _selectedBookingIds.contains(
                              booking.id,
                            );
                            final dateFormat = DateFormat(
                              'yyyy/MM/dd HH:mm',
                              'ar',
                            );

                            // --- الحسابات للعرض فقط ---
                            // booking.totalPrice القادم من الـ Provider هو الصافي بالفعل
                            final double netPrice = booking.totalPrice ?? 0.0;
                            final double coachWage = booking.coachWage ?? 0.0;
                            // نعيد بناء السعر الأصلي لغرض العرض
                            final double originalPrice = netPrice + coachWage;

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: Colors.green,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 0.5.h,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    booking.teamName ?? 'بدون اسم',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  // عرض المبلغ الصافي للتوريد
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${netPrice.toStringAsFixed(0)} ريال',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                      if (coachWage > 0)
                                        Text(
                                          'صافي التوريد',
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${dateFormat.format(booking.startTime)} - الملعب ${booking.pitchId}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  // --- عرض تفاصيل الخصم إذا وجد مدرب ---
                                  if (coachWage > 0) ...[
                                    SizedBox(height: 0.5.h),
                                    Row(
                                      children: [
                                        Text(
                                          'إجمالي: ${originalPrice.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: Colors.grey[600],
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          '- المدرب: ${coachWage.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              onChanged: (val) =>
                                  _toggleBookingSelection(booking, val),
                            );
                          },
                        ),
                ),
              ],
            ),

            // --- التبويب الثاني: السجل ---
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.requests.isEmpty
                ? Center(
                    child: Text(
                      "لا يوجد سجل توريدات سابق",
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.requests.length,
                    itemBuilder: (context, index) {
                      final req = provider.requests[index];
                      Color statusColor = req.status == 'approved'
                          ? Colors.green
                          : (req.status == 'rejected'
                                ? Colors.red
                                : Colors.orange);
                      String statusText = req.status == 'approved'
                          ? 'مقبول'
                          : (req.status == 'rejected'
                                ? 'مرفوض'
                                : 'قيد المراجعة');

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.1),
                            child: Icon(
                              req.status == 'approved'
                                  ? Icons.check
                                  : (req.status == 'rejected'
                                        ? Icons.close
                                        : Icons.hourglass_bottom),
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            '${req.amount.toStringAsFixed(2)} ريال',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'yyyy/MM/dd hh:mm a',
                                  'ar',
                                ).format(req.createdAt),
                                style: TextStyle(fontSize: 11.sp),
                              ),
                              if (req.note != null && req.note!.isNotEmpty)
                                Text(
                                  req.note!,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),

        // زر التوريد العائم (يظهر فقط عند اختيار حجوزات في التبويب الأول)
        floatingActionButton:
            (_selectedBookingIds.isNotEmpty && _tabController.index == 0)
            ? FloatingActionButton.extended(
                onPressed: _submitDeposit,
                label: Text(
                  'توريد ${_totalSelectedAmount.toStringAsFixed(0)} ريال',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.send),
                backgroundColor: Colors.green,
              )
            : null,
      ),
    );
  }
}
