import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/utils/pdf_generator_helper.dart';
import '../../../../data/models/booking.dart';

class BookingPrintPreviewScreen extends StatelessWidget {
  final Booking booking;
  final PrintSize initialSize;
  final String? pitchName;
  final String? coachName;

  const BookingPrintPreviewScreen({
    super.key,
    required this.booking,
    required this.initialSize,
    this.pitchName,
    this.coachName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الإيصال وفحص الطابعة'),
      ),
      // الـ PdfPreview هو الودجت السحري الذي يوفر المعاينة والبحث عن الطابعات
      body: PdfPreview(
        // تخصيص الأزرار الظاهرة
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false, // نتحكم بالخط عبر الـ Helper الخاص بنا
        canDebug: false,
        
        // استدعاء المولد الذي أنشأناه سابقاً
        build: (format) => PdfGeneratorHelper.generateBookingPdf(
          booking: booking,
          size: initialSize,
          pitchName: pitchName,
          coachName: coachName,
        ),
        
        // رسائل تخصيص باللغة العربية
        pdfFileName: 'Booking_${booking.id}.pdf',
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onPrinted: (context) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت عملية الطباعة بنجاح')),
          );
        },
      ),
    );
  }
}