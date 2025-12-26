// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'dart:ui' as ui;

import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/report_pdf_helper.dart';
import '../../../../core/utils/thermal_printer_helper.dart';
import '../../../pitches_balls/presentation/providers/pitch_ball_provider.dart';
import '../providers/reports_provider.dart';
import '../../data/models/daily_report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchData() {
    final reportsProv = context.read<ReportsProvider>();
    reportsProv.generateReports(_startDate, _endDate); // التقرير العام
    reportsProv.generateDetailedReports(
      _startDate,
      _endDate,
    ); // التقرير التفصيلي
    context.read<PitchBallProvider>().loadAll();
  }

  // --- الطباعة والمشاركة الذكية ---
  Future<void> _handleReportAction(
    BuildContext context, {
    required bool isShare,
  }) async {
    final reportsProv = context.read<ReportsProvider>();
    final pitchProv = context.read<PitchBallProvider>();

    // التحقق من وجود بيانات بناءً على التبويب النشط
    bool hasData = _tabController.index == 0
        ? reportsProv.reports.isNotEmpty
        : (reportsProv.employeeReports.isNotEmpty ||
              reportsProv.coachReports.isNotEmpty);

    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للعملية المطلوبة')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (_tabController.index == 0) {
        // --- التقرير العام ---
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
      } else {
        // --- التقرير التفصيلي (الجديد) ---
        if (isShare) {
          await ReportPdfHelper.shareDetailedReport(
            employees: reportsProv.employeeReports,
            coaches: reportsProv.coachReports,
            startDate: _startDate,
            endDate: _endDate,
          );
        } else {
          await ReportPdfHelper.generateAndPrintDetailedReport(
            employees: reportsProv.employeeReports,
            coaches: reportsProv.coachReports,
            startDate: _startDate,
            endDate: _endDate,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _showPrinterPicker() async {
    // الطباعة الحرارية تدعم حالياً التقرير العام فقط (كنص)
    // يمكن تطويرها لاحقاً لطباعة التفصيلي
    if (_tabController.index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الطباعة الحرارية المباشرة غير مدعومة للتقرير التفصيلي حالياً. استخدم طباعة PDF.',
          ),
        ),
      );
      return;
    }

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
                  child: Text("لا توجد أجهزة بلوتوث مقترنة."),
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
            'التقارير والإحصائيات',
            style: TextStyle(fontSize: 18.sp),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'التقرير العام (اليومي)'),
              Tab(text: 'تفاصيل الموظفين والمدربين'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.bluetooth_connected,
                size: 20.sp,
                color: Colors.teal,
              ),
              onPressed: _showPrinterPicker,
              tooltip: 'طباعة حرارية (للتقرير العام فقط)',
            ),
            IconButton(
              icon: Icon(Icons.share_rounded, size: 20.sp, color: Colors.blue),
              onPressed: () => _handleReportAction(context, isShare: true),
              tooltip: 'مشاركة PDF',
            ),
            IconButton(
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                size: 20.sp,
                color: Colors.redAccent,
              ),
              onPressed: () => _handleReportAction(context, isShare: false),
              tooltip: 'طباعة PDF',
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            const Divider(height: 1),
            Expanded(
              child: Consumer<ReportsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading)
                    return const Center(child: CircularProgressIndicator());

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // التبويب الأول
                      provider.reports.isEmpty
                          ? Center(
                              child: Text(
                                'لا توجد بيانات.',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            )
                          : _buildGeneralReportTab(provider.reports),

                      // التبويب الثاني
                      _buildDetailedReportTab(provider),
                    ],
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

  Widget _buildGeneralReportTab(List<DailyReport> reports) {
    final pitchProv = context.read<PitchBallProvider>();
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
          columns: _buildColumns(pitchProv.pitches),
          rows: reports
              .map((report) => _buildRow(report, pitchProv.pitches))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDetailedReportTab(ReportsProvider provider) {
    if (provider.employeeReports.isEmpty && provider.coachReports.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات تفصيلية.',
          style: TextStyle(fontSize: 14.sp),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.employeeReports.isNotEmpty) ...[
            _buildSectionHeader('أداء الموظفين', Icons.badge),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.employeeReports.length,
              itemBuilder: (ctx, idx) {
                final emp = provider.employeeReports[idx];
                return Card(
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18.sp,
                              child: Text(emp.name[0]),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              emp.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'الأجر المستحق: ${emp.totalWages.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'المبيعات',
                              emp.totalSales.toStringAsFixed(2),
                            ),
                            _buildStatItem(
                              'حجوزات',
                              '${emp.paidBookingsCount}',
                            ),
                            _buildStatItem(
                              'غير مورد',
                              '${emp.pendingDepositionCount}',
                              isWarning: emp.pendingDepositionCount > 0,
                            ),
                          ],
                        ),
                        if (emp.cancelledBookings.isNotEmpty) ...[
                          SizedBox(height: 1.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'ملغيات (أرقام): ${emp.cancelledBookings.join(", ")}',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
          ],

          if (provider.coachReports.isNotEmpty) ...[
            _buildSectionHeader('أجور المدربين', Icons.sports),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.coachReports.length,
              itemBuilder: (ctx, idx) {
                final coach = provider.coachReports[idx];
                return Card(
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(
                      Icons.sports_soccer,
                      color: Colors.blue,
                    ),
                    title: Text(
                      coach.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    subtitle: Text(
                      'عدد الحصص التدريبية: ${coach.bookingsCount}',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    trailing: Text(
                      '${coach.totalWages.toStringAsFixed(2)} ريال',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20.sp),
          SizedBox(width: 2.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isWarning = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  List<DataColumn> _buildColumns(List pitches) {
    List<DataColumn> cols = [DataColumn(label: _colText('اليوم'))];
    for (var pitch in pitches) {
      cols.add(DataColumn(label: _colText(pitch.name)));
    }
    cols.addAll([
      DataColumn(label: _colText('ساعات')),
      DataColumn(label: _colText('إجمالي')),
      DataColumn(label: _colText('أجور\nع')),
      DataColumn(label: _colText('أجور\nم')),
      DataColumn(label: _colText('مورد')),
      DataColumn(label: _colText('صافي')),
      DataColumn(label: _colText('مسدد')),
      DataColumn(label: _colText('ملاحظات')),
    ]);
    return cols;
  }

  DataRow _buildRow(DailyReport report, List pitches) {
    List<DataCell> cells = [
      DataCell(
        Text(
          '${report.dayName}\n${DateFormat('M/d').format(report.date)}',
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
      DataCell(Text(report.totalAmount.toStringAsFixed(0))),
      DataCell(Text(report.totalStaffWages.toStringAsFixed(0))),
      DataCell(Text(report.totalCoachWages.toStringAsFixed(0))),
      DataCell(
        Text(
          report.depositedAmount.toStringAsFixed(0),
          style: const TextStyle(color: Colors.green),
        ),
      ),
      DataCell(
        Text(
          report.remainingAmount.toStringAsFixed(0),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataCell(Center(child: Text('${report.paidBookingsCount}'))),
      DataCell(
        SizedBox(
          width: 20.w,
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
      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
    );
  }
}
