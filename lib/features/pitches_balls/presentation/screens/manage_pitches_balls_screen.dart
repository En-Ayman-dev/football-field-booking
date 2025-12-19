// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/ball.dart';
import '../../../../data/models/pitch.dart';
import '../../../../core/utils/responsive_helper.dart'; // استيراد محرك التجاوب
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp))), // متجاوب
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 2.h, // متجاوب
              top: 2.h,
              right: 4.w,
              left: 4.w,
            ),
            child: StatefulBuilder(
              builder: (context, setStateSheet) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pitch == null ? 'إضافة ملعب جديد' : 'تعديل الملعب',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16.sp), // متجاوب
                      ),
                      SizedBox(height: 2.h), // متجاوب
                      TextField(
                        controller: nameController,
                        style: TextStyle(fontSize: 14.sp), // متجاوب
                        decoration: InputDecoration(
                          labelText: 'اسم الملعب',
                          labelStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 1.h), // متجاوب
                      TextField(
                        controller: locationController,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          labelText: 'الموقع',
                          labelStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      TextField(
                        controller: priceController,
                        style: TextStyle(fontSize: 14.sp),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'السعر للساعة (اختياري)',
                          labelStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SwitchListTile(
                        value: isIndoor,
                        onChanged: (val) {
                          setStateSheet(() {
                            isIndoor = val;
                          });
                        },
                        title: Text('ملعب داخلي', style: TextStyle(fontSize: 13.sp)), // متجاوب
                      ),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (val) {
                          setStateSheet(() {
                            isActive = val;
                          });
                        },
                        title: Text('نشط', style: TextStyle(fontSize: 13.sp)), // متجاوب
                      ),
                      SizedBox(height: 2.h),
                      SizedBox(
                        width: double.infinity,
                        height: 6.h, // متجاوب
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
                          child: Text(pitch == null ? 'حفظ' : 'تحديث', style: TextStyle(fontSize: 14.sp)), // متجاوب
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp))), // متجاوب
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 2.h,
              top: 2.h,
              right: 4.w,
              left: 4.w,
            ),
            child: StatefulBuilder(
              builder: (context, setStateSheet) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ball == null ? 'إضافة كرة جديدة' : 'تعديل الكرة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16.sp), // متجاوب
                      ),
                      SizedBox(height: 2.h),
                      TextField(
                        controller: nameController,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          labelText: 'اسم الكرة',
                          labelStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      TextField(
                        controller: sizeController,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          labelText: 'المقاس (اختياري)',
                          labelStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      TextField(
                        controller: quantityController,
                        style: TextStyle(fontSize: 14.sp),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'الكمية المتاحة',
                          labelStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SwitchListTile(
                        value: isAvailable,
                        onChanged: (val) {
                          setStateSheet(() {
                            isAvailable = val;
                          });
                        },
                        title: Text('متاحة', style: TextStyle(fontSize: 13.sp)), // متجاوب
                      ),
                      SizedBox(height: 2.h),
                      SizedBox(
                        width: double.infinity,
                        height: 6.h, // متجاوب
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
                          child: Text(ball == null ? 'حفظ' : 'تحديث', style: TextStyle(fontSize: 14.sp)), // متجاوب
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
                  title: Text('إدارة الملاعب والكرات', style: TextStyle(fontSize: 18.sp)), // متجاوب
                  bottom: TabBar(
                    tabs: [
                      Tab(text: 'الملاعب', icon: Icon(Icons.stadium_outlined, size: 20.sp)), // متجاوب
                      Tab(text: 'الكرات', icon: Icon(Icons.sports_soccer, size: 20.sp)), // متجاوب
                    ],
                    labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: TextStyle(fontSize: 11.sp),
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
                        child: Text(provider.errorMessage!, style: TextStyle(fontSize: 14.sp)), // متجاوب
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
                  child: Icon(Icons.add, size: 24.sp), // متجاوب
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
      return Center(
        child: Text('لا توجد ملاعب مسجلة حالياً.', style: TextStyle(fontSize: 14.sp)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h), // متجاوب
      itemCount: provider.pitches.length,
      itemBuilder: (context, index) {
        final pitch = provider.pitches[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h), // متجاوب
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)), // متجاوب
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h), // متجاوب
            title: Text(pitch.name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)), // متجاوب
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pitch.location != null && pitch.location!.isNotEmpty)
                  Text('الموقع: ${pitch.location}', style: TextStyle(fontSize: 12.sp)), // متجاوب
                if (pitch.pricePerHour != null)
                  Text('السعر/ساعة: ${pitch.pricePerHour}', style: TextStyle(fontSize: 12.sp)), // متجاوب
                Text(
                  pitch.isIndoor ? 'داخلي' : 'خارجي',
                  style: TextStyle(fontSize: 12.sp),
                ),
                Text(
                  pitch.isActive ? 'حالة: نشط' : 'حالة: غير نشط',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: pitch.isActive ? AppTheme.success : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20.sp), // متجاوب
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
                PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل', style: TextStyle(fontSize: 13.sp)),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    pitch.isActive ? 'تعطيل' : 'تفعيل',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(fontSize: 13.sp)),
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
      return Center(
        child: Text('لا توجد كرات مسجلة حالياً.', style: TextStyle(fontSize: 14.sp)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: provider.balls.length,
      itemBuilder: (context, index) {
        final ball = provider.balls[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
            title: Text(ball.name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ball.size != null && ball.size!.isNotEmpty)
                  Text('المقاس: ${ball.size}', style: TextStyle(fontSize: 12.sp)),
                Text('الكمية: ${ball.quantity}', style: TextStyle(fontSize: 12.sp)),
                Text(
                  ball.isAvailable ? 'متاحة' : 'غير متاحة',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: ball.isAvailable ? AppTheme.success : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20.sp),
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
                PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل', style: TextStyle(fontSize: 13.sp)),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    ball.isAvailable ? 'تعطيل' : 'تفعيل',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(fontSize: 13.sp)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}