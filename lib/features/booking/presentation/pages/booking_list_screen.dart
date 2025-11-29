import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../bookings/presentation/screens/booking_list_screen.dart';
import '../../../../providers/auth_provider.dart';

class BookingListScreenWarp extends StatelessWidget {
  const BookingListScreenWarp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canViewBookings = auth.isAdmin || (auth.currentUser?.canManageBookings ?? false);
    if (canViewBookings) {
      return const BookingListScreen();
    }

    // Not authorized: show a simple forbidden page with option to go back to dashboard
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قائمة الحجوزات')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 54),
                const SizedBox(height: 12),
                const Text('غير مصرح لعرض قائمة الحجوزات.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false),
                  child: const Text('العودة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
