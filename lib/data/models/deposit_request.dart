class DepositRequest {
  final int? id;
  final int userId;
  final double amount;
  final String? note;
  final String status; // pending, approved, rejected
  final int? processedBy; // admin user id
  final DateTime createdAt;
  final DateTime? processedAt;

  const DepositRequest({
    this.id,
    required this.userId,
    required this.amount,
    this.note,
    required this.status,
    this.processedBy,
    required this.createdAt,
    this.processedAt,
  });

  DepositRequest copyWith({
    int? id,
    int? userId,
    double? amount,
    String? note,
    String? status,
    int? processedBy,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return DepositRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      status: status ?? this.status,
      processedBy: processedBy ?? this.processedBy,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'note': note,
      'status': status,
      'processed_by': processedBy,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  factory DepositRequest.fromMap(Map<String, dynamic> map) {
    return DepositRequest(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      status: map['status'] as String? ?? 'pending',
      processedBy: map['processed_by'] as int?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      processedAt: DateTime.tryParse(map['processed_at']?.toString() ?? ''),
    );
  }
}
