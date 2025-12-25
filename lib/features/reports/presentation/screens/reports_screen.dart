import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; // مكتبة البلوتوث
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/report_pdf_helper.dart';
import '../../../../core/utils/thermal_printer_helper.dart'; // محرك الطباعة الحرارية
import '../../../pitches_balls/presentation/providers/pitch_ball_provider.dart';
import '../providers/reports_provider.dart';
import '../../data/models/daily_report_model.dart';
import 'dart:ui' as ui;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<ReportsProvider>().generateReports(_startDate, _endDate);
    context.read<PitchBallProvider>().loadAll();
  }

  // --- دالة اختيار الطابعة والاتصال بها ---
  Future<void> _showPrinterPicker() async {
    List<BluetoothDevice> devices =
        await ThermalPrinterHelper.getPairedDevices();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "اختر الطابعة الحرارية",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "لا توجد أجهزة بلوتوث مقترنة. يرجى الاقتران من إعدادات الهاتف أولاً.",
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(devices[index].name ?? "جهاز مجهول"),
                      subtitle: Text(devices[index].address ?? ""),
                      onTap: () async {
                        Navigator.pop(context);
                        _connectAndPrint(devices[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectAndPrint(BluetoothDevice device) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("جاري الاتصال بالطابعة...")));

    bool connected = await ThermalPrinterHelper.connect(device);

    if (connected) {
      final reportsProv = context.read<ReportsProvider>();
      await ThermalPrinterHelper.printReport(
        reports: reportsProv.reports,
        startDate: _startDate,
        endDate: _endDate,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل الاتصال بالطابعة")));
    }
  }

  Future<void> _handleReportAction(
    BuildContext context, {
    required bool isShare,
  }) async {
    final reportsProv = context.read<ReportsProvider>();
    final pitchProv = context.read<PitchBallProvider>();

    if (reportsProv.reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات للعملية المطلوبة في الفترة المختارة'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isShare) {
        await ReportPdfHelper.shareReport(
          reports: reportsProv.reports,
          pitches: pitchProv.pitches,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        await ReportPdfHelper.generateAndPrintReport(
          reports: reportsProv.reports,
          pitches: pitchProv.pitches,
          startDate: _startDate,
          endDate: _endDate,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء معالجة الملف: $e')));
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ar'),
      builder: (context, child) =>
          Directionality(textDirection: ui.TextDirection.rtl, child: child!),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تقارير النظام التفصيلية',
            style: TextStyle(fontSize: 18.sp),
          ),
          actions: [
            // زر الطباعة الحرارية (جديد)
            IconButton(
              icon: Icon(
                Icons.bluetooth_connected,
                size: 20.sp,
                color: Colors.teal,
              ),
              tooltip: 'طباعة حرارية (Bluetooth)',
              onPressed: _showPrinterPicker,
            ),
            IconButton(
              icon: Icon(Icons.share_rounded, size: 20.sp, color: Colors.blue),
              tooltip: 'مشاركة التقرير',
              onPressed: () => _handleReportAction(context, isShare: true),
            ),
            IconButton(
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                size: 20.sp,
                color: Colors.redAccent,
              ),
              tooltip: 'عرض PDF للطباعة',
              onPressed: () => _handleReportAction(context, isShare: false),
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            const Divider(height: 1),
            Expanded(
              child: Consumer2<ReportsProvider, PitchBallProvider>(
                builder: (context, reportsProv, pitchProv, _) {
                  if (reportsProv.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (reportsProv.reports.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد بيانات للفترة المختارة',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    );
                  }

                  return _buildReportTable(
                    reportsProv.reports,
                    pitchProv.pitches,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final df = DateFormat('yyyy/MM/dd');
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الفترة المختارة:',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              Text(
                '${df.format(_startDate)} - ${df.format(_endDate)}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _selectDateRange,
            icon: Icon(Icons.date_range, size: 18.sp),
            label: Text('تغيير الفترة', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable(List<DailyReport> reports, List pitches) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          columnSpacing: 20.sp,
          horizontalMargin: 10.sp,
          columns: _buildColumns(pitches),
          rows: reports.map((report) => _buildRow(report, pitches)).toList(),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns(List pitches) {
    List<DataColumn> cols = [DataColumn(label: _colText('اليوم / التاريخ'))];
    for (var pitch in pitches) {
      cols.add(DataColumn(label: _colText(pitch.name)));
    }
    cols.addAll([
      DataColumn(label: _colText('مجموع\nالساعات')),
      DataColumn(label: _colText('المبلغ\nالإجمالي')),
      DataColumn(label: _colText('أجور\nعمال')),
      DataColumn(label: _colText('أجور\nمدربين')),
      DataColumn(label: _colText('المبلغ\nالمورد')),
      DataColumn(label: _colText('الصافي\nالمتبقي')),
      DataColumn(label: _colText('الحجوزات\nالمسددة')),
      DataColumn(label: _colText('ملاحظات')),
    ]);
    return cols;
  }

  DataRow _buildRow(DailyReport report, List pitches) {
    List<DataCell> cells = [
      DataCell(
        Text(
          '${report.dayName}\n${report.formattedDate}',
          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
        ),
      ),
    ];

    for (var pitch in pitches) {
      final hours = report.pitchHours[pitch.id] ?? 0.0;
      cells.add(
        DataCell(
          Text(
            DailyReport.formatDecimalHours(hours),
            style: TextStyle(fontSize: 11.sp),
          ),
        ),
      );
    }

    cells.addAll([
      DataCell(Text(DailyReport.formatDecimalHours(report.totalHours))),
      DataCell(Text(report.totalAmount.toStringAsFixed(2))),
      DataCell(Text(report.totalStaffWages.toStringAsFixed(2))),
      DataCell(Text(report.totalCoachWages.toStringAsFixed(2))),
      DataCell(
        Text(
          report.depositedAmount.toStringAsFixed(2),
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataCell(
        Text(
          report.remainingAmount.toStringAsFixed(2),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataCell(Center(child: Text('${report.paidBookingsCount}'))),
      DataCell(
        SizedBox(
          width: 25.w,
          child: Text(
            report.notes,
            style: TextStyle(fontSize: 9.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ]);

    return DataRow(cells: cells);
  }

  Widget _colText(String label) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
    );
  }
}
