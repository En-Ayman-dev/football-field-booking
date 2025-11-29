// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart' hide SizedBox;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../pitches_balls/presentation/screens/manage_coaches_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_pitches_balls_screen.dart';
import '../../../pitches_balls/presentation/screens/manage_staff_screen.dart';
import '../../../bookings/presentation/screens/add_booking_screen.dart';


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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم المدير'),
          centerTitle: true,
          actions: [
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
              _DashboardCard(
                icon: Icons.people_alt_outlined,
                title: 'العمال / الموظفون',
                subtitle: 'إدارة حسابات العاملين',
                onTap: () => _openManageStaff(context),
              ),
              _DashboardCard(
                icon: Icons.sports_soccer_outlined,
                title: 'المدربون',
                subtitle: 'إدارة بيانات المدربين',
                onTap: () => _openManageCoaches(context),
              ),
              _DashboardCard(
                icon: Icons.stadium_outlined,
                title: 'الملاعب والكرات',
                subtitle: 'إدارة الملاعب والكرات',
                onTap: () => _openManagePitchesBalls(context),
              ),
              _DashboardCard(
                icon: Icons.insert_chart_outlined,
                title: 'التقارير',
                subtitle: 'عرض تقارير الحجوزات',
                onTap: () => _openReports(context),
              ),
              _DashboardCard(
                icon: Icons.add_box_outlined,
                title: 'إنشاء حجز',
                subtitle: 'إضافة حجز جديد',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddBookingScreen()),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddBookingScreen()),
          ),
          label: const Text('حجز جديد'),
          icon: const Icon(Icons.add_box_outlined),
        ),
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
