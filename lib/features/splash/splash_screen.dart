// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. إعداد الأنيميشن
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // 2. المؤقت للانتقال للصفحة التالية
    Timer(const Duration(seconds: 3), _navigateToNextScreen);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() async {
    // التحقق من حالة المصادقة
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // إذا كان المستخدم مسجلاً للدخول بالفعل (يتم التحقق عادة في main.dart أو هنا)
    // سنفترض هنا التحقق البسيط، ويمكنك تعديل المسارات حسب أسماء الـ Routes لديك
    
    if (authProvider.isAuthenticated) {
        // توجيه حسب الصلاحية (مثال)
        // Navigator.pushReplacementNamed(context, '/home'); 
        // أو إذا كان لديك منطق توجيه داخل AuthWrapper يمكن التوجيه له
        Navigator.of(context).pushReplacementNamed('/home');
    } else {
        Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام MediaQuery للتجاوب السريع إذا لم يكن ResponsiveHelper مفعلاً بالكامل هنا
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء لتناسب الشعار
      body: Stack(
        children: [
          // المحتوى في المنتصف
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // عرض الشعار
                    Container(
                      width: size.width * 0.5, // عرض نصف الشاشة
                      height: size.width * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/1.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // نص ترحيبي (اختياري)
                    const Text(
                      "نظام إدارة الملاعب",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo', // التأكد من استخدام الخط المضاف
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // مؤشر تحميل صغير في الأسفل
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  color: Colors.green, // لون يتناسب مع الملاعب
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}