import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _defaultHourPriceController =
      TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final db = await _dbHelper.database;

      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        );
      ''');

      final rows = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['default_hour_price'],
      );

      if (rows.isNotEmpty) {
        final value = rows.first['value']?.toString();
        if (value != null) {
          _defaultHourPriceController.text = value;
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final text = _defaultHourPriceController.text.trim();
    final value = double.tryParse(text.replaceAll(',', '.'));

    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رقم صحيح لسعر الساعة.'),
        ),
      );
      return;
    }

    try {
      final db = await _dbHelper.database;

      await db.insert(
        'settings',
        {
          'key': 'default_hour_price',
          'value': value.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الإعدادات بنجاح.'),
        ),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ الإعدادات.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _defaultHourPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'إعدادات الأسعار',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _defaultHourPriceController,
                        decoration: const InputDecoration(
                          labelText: 'سعر الساعة الافتراضي للملاعب',
                          suffixText: 'ريال',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'أدخل سعراً افتراضياً للساعة.';
                          }
                          final v = double.tryParse(
                              text.replaceAll(',', '.'));
                          if (v == null || v <= 0) {
                            return 'أدخل رقماً أكبر من صفر.';
                          }
                          return null;
                        },
                      ),
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
