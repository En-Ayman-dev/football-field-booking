// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/user.dart';
import '../providers/staff_provider.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showStaffForm(BuildContext context, {User? user}) {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final nameController = TextEditingController(text: user?.name ?? '');
    final usernameController =
        TextEditingController(text: user?.username ?? '');
    final passwordController =
        TextEditingController(text: user?.password ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final wageController = TextEditingController(
      text: user?.wagePerBooking != null
          ? user!.wagePerBooking!.toString()
          : '',
    );

    bool isActive = user?.isActive ?? true;
    bool canManagePitches = user?.canManagePitches ?? false;
    bool canManageCoaches = user?.canManageCoaches ?? false;
    bool canManageBookings = user?.canManageBookings ?? true;
    bool canViewReports = user?.canViewReports ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 16,
              right: 16,
              left: 16,
            ),
            child: StatefulBuilder(
                builder: (context, setStateSheet) {
                final provider = staffProvider;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user == null ? 'إضافة موظف جديد' : 'تعديل الموظف',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // local saving state to prevent double submissions (isSaving in outer scope)
                      // error message
                      Builder(builder: (ctx) {
                        final error = staffProvider.errorMessage;
                        if (error == null || error.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الجوال (اختياري)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: wageController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'الأجر لكل حجز (اختياري)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الصلاحيات',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SwitchListTile(
                        value: canManagePitches,
                        onChanged: (val) {
                          setStateSheet(() {
                            canManagePitches = val;
                          });
                        },
                        title: const Text('إدارة الملاعب والكرات'),
                      ),
                      SwitchListTile(
                        value: canManageCoaches,
                        onChanged: (val) {
                          setStateSheet(() {
                            canManageCoaches = val;
                          });
                        },
                        title: const Text('إدارة المدربين'),
                      ),
                      SwitchListTile(
                        value: canManageBookings,
                        onChanged: (val) {
                          setStateSheet(() {
                            canManageBookings = val;
                          });
                        },
                        title: const Text('إدارة الحجوزات'),
                      ),
                      SwitchListTile(
                        value: canViewReports,
                        onChanged: (val) {
                          setStateSheet(() {
                            canViewReports = val;
                          });
                        },
                        title: const Text('عرض التقارير'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (val) {
                          setStateSheet(() {
                            isActive = val;
                          });
                        },
                        title: const Text('نشط'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isSaving
                              ? null
                              : () async {
                                  // provider will hold the saving state
                                  final provider = staffProvider;
                                  provider.clearError();

                                  final name = nameController.text.trim();
                                  final username =
                                      usernameController.text.trim();
                                  final password =
                                      passwordController.text.trim();

                                  if (name.isEmpty ||
                                      username.isEmpty ||
                                      password.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'الرجاء إدخال الاسم، اسم المستخدم، وكلمة المرور.'),
                                      ),
                                    );
                                    // provider will clear its saving state
                                    return;
                                  }

                                  final wageText = wageController.text
                                      .trim()
                                      .replaceAll(',', '.');
                                  final wage = wageText.isEmpty
                                      ? null
                                      : double.tryParse(wageText);

                                  final newUser = User(
                                    id: user?.id,
                                    name: name,
                                    username: username,
                                    password: password,
                                    phone: phoneController.text.trim(),
                                    email: user?.email, // غير مستخدم حالياً
                                    role: 'staff',
                                    isActive: isActive,
                                    wagePerBooking: wage,
                                    canManagePitches: canManagePitches,
                                    canManageCoaches: canManageCoaches,
                                    canManageBookings: canManageBookings,
                                    canViewReports: canViewReports,
                                    isDirty: true,
                                    updatedAt: DateTime.now(),
                                  );

                                  if (kDebugMode) {
                                    print(
                                        'Attempting to save staff: ${newUser.toMap()}');
                                  }
                                  final success =
                                      await provider.addOrUpdateStaff(newUser);
                                  // provider will clear its saving state
                                  if (success) {
                                    if (mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            provider.errorMessage ??
                                                'تعذر حفظ بيانات الموظف.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: provider.isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(user == null ? 'حفظ' : 'تحديث'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StaffProvider>(
      create: (_) => StaffProvider()..loadStaff(),
      child: Builder(
        builder: (providerContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('إدارة الموظفين'),
              ),
              body: Consumer<StaffProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Text(provider.errorMessage!),
                    );
                  }

                  if (provider.staff.isEmpty) {
                    return const Center(
                      child: Text('لا يوجد موظفين مسجلين حالياً.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.staff.length,
                    itemBuilder: (context, index) {
                      final user = provider.staff[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(user.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('اسم المستخدم: ${user.username}'),
                              if (user.phone != null &&
                                  user.phone!.isNotEmpty)
                                Text('الجوال: ${user.phone}'),
                              if (user.wagePerBooking != null)
                                Text('الأجر لكل حجز: ${user.wagePerBooking}'),
                              Text(
                                user.isActive ? 'نشط' : 'غير نشط',
                                style: TextStyle(
                                  color:
                                      user.isActive ? Colors.green : Colors.red,
                                ),
                              ),
                              Wrap(
                                spacing: 4,
                                children: [
                                  if (user.canManagePitches)
                                    const Chip(
                                      label: Text('ملاعب'),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (user.canManageCoaches)
                                    const Chip(
                                      label: Text('مدربون'),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (user.canManageBookings)
                                    const Chip(
                                      label: Text('حجوزات'),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (user.canViewReports)
                                    const Chip(
                                      label: Text('تقارير'),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showStaffForm(context, user: user);
                              } else if (value == 'toggle') {
                                provider.clearError();
                                final success =
                                    await provider.toggleStaffActive(user);
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        provider.errorMessage ??
                                            'تعذر تعديل حالة الموظف.',
                                      ),
                                    ),
                                  );
                                }
                              } else if (value == 'delete') {
                                provider.clearError();
                                await provider.deleteStaff(user.id!);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('تعديل'),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  user.isActive ? 'تعطيل' : 'تفعيل',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  _showStaffForm(providerContext);
                },
                child: const Icon(Icons.add),
              ),
            ),
          );
        },
      ),
    );
  }
}
