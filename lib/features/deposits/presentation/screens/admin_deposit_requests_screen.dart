// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/deposit_provider.dart';
import '../../../../providers/auth_provider.dart';

class AdminDepositRequestsScreen extends StatefulWidget {
  const AdminDepositRequestsScreen({super.key});

  @override
  State<AdminDepositRequestsScreen> createState() =>
      _AdminDepositRequestsScreenState();
}

class _AdminDepositRequestsScreenState extends State<AdminDepositRequestsScreen>
    with SingleTickerProviderStateMixin {
  // خريطة لتخزين أسماء المستخدمين مؤقتاً لتقليل استعلامات قاعدة البيانات
  final Map<int, String> _userNamesCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<DepositProvider>(context, listen: false);
    await provider.fetchRequests(forAdmin: true);
  }

  Future<String> _getUserName(int userId) async {
    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }
    try {
      final db = DatabaseHelper();
      final map = await db.getById(DatabaseHelper.tableUsers, userId);
      String name = 'مستخدم $userId';
      if (map != null) {
        name = (map['name'] as String?) ?? map['username']?.toString() ?? name;
      }
      _userNamesCache[userId] = name;
      return name;
    } catch (e) {
      if (kDebugMode) print('Error fetching user name: $e');
      return 'مستخدم $userId';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DepositProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // تقسيم الطلبات
    final pendingRequests = provider.requests
        .where((r) => r.status == 'pending')
        .toList();
    final historyRequests = provider.requests
        .where((r) => r.status != 'pending')
        .toList();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'إدارة التوريد المالي',
              style: TextStyle(fontSize: 18.sp),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'الطلبات الجديدة'),
                Tab(text: 'سجل التوريدات'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // --- التبويب 1: الطلبات المعلقة ---
              _buildRequestsList(
                context,
                pendingRequests,
                provider,
                auth,
                isPending: true,
                emptyMessage: 'لا توجد طلبات معلقة حالياً.',
              ),

              // --- التبويب 2: السجل ---
              _buildRequestsList(
                context,
                historyRequests,
                provider,
                auth,
                isPending: false,
                emptyMessage: 'لا يوجد سجل عمليات سابقة.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    List<dynamic> requests,
    DepositProvider provider,
    AuthProvider auth, {
    required bool isPending,
    required String emptyMessage,
  }) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(height: 30.h),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPending ? Icons.inbox_outlined : Icons.history,
                    size: 40.sp,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    emptyMessage,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: requests.length,
        itemBuilder: (ctx, idx) {
          final r = requests[idx];
          return FutureBuilder<String>(
            future: _getUserName(r.userId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'جاري التحميل...';

              Color statusColor;
              IconData statusIcon;
              switch (r.status) {
                case 'approved':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.hourglass_top;
              }

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.sp),
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الصف العلوي: الاسم + الحالة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18.sp,
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'yyyy/MM/dd hh:mm a',
                                      'ar',
                                    ).format(r.createdAt),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!isPending)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 12.sp,
                                    color: statusColor,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    r.status == 'approved'
                                        ? 'مقبول'
                                        : (r.status == 'rejected'
                                              ? 'مرفوض'
                                              : 'معلق'),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 1.5.h),
                      const Divider(height: 1),
                      SizedBox(height: 1.5.h),

                      // تفاصيل المبلغ والملاحظة
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المبلغ المورد',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${r.amount.toStringAsFixed(2)} ريال',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (r.note != null && r.note!.isNotEmpty)
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  r.note!,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // أزرار الإجراء (فقط للطلبات المعلقة)
                      if (isPending) ...[
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 1.2.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.sp),
                                  ),
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('قبول'),
                                onPressed: () => _confirmAction(
                                  context,
                                  'قبول',
                                  r,
                                  'approved',
                                  provider,
                                  auth,
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 1.2.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.sp),
                                  ),
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('رفض'),
                                onPressed: () => _confirmAction(
                                  context,
                                  'رفض',
                                  r,
                                  'rejected',
                                  provider,
                                  auth,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context,
    String actionName,
    dynamic request,
    String newStatus,
    DepositProvider provider,
    AuthProvider auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تأكيد $actionName',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من $actionName طلب التوريد بقيمة ${request.amount} ريال؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'تأكيد',
              style: TextStyle(
                color: newStatus == 'approved' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.updateRequestStatus(
        id: request.id!,
        status: newStatus,
        processedBy: auth.currentUser?.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم $actionName الطلب بنجاح'),
            backgroundColor: newStatus == 'approved'
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    }
  }
}
