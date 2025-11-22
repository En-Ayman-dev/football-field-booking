class User {
  final int? id;
  final String name;
  final String username;
  final String password;
  final String? phone;
  final String? email;
  final String role; // admin / staff / customer
  final bool isActive;
  final double? wagePerBooking; // الأجر لكل حجز (للعامل)
  final bool canManagePitches;
  final bool canManageCoaches;
  final bool canManageBookings;
  final bool canViewReports;
  final bool isDirty;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.name,
    required this.username,
    required this.password,
    this.phone,
    this.email,
    required this.role,
    required this.isActive,
    this.wagePerBooking,
    required this.canManagePitches,
    required this.canManageCoaches,
    required this.canManageBookings,
    required this.canViewReports,
    required this.isDirty,
    required this.updatedAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStaff => role.toLowerCase() == 'staff';

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? password,
    String? phone,
    String? email,
    String? role,
    bool? isActive,
    double? wagePerBooking,
    bool? canManagePitches,
    bool? canManageCoaches,
    bool? canManageBookings,
    bool? canViewReports,
    bool? isDirty,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      wagePerBooking: wagePerBooking ?? this.wagePerBooking,
      canManagePitches: canManagePitches ?? this.canManagePitches,
      canManageCoaches: canManageCoaches ?? this.canManageCoaches,
      canManageBookings: canManageBookings ?? this.canManageBookings,
      canViewReports: canViewReports ?? this.canViewReports,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'phone': phone,
      'email': email,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'wage_per_booking': wagePerBooking,
      'can_manage_pitches': canManagePitches ? 1 : 0,
      'can_manage_coaches': canManageCoaches ? 1 : 0,
      'can_manage_bookings': canManageBookings ? 1 : 0,
      'can_view_reports': canViewReports ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      role: map['role'] as String? ?? 'staff',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      wagePerBooking: map['wage_per_booking'] != null
          ? (map['wage_per_booking'] as num).toDouble()
          : null,
      canManagePitches: (map['can_manage_pitches'] as int? ?? 0) == 1,
      canManageCoaches: (map['can_manage_coaches'] as int? ?? 0) == 1,
      canManageBookings: (map['can_manage_bookings'] as int? ?? 0) == 1,
      canViewReports: (map['can_view_reports'] as int? ?? 0) == 1,
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
