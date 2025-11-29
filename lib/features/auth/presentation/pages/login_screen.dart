// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';

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

  Future<void> _login(BuildContext ctx, {String? expectedRole}) async {
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور.')),
      );
      return;
    }

    final success = await auth.login(username, password);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'فشل تسجيل الدخول. يرجى التحقق من اسم المستخدم وكلمة المرور.')),
      );
      return;
    }

    final role = auth.currentUser?.role.toLowerCase();
    if (expectedRole != null && role != expectedRole) {
      await auth.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            expectedRole == 'admin'
                ? 'هذا الحساب غير مصرح لتسجيل دخول الأدمن.'
                : 'هذا الحساب غير مصرح لتسجيل دخول العمال.',
          ),
        ),
      );
      return;
    }

    if (role == 'admin') {
      Navigator.of(ctx).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } else {
      // Redirect staff to dashboard so they see pages according to their permissions
      Navigator.of(ctx).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    }
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
          title: Center(child: const Text('تسجيل الدخول',textAlign: TextAlign.center,)),
        ),
        body: Container(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = 600.0;
              final isWide = constraints.maxWidth >= 800;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: child,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(28, 26, 28, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      child: Icon(Icons.sports_soccer, size: 28, color: colorScheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('مرحبا بك!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('أدخل بياناتك للمتابعة إلى لوحة التحكم', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              if (isWide) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _usernameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
                                          prefixIcon: const Icon(Icons.person),
                                          labelText: 'اسم المستخدم',
                                          hintText: 'مثال: user123',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        textInputAction: TextInputAction.done,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
                                          prefixIcon: const Icon(Icons.lock),
                                          labelText: 'كلمة المرور',
                                          hintText: '••••••',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                                        ),
                                        obscureText: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                TextField(
                                  controller: _usernameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
                                    prefixIcon: const Icon(Icons.person),
                                    labelText: 'اسم المستخدم',
                                    hintText: 'مثال: user123',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
                                    prefixIcon: const Icon(Icons.lock),
                                    labelText: 'كلمة المرور',
                                    hintText: '••••••',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                                  ),
                                  obscureText: true,
                                ),
                              ],
                              const SizedBox(height: 22),
                              // Buttons: stacked on narrow screens to avoid overflow
                              Builder(builder: (context) {
                                final btnRowWidth = constraints.maxWidth;
                                final stackButtons = btnRowWidth < 420;

                                Widget adminButton = DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primaryContainer]),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 6))],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: auth.isLoading ? null : () => _login(context, expectedRole: 'admin'),
                                    child: auth.isLoading
                                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.onPrimary),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'تسجيل دخول الأدمن',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );

                                Widget staffButton = OutlinedButton(
                                  onPressed: auth.isLoading ? null : () => _login(context, expectedRole: 'staff'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.person_search),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'تسجيل دخول العمال',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                );

                                if (stackButtons) {
                                  return Column(
                                    children: [
                                      SizedBox(width: double.infinity, child: adminButton),
                                      const SizedBox(height: 10),
                                      SizedBox(width: double.infinity, child: staffButton),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: adminButton),
                                    const SizedBox(width: 12),
                                    Expanded(child: staffButton),
                                  ],
                                );
                              }),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text('هل نسيت كلمة المرور؟', style: TextStyle(color: colorScheme.primary)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.info_outline, size: 18, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'جديد؟ سجل من خلال حساب مدير',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            style: const TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: 0.4,
                                              height: 1.3,
                                              color: Color.fromRGBO(29, 27, 32, 1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AnimatedOpacity(
                                opacity: auth.errorMessage != null ? 1 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: auth.errorMessage != null
                                    ? Text(auth.errorMessage!, style: TextStyle(color: colorScheme.error))
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
