// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/database/database_helper.dart';
import '../providers/deposit_provider.dart';
import '../../../../providers/auth_provider.dart';
import 'dart:ui' as ui;

class AdminDepositRequestsScreen extends StatefulWidget {
  const AdminDepositRequestsScreen({super.key});

  @override
  State<AdminDepositRequestsScreen> createState() => _AdminDepositRequestsScreenState();
}

class _AdminDepositRequestsScreenState extends State<AdminDepositRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<DepositProvider>(context, listen: false);
      await provider.fetchRequests(forAdmin: true);
    });
  }

  Future<String?> _userNameOf(int userId) async {
    try {
      final db = DatabaseHelper();
      final map = await db.getById(DatabaseHelper.tableUsers, userId);
      if (map != null) {
        return (map['name'] as String?) ?? map['username']?.toString();
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching user name: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DepositProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلبات التوريد')),
        body: RefreshIndicator(
          onRefresh: () async => provider.fetchRequests(forAdmin: true),
          child: ListView.builder(
                      itemCount: provider.isLoading
                          ? 1
                          : (provider.requests.isEmpty ? 1 : provider.requests.length),
                      itemBuilder: (ctx, idx) {
                        if (provider.isLoading) {
                          return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: CircularProgressIndicator()));
                        }
                        if (provider.requests.isEmpty) {
                          return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('لا توجد طلبات حالياً.')));
                        }
                        final r = provider.requests[idx];
                        return FutureBuilder<String?>(
                          future: _userNameOf(r.userId),
                          builder: (ctx, snap) {
                            final userName = snap.data ?? 'مستخدم: ${r.userId}';
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              padding: const EdgeInsets.all(4),
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('$userName — ${r.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 6),
                                          if (r.note != null && r.note!.isNotEmpty) Text('ملاحظة: ${r.note}'),
                                          Text('الحالة: ${r.status}'),
                                        ],
                                      ),
                                    ),
                                    if (r.status == 'pending')
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'قبول',
                                            icon: const Icon(Icons.check, color: Colors.green),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('تأكيد العملية'),
                                                  content: const Text('هل تريد قبول طلب التوريد؟'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('لا')),
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم')),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                await provider.updateRequestStatus(id: r.id!, status: 'approved', processedBy: auth.currentUser?.id);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'رفض',
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('تأكيد العملية'),
                                                  content: const Text('هل تريد رفض طلب التوريد؟'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('لا')),
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم')),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                await provider.updateRequestStatus(id: r.id!, status: 'rejected', processedBy: auth.currentUser?.id);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
