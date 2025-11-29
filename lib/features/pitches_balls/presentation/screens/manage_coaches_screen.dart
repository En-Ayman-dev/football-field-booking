// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../data/models/coach.dart';
import '../providers/coaches_provider.dart';


class ManageCoachesScreen extends StatefulWidget {
  const ManageCoachesScreen({super.key});

  @override
  State<ManageCoachesScreen> createState() => _ManageCoachesScreenState();
}

class _ManageCoachesScreenState extends State<ManageCoachesScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showCoachForm(BuildContext context, {Coach? coach}) {
    final coachesProvider = Provider.of<CoachesProvider>(context, listen: false);
    final nameController = TextEditingController(text: coach?.name ?? '');
    final phoneController = TextEditingController(text: coach?.phone ?? '');
    final specializationController =
        TextEditingController(text: coach?.specialization ?? '');
    final priceController = TextEditingController(
      text: coach?.pricePerHour != null
          ? coach!.pricePerHour!.toString()
          : '',
    );
    bool isActive = coach?.isActive ?? true;

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
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        coach == null ? 'إضافة مدرب جديد' : 'تعديل المدرب',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المدرب',
                        ),
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
                        controller: specializationController,
                        decoration: const InputDecoration(
                          labelText: 'التخصص (مثال: لياقة، حراس...)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'أجر الساعة',
                        ),
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
                          onPressed: () async {
                            final provider = coachesProvider;

                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('الرجاء إدخال اسم المدرب.'),
                                ),
                              );
                              return;
                            }

                            final priceText =
                                priceController.text.trim().replaceAll(',', '.');
                            final price = double.tryParse(
                              priceText.isEmpty ? '0' : priceText,
                            );

                            final newCoach = Coach(
                              id: coach?.id,
                              name: name,
                              phone: phoneController.text.trim(),
                              specialization:
                                  specializationController.text.trim(),
                              pricePerHour: price,
                              isActive: isActive,
                              isDirty: true,
                              updatedAt: DateTime.now(),
                            );

                            await provider.addOrUpdateCoach(newCoach);
                            if (mounted) Navigator.of(ctx).pop();
                          },
                          child: Text(coach == null ? 'حفظ' : 'تحديث'),
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
    return ChangeNotifierProvider<CoachesProvider>(
      create: (_) => CoachesProvider()..loadCoaches(),
      child: Builder(
        builder: (providerContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('إدارة المدربين'),
              ),
              body: Consumer<CoachesProvider>(
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

                  if (provider.coaches.isEmpty) {
                    return const Center(
                      child: Text('لا يوجد مدربين مسجلين حالياً.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.coaches.length,
                    itemBuilder: (context, index) {
                      final coach = provider.coaches[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(coach.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (coach.phone != null &&
                                  coach.phone!.isNotEmpty)
                                Text('الجوال: ${coach.phone}'),
                              if (coach.specialization != null &&
                                  coach.specialization!.isNotEmpty)
                                Text('التخصص: ${coach.specialization}'),
                              if (coach.pricePerHour != null)
                                Text('أجر الساعة: ${coach.pricePerHour}'),
                              Text(
                                coach.isActive ? 'نشط' : 'غير نشط',
                                style: TextStyle(
                                  color: coach.isActive ? AppTheme.success : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showCoachForm(context, coach: coach);
                              } else if (value == 'toggle') {
                                await provider.toggleCoachActive(coach);
                              } else if (value == 'delete') {
                                await provider.deleteCoach(coach.id!);
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
                                  coach.isActive ? 'تعطيل' : 'تفعيل',
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
                  _showCoachForm(providerContext);
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
