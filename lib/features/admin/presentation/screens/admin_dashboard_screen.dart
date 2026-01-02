// ignore_for_file: deprecated_member_use, depend_on_referenced_packages
import 'package:flutter/material.dart' hide SizedBox;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../core/utils/responsive_helper.dart'; // محرك التجاوب
import '../../../../core/utils/sync_ui_helper.dart'; // استيراد مساعد المزامنة الجديد
import '../../../pitches_balls/presentation/screens/manage_coaches_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_pitches_balls_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_staff_screen.dart';
import '../../../bookings/presentation/screens/add_booking_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../deposits/presentation/screens/admin_deposit_requests_screen.dart';
import '../../../deposits/presentation/screens/worker_deposits_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // --- دوال التنقل الموحدة ---
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).pushNamed('/reports');
  }

  Future<void> _performLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الخروج', style: TextStyle(fontSize: 16.sp)),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // التوجيه أولاً ثم تنفيذ الخروج لتجنب تعليق الواجهة
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    // إدارة الصلاحيات
    final bool isAdmin = auth.isAdmin;
    final bool isStaff = auth.isStaff;
    final bool canManagePitches = isAdmin || (user?.canManagePitches ?? false);
    final bool canManageCoaches = isAdmin || (user?.canManageCoaches ?? false);
    final bool canManageStaff = isAdmin;
    final bool canViewReports = isAdmin || (user?.canViewReports ?? false);
    final bool canManageBookings =
        isAdmin || (user?.canManageBookings ?? false);

    // حساب عدد الأعمدة بناءً على عرض الشاشة لضمان التجاوب
    int crossAxisCount = 2;
    if (ResponsiveHelper.screenWidth > 600) crossAxisCount = 3;
    if (ResponsiveHelper.screenWidth > 900) crossAxisCount = 4;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'لوحة التحكم',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تسجيل خروج',
              icon: Icon(Icons.logout, size: 22.sp),
              onPressed: () => _performLogout(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4.w,
                mainAxisSpacing: 4.w,
                childAspectRatio: 0.9, // تحسين النسبة لتقليل الفراغات
              ),
              children: [
                if (canManageStaff)
                  _DashboardCard(
                    icon: Icons.people_alt_rounded,
                    title: 'الموظفون',
                    subtitle: 'إدارة حسابات العاملين',
                    onTap: () =>
                        _navigateTo(context, const ManageStaffScreen()),
                  ),
                if (canManageCoaches)
                  _DashboardCard(
                    icon: Icons.sports_rounded,
                    title: 'المدربون',
                    subtitle: 'إدارة بيانات المدربين',
                    onTap: () =>
                        _navigateTo(context, const ManageCoachesScreen()),
                  ),
                if (canManagePitches)
                  _DashboardCard(
                    icon: Icons.stadium_rounded,
                    title: 'الملاعب والكرات',
                    subtitle: 'إدارة المنشآت والأدوات',
                    onTap: () =>
                        _navigateTo(context, const ManagePitchesBallsScreen()),
                  ),
                if (canViewReports)
                  _DashboardCard(
                    icon: Icons.analytics_rounded,
                    title: 'التقارير',
                    subtitle: 'إحصائيات العمل والمالية',
                    onTap: () => _openReports(context),
                  ),
                if (canManageBookings)
                  _DashboardCard(
                    icon: Icons.assignment_rounded,
                    title: 'قائمة الحجوزات',
                    subtitle: 'متابعة كافة الحجوزات',
                    onTap: () => Navigator.of(context).pushNamed('/bookings'),
                  ),
                if (isAdmin)
                  _DashboardCard(
                    icon: Icons.settings_suggest_rounded,
                    title: 'الإعدادات',
                    subtitle: 'ضبط أسعار النظام',
                    onTap: () => _navigateTo(context, const SettingsScreen()),
                  ),
                if (canManageBookings)
                  _DashboardCard(
                    icon: Icons.add_circle_rounded,
                    title: 'حجز جديد',
                    subtitle: 'إضافة حجز فوري',
                    onTap: () => _navigateTo(context, const AddBookingScreen()),
                  ),
                if (isAdmin || isStaff)
                  _DashboardCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'طلبات التوريد',
                    subtitle: 'إدارة تسليم المبالغ',
                    onTap: () {
                      final screen = isAdmin
                          ? const AdminDepositRequestsScreen()
                          : const WorkerDepositsScreen();
                      _navigateTo(context, screen);
                    },
                  ),

                // --- زر المزامنة الجديد ---
                if (isAdmin || isStaff)
                  _DashboardCard(
                    icon: Icons.cloud_upload_rounded,
                    title: 'مزامنة البيانات',
                    subtitle: 'رفع التغييرات للسحابة',
                    onTap: () {
                      // استدعاء المساعد الذي أنشأناه (إعادة استخدام الكود)
                      SyncUiHelper.triggerSync(context);
                    },
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: canManageBookings
            ? FloatingActionButton.extended(
                onPressed: () => _navigateTo(context, const AddBookingScreen()),
                label: Text('حجز جديد', style: TextStyle(fontSize: 14.sp)),
                icon: Icon(Icons.add_rounded, size: 22.sp),
              )
            : null,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16.sp),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.sp),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة مميزة مع خلفية خفيفة
              Container(
                padding: EdgeInsets.all(10.sp),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28.sp, color: colorScheme.primary),
              ),
              SizedBox(height: 1.5.h),
              Text(
                title,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 9.sp, color: theme.hintColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
