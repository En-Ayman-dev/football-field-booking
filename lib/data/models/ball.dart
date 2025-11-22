class Ball {
  final int? id;
  final String name;
  final String? size;
  final int quantity;
  final bool isAvailable;
  final bool isDirty;
  final DateTime updatedAt;

  const Ball({
    this.id,
    required this.name,
    this.size,
    required this.quantity,
    required this.isAvailable,
    required this.isDirty,
    required this.updatedAt,
  });

  Ball copyWith({
    int? id,
    String? name,
    String? size,
    int? quantity,
    bool? isAvailable,
    bool? isDirty,
    DateTime? updatedAt,
  }) {
    return Ball(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      isAvailable: isAvailable ?? this.isAvailable,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'quantity': quantity,
      'is_available': isAvailable ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Ball.fromMap(Map<String, dynamic> map) {
    return Ball(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      size: map['size'] as String?,
      quantity: map['quantity'] as int? ?? 0,
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
