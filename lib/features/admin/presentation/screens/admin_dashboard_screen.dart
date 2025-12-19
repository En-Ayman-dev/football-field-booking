// ignore_for_file: deprecated_member_use, depend_on_referenced_packages
import 'package:flutter/material.dart' hide SizedBox;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب
import '../../../pitches_balls/presentation/screens/manage_coaches_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_pitches_balls_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_staff_screen.dart';
import '../../../bookings/presentation/screens/add_booking_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../deposits/presentation/screens/admin_deposit_requests_screen.dart';
import '../../../deposits/presentation/screens/worker_deposits_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // --- دوال التنقل (بدون تغيير) ---
  void _openManagePitchesBalls(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagePitchesBallsScreen()));
  }

  void _openManageCoaches(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageCoachesScreen()));
  }

  void _openManageStaff(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageStaffScreen()));
  }

  void _openReports(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شاشة التقارير ستتوفر قريباً.')));
  }

  Future<void> _performLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;
    final isStaff = auth.isStaff;
    
    // صلاحيات الوصول
    final canManagePitches = isAdmin || (user?.canManagePitches ?? false);
    final canManageCoaches = isAdmin || (user?.canManageCoaches ?? false);
    final canManageStaff = isAdmin;
    final canViewReports = isAdmin || (user?.canViewReports ?? false);
    final canManageBookings = isAdmin || (user?.canManageBookings ?? false);

    // --- حساب عدد الأعمدة بناءً على عرض الشاشة ---
    int crossAxisCount = 2; // الهواتف العادية
    if (ResponsiveHelper.screenWidth > 600) crossAxisCount = 3; // الأجهزة اللوحية الصغيرة
    if (ResponsiveHelper.screenWidth > 900) crossAxisCount = 4; // الأجهزة اللوحية الكبيرة / سطح المكتب

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('لوحة التحكم', style: TextStyle(fontSize: 18.sp)),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تسجيل خروج',
              onPressed: () => _performLogout(context),
              icon: Icon(Icons.logout, size: 22.sp),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w), // بادينج متجاوب
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4.w,
                mainAxisSpacing: 4.w,
                childAspectRatio: 0.85, // جعل الكروت متناسقة الطول والعرض
              ),
              children: [
                if (canManageStaff)
                  _DashboardCard(
                    icon: Icons.people_alt_outlined,
                    title: 'الموظفون',
                    subtitle: 'إدارة العاملين',
                    onTap: () => _openManageStaff(context),
                  ),
                if (canManageCoaches)
                  _DashboardCard(
                    icon: Icons.sports_soccer_outlined,
                    title: 'المدربون',
                    subtitle: 'إدارة المدربين',
                    onTap: () => _openManageCoaches(context),
                  ),
                if (canManagePitches)
                  _DashboardCard(
                    icon: Icons.stadium_outlined,
                    title: 'الملاعب والكرات',
                    subtitle: 'إدارة المنشآت',
                    onTap: () => _openManagePitchesBalls(context),
                  ),
                if (canViewReports)
                  _DashboardCard(
                    icon: Icons.insert_chart_outlined,
                    title: 'التقارير',
                    subtitle: 'إحصائيات العمل',
                    onTap: () => _openReports(context),
                  ),
                if (canManageBookings)
                  _DashboardCard(
                    icon: Icons.list_alt,
                    title: 'قائمة الحجوزات',
                    subtitle: 'كل الحجوزات',
                    onTap: () => Navigator.of(context).pushNamed('/bookings'),
                  ),
                if (isAdmin)
                  _DashboardCard(
                    icon: Icons.settings,
                    title: 'الإعدادات',
                    subtitle: 'ضبط النظام',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                if (canManageBookings)
                  _DashboardCard(
                    icon: Icons.add_box_outlined,
                    title: 'حجز جديد',
                    subtitle: 'إضافة فورية',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBookingScreen())),
                  ),
                if (isAdmin || isStaff)
                  _DashboardCard(
                    icon: Icons.monetization_on_outlined,
                    title: 'طلبات التوريد',
                    subtitle: 'إدارة المالية',
                    onTap: () {
                      final screen = isAdmin ? const AdminDepositRequestsScreen() : const WorkerDepositsScreen();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
                    },
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: canManageBookings
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBookingScreen())),
                label: Text('حجز جديد', style: TextStyle(fontSize: 14.sp)),
                icon: Icon(Icons.add_box_outlined, size: 20.sp),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.sp),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.sp),
          boxShadow: [
            BoxShadow(
              blurRadius: 10.sp,
              spreadRadius: 1.sp,
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, 4.sp),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 35.sp, color: theme.colorScheme.primary),
              SizedBox(height: 1.5.h),
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10.sp, color: theme.textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}