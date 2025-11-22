class Coach {
  final int? id;
  final String name;
  final String? phone;
  final String? specialization;
  final double? pricePerHour;
  final bool isActive;
  final bool isDirty;
  final DateTime updatedAt;

  const Coach({
    this.id,
    required this.name,
    this.phone,
    this.specialization,
    this.pricePerHour,
    required this.isActive,
    required this.isDirty,
    required this.updatedAt,
  });

  Coach copyWith({
    int? id,
    String? name,
    String? phone,
    String? specialization,
    double? pricePerHour,
    bool? isActive,
    bool? isDirty,
    DateTime? updatedAt,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isActive: isActive ?? this.isActive,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'specialization': specialization,
      'price_per_hour': pricePerHour,
      'is_active': isActive ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Coach.fromMap(Map<String, dynamic> map) {
    return Coach(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      specialization: map['specialization'] as String?,
      pricePerHour: map['price_per_hour'] != null
          ? (map['price_per_hour'] as num).toDouble()
          : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
