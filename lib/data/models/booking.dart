class Booking {
  final int? id;
  final String? firebaseId; // جديد للمزامنة
  final int userId;
  final int? coachId;
  final int pitchId;
  final int? ballId;
  final DateTime startTime;
  final DateTime endTime;
  final double? totalPrice;
  final String? status; // pending / paid / cancelled
  final String? notes;

  final String? teamName;
  final String? customerPhone;
  final String? period; // morning / evening

  final int createdByUserId;
  final double? staffWage;
  final double? coachWage;

  final bool isDeposited; // جديد للتوريد المالي
  final bool isDirty;
  final String? deletedAt; // جديد للحذف الناعم
  final DateTime updatedAt;

  const Booking({
    this.id,
    this.firebaseId,
    required this.userId,
    this.coachId,
    required this.pitchId,
    this.ballId,
    required this.startTime,
    required this.endTime,
    this.totalPrice,
    this.status,
    this.notes,
    this.teamName,
    this.customerPhone,
    this.period,
    required this.createdByUserId,
    this.staffWage,
    this.coachWage,
    this.isDeposited = false, // القيمة الافتراضية
    required this.isDirty,
    this.deletedAt,
    required this.updatedAt,
  });

  Booking copyWith({
    int? id,
    String? firebaseId,
    int? userId,
    int? coachId,
    int? pitchId,
    int? ballId,
    DateTime? startTime,
    DateTime? endTime,
    double? totalPrice,
    String? status,
    String? notes,
    String? teamName,
    String? customerPhone,
    String? period,
    int? createdByUserId,
    double? staffWage,
    double? coachWage,
    bool? isDeposited,
    bool? isDirty,
    String? deletedAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      userId: userId ?? this.userId,
      coachId: coachId ?? this.coachId,
      pitchId: pitchId ?? this.pitchId,
      ballId: ballId ?? this.ballId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      teamName: teamName ?? this.teamName,
      customerPhone: customerPhone ?? this.customerPhone,
      period: period ?? this.period,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      staffWage: staffWage ?? this.staffWage,
      coachWage: coachWage ?? this.coachWage,
      isDeposited: isDeposited ?? this.isDeposited,
      isDirty: isDirty ?? this.isDirty,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_id': firebaseId,
      'user_id': userId,
      'coach_id': coachId,
      'pitch_id': pitchId,
      'ball_id': ballId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
      'notes': notes,
      'team_name': teamName,
      'customer_phone': customerPhone,
      'period': period,
      'created_by_user_id': createdByUserId,
      'staff_wage': staffWage,
      'coach_wage': coachWage,
      'is_deposited': isDeposited ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'deleted_at': deletedAt,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      firebaseId: map['firebase_id'] as String?,
      userId: map['user_id'] as int? ?? 0,
      coachId: map['coach_id'] as int?,
      pitchId: map['pitch_id'] as int? ?? 0,
      ballId: map['ball_id'] as int?,
      startTime:
          DateTime.tryParse(map['start_time']?.toString() ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(map['end_time']?.toString() ?? '') ??
          DateTime.now(),
      totalPrice: map['total_price'] != null
          ? (map['total_price'] as num).toDouble()
          : null,
      status: map['status'] as String?,
      notes: map['notes'] as String?,
      teamName: map['team_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      period: map['period'] as String?,
      createdByUserId: map['created_by_user_id'] as int? ?? 0,
      staffWage: map['staff_wage'] != null
          ? (map['staff_wage'] as num).toDouble()
          : null,
      coachWage: map['coach_wage'] != null
          ? (map['coach_wage'] as num).toDouble()
          : null,
      isDeposited: (map['is_deposited'] as int? ?? 0) == 1,
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] as String?,
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
