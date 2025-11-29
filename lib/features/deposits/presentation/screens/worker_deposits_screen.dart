// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/database/database_helper.dart';
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

      // 1. جلب إجمالي مبالغ الحجوزات التي أنشأها هذا العامل
      final bookingRows = await db.rawQuery(
          'SELECT SUM(IFNULL(total_price,0)) as s FROM ${DatabaseHelper.tableBookings} WHERE created_by_user_id = ?',
          [user.id]);
      final totalSales = bookingRows.first['s'] != null 
          ? (bookingRows.first['s'] as num).toDouble() 
          : 0.0;

      // 2. جلب إجمالي مبالغ التوريد التي حالتها "approved" فقط
      final depositRows = await db.rawQuery(
          'SELECT SUM(IFNULL(amount,0)) as s FROM ${DatabaseHelper.tableDepositRequests} WHERE user_id = ? AND status = ?',
          [user.id, 'approved']);
      final totalApproved = depositRows.first['s'] != null 
          ? (depositRows.first['s'] as num).toDouble() 
          : 0.0;

      // 3. المبلغ المعروض هو الفرق (الصافي)
      double netAmount = totalSales - totalApproved;
      if (netAmount < 0) netAmount = 0; // حماية إضافية لعدم ظهور قيم سالبة

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
    // نقترح المبلغ المتبقي (الصافي) في الحقل افتراضياً
    final amountController = TextEditingController(
        text: _totalBookingsAmount.toStringAsFixed(2));
    final noteController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('إنشاء طلب توريد',
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الرجاء إدخال المبلغ';
                    }
                    final parsed =
                        double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'المبلغ يجب أن يكون أكبر من صفر';
                    }
                    if (parsed > _totalBookingsAmount + 0.5) { 
                      // تحذير اختياري: إذا حاول توريد أكثر من الموجود (مع هامش بسيط للتقريب)
                      // يمكن إزالته إذا أردت السماح بذلك
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
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
                    child: const Text('إرسال الطلب'),
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
        appBar: AppBar(title: const Text('توريد المبالغ')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المبلغ المتبقي (غير المورد)'),
                        const SizedBox(height: 8),
                        _isLoadingTotal
                            ? const CircularProgressIndicator()
                            : Text(
                                formatAmount(_totalBookingsAmount),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                      ],
                    ),
                    ElevatedButton(
                      // تعطيل الزر إذا كان المبلغ صفر لتقليل الأخطاء، أو تركه متاحاً حسب الرغبة
                      onPressed: _totalBookingsAmount <= 0 
                          ? null 
                          : () => _showCreateDepositDialog(user),
                      child: const Text('إنشاء طلب توريد'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('طلبات التوريد السابقة',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
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
                        return const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (depositProvider.requests.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: 24.0),
                            child: Text('لا توجد طلبات توريد بعد.'),
                          ),
                        );
                      }
                      final r = depositProvider.requests[idx];
                      
                      // تحديد لون للحالة لتسهيل التمييز
                      Color statusColor;
                      switch(r.status) {
                        case 'approved': statusColor = Colors.green; break;
                        case 'rejected': statusColor = Colors.red; break;
                        default: statusColor = Colors.orange;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatAmount(r.amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: statusColor.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          r.status == 'approved' ? 'مقبول' : 
                                          r.status == 'rejected' ? 'مرفوض' : 'معلق',
                                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (r.note != null &&
                                      r.note!.isNotEmpty)
                                    Text('ملاحظة: ${r.note}'),
                                  Text(
                                    'تاريخ: ${DateFormat.yMd('ar').add_Hm().format(r.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
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