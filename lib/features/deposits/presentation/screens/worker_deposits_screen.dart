// // ignore_for_file: depend_on_referenced_packages

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'dart:ui' as ui;
// import 'package:provider/provider.dart';
// import '../../../../providers/auth_provider.dart';
// import '../../../../core/database/database_helper.dart';
// import '../providers/deposit_provider.dart';
// import '../../../../data/models/user.dart';
// import 'package:intl/intl.dart';

// class WorkerDepositsScreen extends StatefulWidget {
//   const WorkerDepositsScreen({super.key});

//   @override
//   State<WorkerDepositsScreen> createState() => _WorkerDepositsScreenState();
// }

// class _WorkerDepositsScreenState extends State<WorkerDepositsScreen> {
//   double _totalBookingsAmount = 0.0;
//   bool _isLoadingTotal = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadTotal();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final auth = Provider.of<AuthProvider>(context, listen: false);
//       final depositProvider =
//           Provider.of<DepositProvider>(context, listen: false);
//       depositProvider.fetchRequests(
//           forAdmin: false, userId: auth.currentUser?.id);
//     });
//   }

//   Future<void> _loadTotal() async {
//     _isLoadingTotal = true;
//     setState(() {});
//     try {
//       final auth = Provider.of<AuthProvider>(context, listen: false);
//       final user = auth.currentUser;
//       if (user == null) return;
//       final db = DatabaseHelper();
//       final rows = await db.rawQuery(
//           'SELECT SUM(IFNULL(total_price,0)) as s FROM ${DatabaseHelper.tableBookings} WHERE created_by_user_id = ?',
//           [user.id]);
//       final s = rows.first['s'];
//       final value = s == null ? 0.0 : (s as num).toDouble();
//       _totalBookingsAmount = value;
//     } catch (e) {
//       if (kDebugMode) print('Error computing total bookings: $e');
//     } finally {
//       _isLoadingTotal = false;
//       setState(() {});
//     }
//   }

//   Future<void> _showCreateDepositDialog(User user) async {
//     final depositProvider =
//         Provider.of<DepositProvider>(context, listen: false);
//     final amountController = TextEditingController(
//         text: _totalBookingsAmount.toStringAsFixed(2));
//     final noteController = TextEditingController();

