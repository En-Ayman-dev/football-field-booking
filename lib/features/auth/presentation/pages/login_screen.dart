// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

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
        const SnackBar(content: Text('OU,O�O�OO� O�O_OrOU, OO3U. OU,U.O3O�OrO_U. U^U�U,U.Oc OU,U.O�U^O�.')),
      );
      return;
    }

    final success = await auth.login(username, password);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'O�O1O�O� O�O3O�USU, OU,O_OrU^U,.')),
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
      Navigator.of(ctx).pushNamedAndRemoveUntil('/bookings', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('O�O3O�USU, OU,O_OrU^U,')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'OO3U. OU,U.O3O�OrO_U.'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'U�U,U.Oc OU,U.O�U^O�'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : () => _login(context, expectedRole: 'admin'),
                  child: auth.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('تسجيل دخول الأدمن'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: auth.isLoading ? null : () => _login(context, expectedRole: 'staff'),
                  child: auth.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('تسجيل دخول العمال'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
