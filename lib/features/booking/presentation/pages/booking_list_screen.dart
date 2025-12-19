import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب
import '../../../../providers/auth_provider.dart';
// ملاحظة: تأكد من أن مسار الاستيراد أدناه صحيح لملف القائمة الفعلي
import '../../../bookings/presentation/screens/booking_list_screen.dart';

class BookingListScreenWarp extends StatelessWidget {
  const BookingListScreenWarp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canViewBookings = auth.isAdmin || (auth.currentUser?.canManageBookings ?? false);
    
    if (canViewBookings) {
      return const BookingListScreen();
    }

    // واجهة "غير مصرح" متجاوبة بالكامل
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('قائمة الحجوزات', style: TextStyle(fontSize: 18.sp)),
        ),
        body: Container(
          width: 100.w,
          height: 100.h,
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block, 
                size: 40.sp, // أيقونة متجاوبة
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: 3.h),
              Text(
                'غير مصرح لعرض قائمة الحجوزات.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp, // نص متجاوب
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.5.h),
              Text(
                'يرجى التواصل مع الإدارة للحصول على الصلاحيات اللازمة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: 60.w,
                height: 6.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.sp),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false),
                  child: Text('العودة للرئيسية', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}