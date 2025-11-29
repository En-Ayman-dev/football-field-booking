// Settings screen with DB-backed simple settings and admin actions
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _defaultHourPriceController = TextEditingController();
  final TextEditingController _defaultStaffWageController = TextEditingController();
  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;
  bool _autoSync = false;
  String _themeMode = 'light'; // light | dark | system
  String _defaultBookingStatus = 'pending'; // pending | paid

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final db = await _dbHelper.database;
      await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');

      final rows = await db.query('settings');
      final map = {for (var r in rows) r['key']?.toString(): r['value']?.toString()};

      setState(() {
        if (map['default_hour_price'] != null) {
          _defaultHourPriceController.text = map['default_hour_price']!;
        }
        if (map['default_staff_wage'] != null) {
          _defaultStaffWageController.text = map['default_staff_wage']!;
        }
        if (map['auto_sync'] != null) {
          _autoSync = map['auto_sync'] == '1';
        }
        if (map['theme_mode'] != null) {
          _themeMode = map['theme_mode']!;
        }
        if (map['default_booking_status'] != null) {
          _defaultBookingStatus = map['default_booking_status']!;
        }
      });

      // load admin username (not password)
      final adminRows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'role = ?',
        whereArgs: ['admin'],
        limit: 1,
      );
      if (adminRows.isNotEmpty) {
        final username = adminRows.first['username']?.toString() ?? '';
        _adminUsernameController.text = username;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final text = _defaultHourPriceController.text.trim();
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال رقم صحيح لسعر الساعة.')));
      return;
    }

    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
        await txn.insert('settings', {'key': 'default_hour_price', 'value': value.toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
        if (_defaultStaffWageController.text.trim().isNotEmpty) {
          await txn.insert('settings', {'key': 'default_staff_wage', 'value': _defaultStaffWageController.text.trim().replaceAll(',', '.')}, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await txn.insert('settings', {'key': 'auto_sync', 'value': _autoSync ? '1' : '0'}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('settings', {'key': 'theme_mode', 'value': _themeMode}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('settings', {'key': 'default_booking_status', 'value': _defaultBookingStatus}, conflictAlgorithm: ConflictAlgorithm.replace);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات بنجاح.')));
    } catch (e) {
      if (kDebugMode) print('Error saving settings: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الإعدادات.')));
    }
  }

  Future<void> _changeAdminCredentials() async {
    final newUsername = _adminUsernameController.text.trim();
    final newPassword = _adminPasswordController.text.trim();
    if (newUsername.isEmpty && newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم مستخدم أو كلمة مرور جديدة.')));
      return;
    }
    try {
      final db = await _dbHelper.database;
      final adminRow = await db.query(DatabaseHelper.tableUsers, where: 'role = ?', whereArgs: ['admin'], limit: 1);
      if (adminRow.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على حساب إدمن.')));
        return;
      }
      final id = adminRow.first['id'];
      final updateValues = <String, dynamic>{};
      if (newUsername.isNotEmpty) updateValues['username'] = newUsername;
      if (newPassword.isNotEmpty) updateValues['password'] = newPassword;
      if (updateValues.isEmpty) return;
      await db.update(DatabaseHelper.tableUsers, updateValues, where: 'id = ?', whereArgs: [id]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات الأدمن.')));
    } catch (e) {
      if (kDebugMode) print('Error updating admin credentials: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث بيانات الأدمن.')));
    }
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف قاعدة البيانات'),
        content: const Text('سيتم حذف جميع البيانات. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم')),
        ],
      ),
    );
    if (!(confirm ?? false)) return;
    try {
      final path = await getDatabasesPath();
      final dbPath = '$path/arena_manager.db'; // use DB filename
      // Close and reset the DatabaseHelper singleton
      await _dbHelper.close();
      await deleteDatabase(dbPath);
      // Recreate DB and seed admin user
      await DatabaseHelper().seedAdminUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إعادة تهيئة قاعدة البيانات.')));
    } catch (e) {
      if (kDebugMode) print('Error resetting database: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إعادة تهيئة قاعدة البيانات.')));
    }
  }

  @override
  void dispose() {
    _defaultHourPriceController.dispose();
    _defaultStaffWageController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text('إعدادات الأسعار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _defaultHourPriceController,
                        decoration: const InputDecoration(
                          labelText: 'سعر الساعة الافتراضي للملاعب',
                          suffixText: 'ريال',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'أدخل سعراً افتراضياً للساعة.';
                          final v = double.tryParse(text.replaceAll(',', '.'));
                          if (v == null || v <= 0) return 'أدخل رقماً أكبر من صفر.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('الإعدادات العامة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _defaultStaffWageController,
                        decoration: const InputDecoration(
                          labelText: 'الأجر الافتراضي للموظف لكل حجز',
                          suffixText: 'ريال',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('المزامنة التلقائية'),
                        value: _autoSync,
                        onChanged: (v) => setState(() => _autoSync = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('الوضع: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _themeMode,
                            items: const [
                              DropdownMenuItem(value: 'light', child: Text('فاتح')),
                              DropdownMenuItem(value: 'dark', child: Text('داكن')),
                              DropdownMenuItem(value: 'system', child: Text('نظام')),
                            ],
                            onChanged: (v) => setState(() => _themeMode = v ?? 'light'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('اعدادات الحجوزات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('الحالة الافتراضية للحجز: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _defaultBookingStatus,
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('معلق')),
                              DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
                            ],
                            onChanged: (v) => setState(() => _defaultBookingStatus = v ?? 'pending'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Builder(builder: (ctx) {
                        final auth = Provider.of<AuthProvider>(ctx);
                        final isAdmin = auth.currentUser?.isAdmin ?? false;
                        if (!isAdmin) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('حسابات الأدمن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _adminUsernameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم مستخدم الأدمن',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _adminPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'كلمة مرور الأدمن (اتركها فارغة إن لا تريد التغيير)',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _changeAdminCredentials,
                                    child: const Text('تحديث بيانات الأدمن'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: _resetDatabase,
                                    child: const Text('إعادة تهيئة قاعدة البيانات'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          child: const Text('حفظ الإعدادات'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
