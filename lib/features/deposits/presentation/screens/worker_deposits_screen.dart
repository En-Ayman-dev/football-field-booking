// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب
import '../providers/deposit_provider.dart';
import '../../../../data/models/user.dart';
import 'package:intl/intl.dart';

class WorkerDepositsScreen extends StatefulWidget {
  const WorkerDepositsScreen({super.key});

  @override
  State<WorkerDepositsScreen> createState() => _WorkerDepositsScreenState();
}

class _WorkerDepositsScreenState extends State<WorkerDepositsScreen> {
  double _totalBookingsAmount = 0.0;
  bool _isLoadingTotal = false;

  @override
  void initState() {
    super.initState();
    _loadTotal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final depositProvider =
          Provider.of<DepositProvider>(context, listen: false);
      depositProvider.fetchRequests(
          forAdmin: false, userId: auth.currentUser?.id);
    });
  }

  Future<void> _loadTotal() async {
    _isLoadingTotal = true;
    setState(() {});
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) return;
      final db = DatabaseHelper();

      final bookingRows = await db.rawQuery(
          'SELECT SUM(IFNULL(total_price,0)) as s FROM ${DatabaseHelper.tableBookings} WHERE created_by_user_id = ?',
          [user.id]);
      final totalSales = bookingRows.first['s'] != null 
          ? (bookingRows.first['s'] as num).toDouble() 
          : 0.0;

      final depositRows = await db.rawQuery(
          'SELECT SUM(IFNULL(amount,0)) as s FROM ${DatabaseHelper.tableDepositRequests} WHERE user_id = ? AND status = ?',
          [user.id, 'approved']);
      final totalApproved = depositRows.first['s'] != null 
          ? (depositRows.first['s'] as num).toDouble() 
          : 0.0;

      double netAmount = totalSales - totalApproved;
      if (netAmount < 0) netAmount = 0;

      _totalBookingsAmount = netAmount;

    } catch (e) {
      if (kDebugMode) print('Error computing total bookings: $e');
    } finally {
      _isLoadingTotal = false;
      setState(() {});
    }
  }

  Future<void> _showCreateDepositDialog(User user) async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);
    final amountController = TextEditingController(
        text: _totalBookingsAmount.toStringAsFixed(2));
    final noteController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp))), // متجاوب
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: EdgeInsets.all(4.w), // متجاوب
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('إنشاء طلب توريد',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontSize: 16.sp)), // متجاوب
                SizedBox(height: 1.5.h), // متجاوب
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  style: TextStyle(fontSize: 14.sp), // متجاوب
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الرجاء إدخال المبلغ';
                    }
                    final parsed =
                        double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'المبلغ يجب أن يكون أكبر من صفر';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 1.h), // متجاوب
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)'),
                  style: TextStyle(fontSize: 14.sp), // متجاوب
                  maxLines: 3,
                ),
                SizedBox(height: 2.h), // متجاوب
                SizedBox(
                  width: double.infinity,
                  height: 6.h, // متجاوب
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final amount = double.tryParse(
                                amountController.text
                                    .replaceAll(',', '.')) ??
                            0.0;
                        final success = await depositProvider.createRequest(
                          user: user,
                          amount: amount,
                          note: noteController.text.trim(),
                        );
                        if (success) {
                          Navigator.of(ctx).pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                depositProvider.errorMessage ??
                                    'تعذر إنشاء الطلب',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text('إرسال الطلب', style: TextStyle(fontSize: 14.sp)), // متجاوب
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await _loadTotal();
      final depositProvider =
          Provider.of<DepositProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      depositProvider.fetchRequests(
          forAdmin: false, userId: auth.currentUser?.id);
    }
  }

  String formatAmount(double a) {
    final f = NumberFormat('#,##0.##', 'ar');
    return f.format(a);
  }

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    if (user == null) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: const Scaffold(
          body: Center(
            child: Text('لا يوجد موظف مسجل الدخول حالياً.'),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('توريد المبالغ', style: TextStyle(fontSize: 18.sp))), // متجاوب
        body: Padding(
          padding: EdgeInsets.all(4.w), // متجاوب
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w), // متجاوب
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8.sp), // متجاوب
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4.sp, // متجاوب
                      spreadRadius: 1.sp, // متجاوب
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المبلغ المتبقي (غير المورد)', style: TextStyle(fontSize: 12.sp)), // متجاوب
                          SizedBox(height: 1.h), // متجاوب
                          _isLoadingTotal
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  formatAmount(_totalBookingsAmount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontSize: 20.sp, fontWeight: FontWeight.bold), // متجاوب
                                ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      ),
                      onPressed: _totalBookingsAmount <= 0 
                          ? null 
                          : () => _showCreateDepositDialog(user),
                      child: Text('إنشاء طلب', style: TextStyle(fontSize: 12.sp)), // متجاوب
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h), // متجاوب
              Text('طلبات التوريد السابقة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15.sp)), // متجاوب
              SizedBox(height: 1.h), // متجاوب
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadTotal();
                    await depositProvider.fetchRequests(
                        forAdmin: false, userId: user.id);
                  },
                  child: ListView.builder(
                    itemCount: depositProvider.isLoading
                        ? 1
                        : (depositProvider.requests.isEmpty
                            ? 1
                            : depositProvider.requests.length),
                    itemBuilder: (ctx, idx) {
                      if (depositProvider.isLoading) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.h),
                            child: const CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (depositProvider.requests.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.h),
                            child: Text('لا توجد طلبات توريد بعد.', style: TextStyle(fontSize: 14.sp)),
                          ),
                        );
                      }
                      final r = depositProvider.requests[idx];
                      
                      Color statusColor;
                      switch(r.status) {
                        case 'approved': statusColor = Colors.green; break;
                        case 'rejected': statusColor = Colors.red; break;
                        default: statusColor = Colors.orange;
                      }

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.8.h), // متجاوب
                        padding: EdgeInsets.all(3.w), // متجاوب
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8.sp), // متجاوب
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4.sp,
                              spreadRadius: 1.sp,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatAmount(r.amount),
                                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold), // متجاوب
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h), // متجاوب
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4.sp),
                                          border: Border.all(color: statusColor.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          r.status == 'approved' ? 'مقبول' : 
                                          r.status == 'rejected' ? 'مرفوض' : 'معلق',
                                          style: TextStyle(color: statusColor, fontSize: 11.sp, fontWeight: FontWeight.bold), // متجاوب
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.8.h), // متجاوب
                                  if (r.note != null && r.note!.isNotEmpty)
                                    Text('ملاحظة: ${r.note}', style: TextStyle(fontSize: 12.sp)), // متجاوب
                                  Text(
                                    'تاريخ: ${DateFormat.yMd('ar').add_Hm().format(r.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.sp), // متجاوب
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}