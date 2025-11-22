class Pitch {
  final int? id;
  final String name;
  final String? location;
  final double? pricePerHour;
  final bool isIndoor;
  final bool isActive;
  final bool isDirty;
  final DateTime updatedAt;

  const Pitch({
    this.id,
    required this.name,
    this.location,
    this.pricePerHour,
    required this.isIndoor,
    required this.isActive,
    required this.isDirty,
    required this.updatedAt,
  });

  Pitch copyWith({
    int? id,
    String? name,
    String? location,
    double? pricePerHour,
    bool? isIndoor,
    bool? isActive,
    bool? isDirty,
    DateTime? updatedAt,
  }) {
    return Pitch(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isIndoor: isIndoor ?? this.isIndoor,
      isActive: isActive ?? this.isActive,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'price_per_hour': pricePerHour,
      'is_indoor': isIndoor ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pitch.fromMap(Map<String, dynamic> map) {
    return Pitch(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      location: map['location'] as String?,
      pricePerHour: map['price_per_hour'] != null
          ? (map['price_per_hour'] as num).toDouble()
          : null,
      isIndoor: (map['is_indoor'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
