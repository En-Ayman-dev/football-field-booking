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

  // Helper safely converts any value to int (0 if null/fail)
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  // Helper safely converts any value to double (null if fail)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: _parseInt(map['id'], defaultValue: 0) == 0 ? null : _parseInt(map['id']),
      name: map['name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      role: map['role']?.toString() ?? 'staff',
      
      // التعامل الآمن مع القيم المنطقية المخزنة كأرقام
      isActive: _parseInt(map['is_active'], defaultValue: 1) == 1,
      
      // التعامل الآمن مع الأرقام العشرية
      wagePerBooking: _parseDouble(map['wage_per_booking']),
      
      canManagePitches: _parseInt(map['can_manage_pitches']) == 1,
      canManageCoaches: _parseInt(map['can_manage_coaches']) == 1,
      canManageBookings: _parseInt(map['can_manage_bookings']) == 1,
      canViewReports: _parseInt(map['can_view_reports']) == 1,
      isDirty: _parseInt(map['is_dirty']) == 1,
      
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}