//     final formKey = GlobalKey<FormState>();
//     final confirmed = await showModalBottomSheet<bool>(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) => Padding(
//         padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Text('إنشاء طلب توريد',
//                     style: Theme.of(ctx).textTheme.titleMedium),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: amountController,
//                   keyboardType:
//                       const TextInputType.numberWithOptions(decimal: true),
//                   decoration: const InputDecoration(labelText: 'المبلغ'),
//                   validator: (v) {
//                     if (v == null || v.trim().isEmpty) {
//                       return 'الرجاء إدخال المبلغ';
//                     }
//                     final parsed =
//                         double.tryParse(v.replaceAll(',', '.'));
//                     if (parsed == null || parsed <= 0) {
//                       return 'المبلغ يجب أن يكون أكبر من صفر';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: noteController,
//                   decoration: const InputDecoration(
//                       labelText: 'ملاحظات (اختياري)'),
//                   maxLines: 3,
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       if (formKey.currentState?.validate() ?? false) {
//                         final amount = double.tryParse(
//                                 amountController.text
//                                     .replaceAll(',', '.')) ??
//                             0.0;
//                         final success = await depositProvider.createRequest(
//                           user: user,
//                           amount: amount,
//                           note: noteController.text.trim(),
//                         );
//                         if (success) {
//                           Navigator.of(ctx).pop(true);
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 depositProvider.errorMessage ??
//                                     'تعذر إنشاء الطلب',
//                               ),
//                             ),
//                           );
//                         }
//                       }
//                     },
//                     child: const Text('إرسال الطلب'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//     if (confirmed == true) {
//       await _loadTotal();
//       final depositProvider =
//           Provider.of<DepositProvider>(context, listen: false);
//       final auth = Provider.of<AuthProvider>(context, listen: false);
//       depositProvider.fetchRequests(
//           forAdmin: false, userId: auth.currentUser?.id);
//     }
//   }

//   String formatAmount(double a) {
//     final f = NumberFormat('#,##0.##', 'ar');
//     return f.format(a);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final depositProvider = Provider.of<DepositProvider>(context);
//     final auth = Provider.of<AuthProvider>(context);
//     final user = auth.currentUser;
//     if (user == null) {
//       return Directionality(
//         textDirection: ui.TextDirection.rtl,
//         child: const Scaffold(
//           body: Center(
//             child: Text('لا يوجد موظف مسجل الدخول حالياً.'),
//           ),
//         ),
//       );
//     }

//     return Directionality(
//       textDirection: ui.TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(title: const Text('توريد المبالغ')),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16.0),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).cardColor,
//                   borderRadius: BorderRadius.circular(8),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 4,
//                       spreadRadius: 1,
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('المبلغ الإجمالي للحجوزات'),
//                         const SizedBox(height: 8),
//                         _isLoadingTotal
//                             ? const CircularProgressIndicator()
//                             : Text(
//                                 formatAmount(_totalBookingsAmount),
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .headlineSmall,
//                               ),
//                       ],
//                     ),
//                     ElevatedButton(
//                       onPressed: () => _showCreateDepositDialog(user),
//                       child: const Text('إنشاء طلب توريد'),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text('طلبات التوريد',
//                   style: Theme.of(context).textTheme.titleMedium),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     await _loadTotal();
//                     await depositProvider.fetchRequests(
//                         forAdmin: false, userId: user.id);
//                   },
//                   child: ListView.builder(
//                     itemCount: depositProvider.isLoading
//                         ? 1
//                         : (depositProvider.requests.isEmpty
//                             ? 1
//                             : depositProvider.requests.length),
//                     itemBuilder: (ctx, idx) {
//                       if (depositProvider.isLoading) {
//                         return const Center(
//                           child: Padding(
//                             padding:
//                                 EdgeInsets.symmetric(vertical: 24.0),
//                             child: CircularProgressIndicator(),
//                           ),
//                         );
//                       }
//                       if (depositProvider.requests.isEmpty) {
//                         return const Center(
//                           child: Padding(
//                             padding:
//                                 EdgeInsets.symmetric(vertical: 24.0),
//                             child: Text('لا توجد طلبات توريد بعد.'),
//                           ),
//                         );
//                       }
//                       final r = depositProvider.requests[idx];
//                       return Container(
//                         margin: const EdgeInsets.symmetric(
//                             horizontal: 4, vertical: 6),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: Theme.of(context).cardColor,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color:
//                                   Colors.black.withOpacity(0.04),
//                               blurRadius: 4,
//                               spreadRadius: 1,
//                             ),
//                           ],
//                         ),
//                         child: IntrinsicWidth(
//                           stepWidth: 0,
//                           child: Row(
//                             crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       formatAmount(r.amount),
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .titleMedium,
//                                     ),
//                                     const SizedBox(height: 6),
//                                     if (r.note != null &&
//                                         r.note!.isNotEmpty)
//                                       Text('ملاحظة: ${r.note}'),
//                                     Text('الحالة: ${r.status}'),
//                                     Text(
//                                       'تاريخ: ${DateFormat.yMd('ar').add_Hm().format(r.createdAt)}',
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
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
      final rows = await db.rawQuery(
          'SELECT SUM(IFNULL(total_price,0)) as s FROM ${DatabaseHelper.tableBookings} WHERE created_by_user_id = ?',
          [user.id]);
      final s = rows.first['s'];
      final value = s == null ? 0.0 : (s as num).toDouble();
      _totalBookingsAmount = value;
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
                        const Text('المبلغ الإجمالي للحجوزات'),
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
                      onPressed: () => _showCreateDepositDialog(user),
                      child: const Text('إنشاء طلب توريد'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('طلبات التوريد',
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
                        // FIXED: Removed IntrinsicWidth to prevent layout errors with Expanded
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatAmount(r.amount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  if (r.note != null &&
                                      r.note!.isNotEmpty)
                                    Text('ملاحظة: ${r.note}'),
                                  Text('الحالة: ${r.status}'),
                                  Text(
                                    'تاريخ: ${DateFormat.yMd('ar').add_Hm().format(r.createdAt)}',
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