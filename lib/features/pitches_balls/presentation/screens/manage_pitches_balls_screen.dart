// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/ball.dart';
import '../../../../data/models/pitch.dart';
import '../providers/pitch_ball_provider.dart';
import '../../../../core/theme/app_theme.dart';


class ManagePitchesBallsScreen extends StatefulWidget {
  const ManagePitchesBallsScreen({super.key});

  @override
  State<ManagePitchesBallsScreen> createState() =>
      _ManagePitchesBallsScreenState();
}

class _ManagePitchesBallsScreenState extends State<ManagePitchesBallsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showPitchForm(BuildContext context, {Pitch? pitch}) {
    final pitchProvider = Provider.of<PitchBallProvider>(context, listen: false);
    final nameController = TextEditingController(text: pitch?.name ?? '');
    final locationController =
        TextEditingController(text: pitch?.location ?? '');
    final priceController = TextEditingController(
      text: pitch?.pricePerHour != null ? pitch!.pricePerHour!.toString() : '',
    );
    bool isIndoor = pitch?.isIndoor ?? false;
    bool isActive = pitch?.isActive ?? true;

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
                        pitch == null ? 'إضافة ملعب جديد' : 'تعديل الملعب',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الملعب',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'الموقع',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'السعر للساعة (اختياري)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isIndoor,
                        onChanged: (val) {
                          setStateSheet(() {
                            isIndoor = val;
                          });
                        },
                        title: const Text('ملعب داخلي'),
                      ),
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
                            final provider = pitchProvider;

                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('الرجاء إدخال اسم الملعب.'),
                                ),
                              );
                              return;
                            }

                            final priceText =
                                priceController.text.trim().replaceAll(',', '.');
                            final price = priceText.isEmpty
                                ? null
                                : double.tryParse(priceText);

                            final newPitch = Pitch(
                              id: pitch?.id,
                              name: name,
                              location: locationController.text.trim(),
                              pricePerHour: price,
                              isIndoor: isIndoor,
                              isActive: isActive,
                              isDirty: true,
                              updatedAt: DateTime.now(),
                            );

                            await provider.addOrUpdatePitch(newPitch);
                            if (mounted) Navigator.of(ctx).pop();
                          },
                          child: Text(pitch == null ? 'حفظ' : 'تحديث'),
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

  void _showBallForm(BuildContext context, {Ball? ball}) {
    final pitchProvider = Provider.of<PitchBallProvider>(context, listen: false);
    final nameController = TextEditingController(text: ball?.name ?? '');
    final sizeController = TextEditingController(text: ball?.size ?? '');
    final quantityController = TextEditingController(
      text: ball?.quantity.toString() ?? '0',
    );
    bool isAvailable = ball?.isAvailable ?? true;

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
                        ball == null ? 'إضافة كرة جديدة' : 'تعديل الكرة',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الكرة',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'المقاس (اختياري)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الكمية المتاحة',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isAvailable,
                        onChanged: (val) {
                          setStateSheet(() {
                            isAvailable = val;
                          });
                        },
                        title: const Text('متاحة'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                              final provider = pitchProvider;

                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('الرجاء إدخال اسم الكرة.'),
                                ),
                              );
                              return;
                            }

                            final qtyText = quantityController.text.trim();
                            final qty =
                                int.tryParse(qtyText.isEmpty ? '0' : qtyText) ??
                                    0;

                            final newBall = Ball(
                              id: ball?.id,
                              name: name,
                              size: sizeController.text.trim(),
                              quantity: qty,
                              isAvailable: isAvailable,
                              isDirty: true,
                              updatedAt: DateTime.now(),
                            );

                            await provider.addOrUpdateBall(newBall);
                            if (mounted) Navigator.of(ctx).pop();
                          },
                          child: Text(ball == null ? 'حفظ' : 'تحديث'),
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
    return ChangeNotifierProvider<PitchBallProvider>(
      create: (_) => PitchBallProvider()..loadAll(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: DefaultTabController(
          length: 2,
          child: Builder(
            builder: (tabContext) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('إدارة الملاعب والكرات'),
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'الملاعب', icon: Icon(Icons.stadium_outlined)),
                      Tab(text: 'الكرات', icon: Icon(Icons.sports_soccer)),
                    ],
                  ),
                ),
                body: Consumer<PitchBallProvider>(
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

                    return TabBarView(
                      children: [
                        _buildPitchesList(provider),
                        _buildBallsList(provider),
                      ],
                    );
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    final index =
                        DefaultTabController.of(tabContext).index;
                    if (index == 0) {
                      _showPitchForm(tabContext);
                    } else {
                      _showBallForm(tabContext);
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPitchesList(PitchBallProvider provider) {
    if (provider.pitches.isEmpty) {
      return const Center(
        child: Text('لا توجد ملاعب مسجلة حالياً.'),
      );
    }

    return ListView.builder(
      itemCount: provider.pitches.length,
      itemBuilder: (context, index) {
        final pitch = provider.pitches[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(pitch.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pitch.location != null && pitch.location!.isNotEmpty)
                  Text('الموقع: ${pitch.location}'),
                if (pitch.pricePerHour != null)
                  Text('السعر/ساعة: ${pitch.pricePerHour}'),
                Text(
                  pitch.isIndoor ? 'داخلي' : 'خارجي',
                ),
                Text(
                  pitch.isActive ? 'حالة: نشط' : 'حالة: غير نشط',
                  style: TextStyle(
                    color: pitch.isActive ? AppTheme.success : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  _showPitchForm(context, pitch: pitch);
                } else if (value == 'toggle') {
                  await provider.togglePitchActive(pitch);
                } else if (value == 'delete') {
                  await provider.deletePitch(pitch.id!);
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
                    pitch.isActive ? 'تعطيل' : 'تفعيل',
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
  }

  Widget _buildBallsList(PitchBallProvider provider) {
    if (provider.balls.isEmpty) {
      return const Center(
        child: Text('لا توجد كرات مسجلة حالياً.'),
      );
    }

    return ListView.builder(
      itemCount: provider.balls.length,
      itemBuilder: (context, index) {
        final ball = provider.balls[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(ball.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ball.size != null && ball.size!.isNotEmpty)
                  Text('المقاس: ${ball.size}'),
                Text('الكمية: ${ball.quantity}'),
                Text(
                  ball.isAvailable ? 'متاحة' : 'غير متاحة',
                  style: TextStyle(
                    color: ball.isAvailable ? AppTheme.success : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  _showBallForm(context, ball: ball);
                } else if (value == 'toggle') {
                  await provider.toggleBallAvailable(ball);
                } else if (value == 'delete') {
                  await provider.deleteBall(ball.id!);
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
                    ball.isAvailable ? 'تعطيل' : 'تفعيل',
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
  }
}
