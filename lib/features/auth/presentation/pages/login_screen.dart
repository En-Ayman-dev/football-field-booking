// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // لاستخدام ImageFilter

import '../../../../providers/auth_provider.dart';
// import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // إعدادات الأنيميشن للدخول السلس
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // // 🛠️ أداة التشخيص (بدون تغيير في المنطق)
  // Future<void> _showDiagnostics(BuildContext context) async {
  //   try {
  //     final dbHelper = DatabaseHelper();
  //     final users = await dbHelper.getAll(DatabaseHelper.tableUsers);
  //     if (!mounted) return;

  //     showDialog(
  //       context: context,
  //       builder: (ctx) => AlertDialog(
  //         title: Text('تشخيص النظام', style: TextStyle(fontSize: 18.sp)),
  //         content: SizedBox(
  //           width: 90.w,
  //           height: 50.h,
  //           child: users.isEmpty
  //               ? const Center(child: Text('قاعدة البيانات فارغة!'))
  //               : ListView.separated(
  //                   itemCount: users.length,
  //                   separatorBuilder: (_, __) => const Divider(),
  //                   itemBuilder: (ctx, i) {
  //                     final u = users[i];
  //                     return ListTile(
  //                       dense: true,
  //                       title: Text(
  //                         '${u['name']}',
  //                         style: const TextStyle(fontWeight: FontWeight.bold),
  //                       ),
  //                       subtitle: SelectableText(
  //                         'User: ${u['username']}\nRole: ${u['role']}',
  //                         style: TextStyle(
  //                           fontFamily: 'monospace',
  //                           fontSize: 12.sp,
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(ctx).pop(),
  //             child: const Text('إغلاق'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
  //   }
  // }

  Future<void> _login(BuildContext ctx, {String? expectedRole}) async {
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال البيانات.')));
      return;
    }

    final success = await auth.login(username, password);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'فشل الدخول')),
      );
      return;
    }

    Navigator.of(ctx).pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        // AppBar شفاف للوصول لأداة التشخيص
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // IconButton(
            //   icon: Icon(
            //     Icons.bug_report,
            //     color: Colors.grey.shade400,
            //     size: 20.sp,
            //   ),
            //   onPressed: () => _showDiagnostics(context),
            // ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          // خلفية بتدرج لوني هادئ (مستوحى من العشب والسماء)
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFE8F5E9), // أخضر فاتح جداً
                Color(0xFFFFFFFF), // أبيض
                Color(0xFFE0F7FA), // سماوي فاتح جداً
              ],
            ),
          ),
          child: Stack(
            children: [

              // دوائر خلفية جمالية
              Positioned(
                top: -50,
                left: -50,
                child: _buildBlurCircle(
                  150,
                  const Color(0xFF4CAF50).withOpacity(0.2),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -50,
                child: _buildBlurCircle(
                  200,
                  const Color(0xFF2196F3).withOpacity(0.15),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. الشعار (Hero Image)
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              height: 180, // حجم كبير وواضح
                              width: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
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
                          ),
                          SizedBox(height: 3.h),

                          // 2. بطاقة تسجيل الدخول (Glassmorphism)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: size.width > 600 ? 500 : double.infinity,
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'مرحباً بعودتك',
                                      style: TextStyle(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'سجل الدخول لإدارة ملاعبك بسهولة',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),

                                    // حقول الإدخال
                                    _buildModernTextField(
                                      controller: _usernameController,
                                      label: 'اسم المستخدم',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    SizedBox(height: 2.h),
                                    _buildModernTextField(
                                      controller: _passwordController,
                                      label: 'كلمة المرور',
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                    ),

                                    SizedBox(height: 4.h),

                                    // زر الدخول الرئيسي
                                    _buildGradientButton(
                                      text: 'تسجيل الدخول',
                                      isLoading: auth.isLoading,
                                      onPressed: () => _login(
                                        context,
                                        expectedRole: 'admin',
                                      ),
                                    ),

                                    SizedBox(height: 2.h),

                                    // زر ثانوي (Text Button)
                                    TextButton(
                                      onPressed:
                                          () {}, // يمكن إضافة وظيفة نسيت كلمة المرور لاحقاً
                                      child: Text(
                                        'نسيت كلمة المرور؟',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // --- بداية إضافة توقيع المطور ---
                          SizedBox(height: 4.h),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.6,
                              ), // خلفية شبه شفافة
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'برمجة وتطوير',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                // اسم بتأثير لوني متدرج (Gradient Text)
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFF1B5E20), // أخضر غامق
                                          Color(0xFF2E7D32), // أخضر متوسط
                                          Color(0xFFFFA000), // لمسة ذهبية
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Text(
                                    'م. أيمن الذاهبي',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Cairo',
                                      color: Colors
                                          .white, // ضروري لعمل القناع اللوني
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 0.8.h),
                                // رقم التواصل بتصميم كبسولة
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 0.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_iphone_rounded,
                                        size: 14.sp,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                      SizedBox(width: 1.5.w),
                                      Text(
                                        '774998429',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1B5E20),
                                          letterSpacing: 1.5, // تباعد للأرقام
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // --- نهاية إضافة توقيع المطور ---
                          SizedBox(height: 2.h), // مسافة قبل الحقوق
                          SizedBox(height: 3.h),
                          // تذييل الصفحة
                          Text(
                            '© 2026 Arena Manager System',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- مكونات التصميم المساعدة ---

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 18.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 6.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // تدرج أخضر احترافي
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
