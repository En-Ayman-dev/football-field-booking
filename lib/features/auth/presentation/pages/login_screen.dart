// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🛠️ أداة التشخيص (بدون تغيير في المنطق)
  Future<void> _showDiagnostics(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      final users = await dbHelper.getAll(DatabaseHelper.tableUsers);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تشخيص النظام', style: TextStyle(fontSize: 18.sp)),
          content: SizedBox(
            width: 90.w,
            height: 50.h,
            child: users.isEmpty
                ? const Center(child: Text('قاعدة البيانات فارغة!'))
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final u = users[i];
                      return ListTile(
                        dense: true,
                        title: Text('${u['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: SelectableText(
                          'User: ${u['username']}\nRole: ${u['role']}',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12.sp),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _login(BuildContext ctx, {String? expectedRole}) async {
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى إدخال البيانات.')));
      return;
    }

    final success = await auth.login(username, password);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'فشل الدخول')));
      return;
    }

    Navigator.of(ctx).pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: colorScheme.onSurface,
          actions: [
            IconButton(
              icon: Icon(Icons.bug_report, color: Colors.red, size: 24.sp),
              onPressed: () => _showDiagnostics(context),
            ),
          ],
          title: Text('تسجيل الدخول', style: TextStyle(fontSize: 20.sp)),
          centerTitle: true,
        ),
        body: Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface.withOpacity(0.98),
                colorScheme.surfaceVariant.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              // استخدام هوامش متجاوبة
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500), // حد أقصى للشاشات العريضة جداً
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20.sp),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18.sp,
                        offset: Offset(0, 8.sp),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(7.w), // بادينج داخلي نسبي
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme, colorScheme),
                        SizedBox(height: 3.h),
                        _buildTextFields(colorScheme),
                        SizedBox(height: 4.h),
                        _buildButtons(context, auth, colorScheme),
                        SizedBox(height: 2.h),
                        _buildFooter(colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.sp),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)]),
          ),
          child: CircleAvatar(
            radius: 8.w > 35 ? 35 : 8.w, // حجم دائرة متجاوب بحد أقصى
            backgroundColor: colorScheme.surface,
            child: Icon(Icons.sports_soccer, size: 30.sp, color: colorScheme.primary),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مرحبا بك!', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
              Text('أدخل بياناتك للمتابعة', style: TextStyle(fontSize: 12.sp, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields(ColorScheme colorScheme) {
    return Column(
      children: [
        TextField(
          controller: _usernameController,
          style: TextStyle(fontSize: 14.sp),
          decoration: _inputDecoration(colorScheme, 'اسم المستخدم', Icons.person),
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: TextStyle(fontSize: 14.sp),
          decoration: _inputDecoration(colorScheme, 'كلمة المرور', Icons.lock),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(ColorScheme colorScheme, String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
      prefixIcon: Icon(icon, size: 20.sp),
      labelText: label,
      labelStyle: TextStyle(fontSize: 13.sp),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.sp), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.sp), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  Widget _buildButtons(BuildContext context, AuthProvider auth, ColorScheme colorScheme) {
    return Column(
      children: [
        _mainButton(
          onPressed: () => _login(context, expectedRole: 'admin'),
          label: 'دخول الأدمن',
          icon: Icons.admin_panel_settings,
          color: colorScheme.primary,
          isLoading: auth.isLoading,
        ),
        SizedBox(height: 1.5.h),
        _mainButton(
          onPressed: () => _login(context, expectedRole: 'staff'),
          label: 'دخول العمال',
          icon: Icons.person_search,
          color: Colors.transparent,
          isOutlined: true,
          isLoading: auth.isLoading,
        ),
      ],
    );
  }

  Widget _mainButton({required VoidCallback onPressed, required String label, required IconData icon, required Color color, bool isOutlined = false, required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 6.h, // ارتفاع متجاوب للزر
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon, size: 20.sp),
              label: Text(label, style: TextStyle(fontSize: 14.sp)),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp))),
            )
          : ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon, size: 20.sp, color: Colors.white),
              label: Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
              ),
            ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Column(
      children: [
        TextButton(
          onPressed: () {},
          child: Text('هل نسيت كلمة المرور؟', style: TextStyle(fontSize: 12.sp)),
        ),
        Text(
          'جديد؟ سجل من خلال حساب مدير',
          style: TextStyle(fontSize: 11.sp, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}