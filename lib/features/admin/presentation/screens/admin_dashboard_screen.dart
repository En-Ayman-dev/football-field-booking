// ignore_for_file: deprecated_member_use, depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide SizedBox;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../../pitches_balls/presentation/screens/manage_coaches_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_pitches_balls_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_staff_screen.dart';
import '../../../bookings/presentation/screens/add_booking_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../deposits/presentation/screens/admin_deposit_requests_screen.dart';
import '../../../deposits/presentation/screens/worker_deposits_screen.dart';


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _openManagePitchesBalls(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ManagePitchesBallsScreen(),
      ),
    );
  }

  void _openManageCoaches(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ManageCoachesScreen(),
      ),
    );
  }

  void _openManageStaff(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ManageStaffScreen(),
      ),
    );
  }

  void _openReports(BuildContext context) {
    // سيتم تنفيذ شاشة التقارير لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('شاشة التقارير سيتم تنفيذها لاحقاً.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;
    final isStaff = auth.isStaff;
    final canManagePitches = isAdmin || (user?.canManagePitches ?? false);
    final canManageCoaches = isAdmin || (user?.canManageCoaches ?? false);
    final canManageStaff = isAdmin; // restrict staff management to admin only
    final canViewReports = isAdmin || (user?.canViewReports ?? false);
    final canManageBookings = isAdmin || (user?.canManageBookings ?? false);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم المدير'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Debug DB',
              onPressed: () async {
                try {
                  final dbHelper = DatabaseHelper();
                  final usersCount = (await dbHelper.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableUsers}'));
                  final pitchesCount = (await dbHelper.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tablePitches}'));
                  final bookingsCount = (await dbHelper.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableBookings}'));
                  final u = usersCount.first['c'];
                  final p = pitchesCount.first['c'];
                  final b = bookingsCount.first['c'];
                  final msg = 'users: $u, pitches: $p, bookings: $b';
                  if (kDebugMode) print(msg);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                } catch (e) {
                  if (kDebugMode) print('DB debug failed: $e');
                }
              },
              icon: const Icon(Icons.bug_report),
            ),
            IconButton(
              tooltip: 'تسجيل خروج',
              onPressed: () async {
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
                if (confirm ?? false) {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                }
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          children: [
              if (canManageStaff) _DashboardCard(
                icon: Icons.people_alt_outlined,
                title: 'العمال / الموظفون',
                subtitle: 'إدارة حسابات العاملين',
                onTap: () => _openManageStaff(context),
              ),
              if (canManageCoaches) _DashboardCard(
                icon: Icons.sports_soccer_outlined,
                title: 'المدربون',
                subtitle: 'إدارة بيانات المدربين',
                onTap: () => _openManageCoaches(context),
              ),
              if (canManagePitches) _DashboardCard(
                icon: Icons.stadium_outlined,
                title: 'الملاعب والكرات',
                subtitle: 'إدارة الملاعب والكرات',
                onTap: () => _openManagePitchesBalls(context),
              ),
              if (canViewReports) _DashboardCard(
                icon: Icons.insert_chart_outlined,
                title: 'التقارير',
                subtitle: 'عرض تقارير الحجوزات',
                onTap: () => _openReports(context),
              ),
              if (canManageBookings) _DashboardCard(
                icon: Icons.list_alt,
                title: 'قائمة الحجوزات',
                subtitle: 'عرض كافة الحجوزات',
                onTap: () => Navigator.of(context).pushNamed('/bookings'),
              ),
              if (isAdmin) _DashboardCard(
                icon: Icons.settings,
                title: 'الإعدادات',
                subtitle: 'إعدادات التطبيق',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              if (canManageBookings) _DashboardCard(
                icon: Icons.add_box_outlined,
                title: 'إنشاء حجز',
                subtitle: 'إضافة حجز جديد',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddBookingScreen()),
                ),
              ),
              // طلبات التوريد - متاحة للمدير والموظفين
              if (isAdmin || isStaff) _DashboardCard(
                icon: Icons.monetization_on_outlined,
                title: 'طلبات التوريد',
                subtitle: 'عرض وإدارة طلبات التوريد',
                onTap: () {
                  if (isAdmin) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDepositRequestsScreen()));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkerDepositsScreen()));
                  }
                },
              ),
            ],
          ),
        ),
        floatingActionButton: canManageBookings
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddBookingScreen()),
                ),
                label: const Text('حجز جديد'),
                icon: const Icon(Icons.add_box_outlined),
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
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
