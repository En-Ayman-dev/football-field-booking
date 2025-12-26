// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/settings/settings_notifier.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب
import '../../../../features/bookings/presentation/providers/booking_provider.dart';
import '../../../../core/services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // تعريف كافة وحدات التحكم (Controllers)
  final Map<String, TextEditingController> _controllers = {
    'default_hour_price': TextEditingController(),
    'default_hour_price_morning_indoor': TextEditingController(),
    'default_hour_price_evening_indoor': TextEditingController(),
    'default_hour_price_morning_outdoor': TextEditingController(),
    'default_hour_price_evening_outdoor': TextEditingController(),
    'default_staff_wage': TextEditingController(),
    'admin_username': TextEditingController(),
    'admin_password': TextEditingController(),
  };

  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;

  // متغيرات المزامنة الجديدة
  bool _autoSync = false;
  String _syncFrequency = 'daily'; // daily, weekly

  String _themeMode = 'system';
  String _defaultBookingStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- تفعيل منطق التحميل لجميع الحقول ---
  Future<void> _loadSettings() async {
    try {
      final db = await _dbHelper.database;
      await db.execute(
        'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)',
      );

      final rows = await db.query('settings');
      final settingsMap = {
        for (var r in rows) r['key']?.toString(): r['value']?.toString(),
      };

      setState(() {
        _controllers['default_hour_price']!.text =
            settingsMap['default_hour_price'] ?? '';
        _controllers['default_hour_price_morning_indoor']!.text =
            settingsMap['default_hour_price_morning_indoor'] ?? '';
        _controllers['default_hour_price_evening_indoor']!.text =
            settingsMap['default_hour_price_evening_indoor'] ?? '';
        _controllers['default_hour_price_morning_outdoor']!.text =
            settingsMap['default_hour_price_morning_outdoor'] ?? '';
        _controllers['default_hour_price_evening_outdoor']!.text =
            settingsMap['default_hour_price_evening_outdoor'] ?? '';
        _controllers['default_staff_wage']!.text =
            settingsMap['default_staff_wage'] ?? '';

        // تحميل إعدادات المزامنة
        _autoSync = settingsMap['auto_sync'] == '1';
        _syncFrequency = settingsMap['sync_frequency'] ?? 'daily';

        _themeMode = settingsMap['theme_mode'] ?? 'system';
        _defaultBookingStatus =
            settingsMap['default_booking_status'] ?? 'pending';
      });

      // تحميل بيانات الأدمن
      final adminRows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'role = ?',
        whereArgs: ['admin'],
        limit: 1,
      );
      if (adminRows.isNotEmpty) {
        _controllers['admin_username']!.text =
            adminRows.first['username']?.toString() ?? '';
      }
    } catch (e) {
      if (kDebugMode) print('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- تفعيل منطق الحفظ الشامل لكافة الإعدادات ---
  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        // حفظ أسعار الملاعب
        final keysToSave = [
          'default_hour_price',
          'default_hour_price_morning_indoor',
          'default_hour_price_evening_indoor',
          'default_hour_price_morning_outdoor',
          'default_hour_price_evening_outdoor',
          'default_staff_wage',
        ];

        for (var key in keysToSave) {
          final value = _controllers[key]!.text.trim().replaceAll(',', '.');
          await txn.insert('settings', {
            'key': key,
            'value': value,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // حفظ إعدادات المزامنة
        await txn.insert('settings', {
          'key': 'auto_sync',
          'value': _autoSync ? '1' : '0',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('settings', {
          'key': 'sync_frequency',
          'value': _syncFrequency,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // حفظ الإعدادات العامة
        await txn.insert('settings', {
          'key': 'theme_mode',
          'value': _themeMode,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('settings', {
          'key': 'default_booking_status',
          'value': _defaultBookingStatus,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });

      if (!mounted) return;

      String message = 'تم حفظ كافة الإعدادات بنجاح.';
      if (_autoSync) {
        message += ' سيتم بدء تهيئة المزامنة السحابية.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      // تحديث الـ Provider ليعكس التغييرات فوراً
      context.read<BookingProvider>().reloadSettings();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ.')));
    }
  }

  Future<void> _changeAdminCredentials() async {
    final newUsername = _controllers['admin_username']!.text.trim();
    final newPassword = _controllers['admin_password']!.text.trim();
    if (newUsername.isEmpty && newPassword.isEmpty) return;

    try {
      final db = await _dbHelper.database;
      final updateValues = <String, dynamic>{};
      if (newUsername.isNotEmpty) updateValues['username'] = newUsername;
      if (newPassword.isNotEmpty) updateValues['password'] = newPassword;

      await db.update(
        DatabaseHelper.tableUsers,
        updateValues,
        where: 'role = ?',
        whereArgs: ['admin'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات الأدمن.')));
      _controllers['admin_password']!.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل تحديث البيانات.')));
    }
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد مسح البيانات'),
        content: const Text(
          'سيتم حذف كافة الحجوزات والملاعب نهائياً. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، امسح الكل'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _dbHelper.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/arena_manager.db');
    await DatabaseHelper().seedAdminUser();
    if (!mounted) return;
    _loadSettings();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إعادة تهيئة النظام.')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الإعدادات العامة', style: TextStyle(fontSize: 18.sp)),
          actions: [
            IconButton(
              icon: Icon(Icons.save, size: 22.sp),
              onPressed: _saveSettings,
              tooltip: 'حفظ الإعدادات',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    _buildSectionTitle('إعدادات أسعار الساعة'),
                    _buildPriceCard(),

                    SizedBox(height: 3.h),
                    _buildSectionTitle('المزامنة والنسخ الاحتياطي'),
                    _buildSyncCard(),

                    SizedBox(height: 3.h),
                    _buildSectionTitle('تفضيلات النظام'),
                    _buildGeneralSettingsCard(),

                    SizedBox(height: 3.h),
                    _buildSectionTitle('الأمن وقاعدة البيانات'),
                    _buildAdminCard(),

                    SizedBox(height: 4.h),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.sp),
                        ),
                      ),
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'حفظ كافة التغييرات',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                    SizedBox(height: 5.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h, right: 1.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            _buildPriceField('السعر الافتراضي العام', 'default_hour_price'),
            const Divider(),
            _buildPriceField(
              'صباحي - ملاعب داخلية',
              'default_hour_price_morning_indoor',
            ),
            _buildPriceField(
              'مسائي - ملاعب داخلية',
              'default_hour_price_evening_indoor',
            ),
            const Divider(),
            _buildPriceField(
              'صباحي - ملاعب خارجية',
              'default_hour_price_morning_outdoor',
            ),
            _buildPriceField(
              'مسائي - ملاعب خارجية',
              'default_hour_price_evening_outdoor',
            ),
            const Divider(),
            _buildPriceField('أجر الموظف لكل حجز', 'default_staff_wage'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(String label, String key) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: TextFormField(
        controller: _controllers[key],
        style: TextStyle(fontSize: 13.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 11.sp),
          suffixText: 'ريال',
          isDense: true,
          border: InputBorder.none,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  // --- كارد المزامنة الجديد (تم ربط الزر) ---
  Widget _buildSyncCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'تفعيل المزامنة السحابية (Firebase)',
              style: TextStyle(fontSize: 13.sp),
            ),
            subtitle: Text(
              'حفظ نسخة احتياطية من البيانات على السحابة',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
            value: _autoSync,
            activeColor: Colors.green,
            onChanged: (v) {
              setState(() => _autoSync = v);
              if (v) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تنبيه: سيتم إنشاء/ربط قاعدة البيانات عند الحفظ.',
                    ),
                  ),
                );
              }
            },
          ),
          if (_autoSync) ...[
            const Divider(height: 1),
            ListTile(
              title: Text(
                'تكرار المزامنة التلقائية',
                style: TextStyle(fontSize: 13.sp),
              ),
              trailing: DropdownButton<String>(
                value: _syncFrequency,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('يومياً')),
                  DropdownMenuItem(value: 'weekly', child: Text('أسبوعياً')),
                ],
                onChanged: (v) => setState(() => _syncFrequency = v ?? 'daily'),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(
                'مزامنة فورية الآن',
                style: TextStyle(fontSize: 13.sp),
              ),
              subtitle: Text(
                'رفع التغييرات الجديدة فقط',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.cloud_upload),
                color: Colors.blue,
                tooltip: 'اضغط للمزامنة الآن',
                onPressed: () async {
                  // إغلاق أي تنبيه سابق
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  // إظهار رسالة جاري التحميل
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري الاتصال بالسيرفر للمزامنة...'),
                    ),
                  );

                  try {
                    // استدعاء خدمة المزامنة الفعلية
                    await SyncService().syncNow();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ تمت المزامنة بنجاح!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ فشل المزامنة: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsCard() {
    final notifier = context.watch<SettingsNotifier>();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'وضع التطبيق (Theme)',
              style: TextStyle(fontSize: 13.sp),
            ),
            trailing: DropdownButton<String>(
              value: _themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('فاتح')),
                DropdownMenuItem(value: 'dark', child: Text('داكن')),
                DropdownMenuItem(value: 'system', child: Text('تلقائي')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _themeMode = v);
                ThemeMode mode = v == 'dark'
                    ? ThemeMode.dark
                    : (v == 'light' ? ThemeMode.light : ThemeMode.system);
                notifier.setThemeMode(mode);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(
              'حالة الحجز الافتراضية',
              style: TextStyle(fontSize: 13.sp),
            ),
            trailing: DropdownButton<String>(
              value: _defaultBookingStatus,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('معلق')),
                DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
              ],
              onChanged: (v) =>
                  setState(() => _defaultBookingStatus = v ?? 'pending'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            TextFormField(
              controller: _controllers['admin_username'],
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                labelText: 'اسم مستخدم الأدمن',
                labelStyle: TextStyle(fontSize: 11.sp),
              ),
            ),
            TextFormField(
              controller: _controllers['admin_password'],
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                labelText: 'كلمة مرور جديدة',
                labelStyle: TextStyle(fontSize: 11.sp),
              ),
              obscureText: true,
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _changeAdminCredentials,
                    child: Text(
                      'تحديث الأدمن',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _resetDatabase,
                    child: Text(
                      'تهيئة النظام',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
