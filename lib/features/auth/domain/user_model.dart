class UserModel {
  final int id;
  final int companyId;
  final int? branchId;
  final String name;
  final String email;
  final String role;
  final String phone;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.permissions,
  });

  /// Parse from the API login/me response user object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      companyId: json['company_id'] as int? ?? 0,
      branchId: json['branch_id'] as int?,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String? ?? '',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convenience getter — displayed in Dashboard as agent identifier
  String get agentCode => 'MG-${id.toString().padLeft(4, '0')}';

  /// Check if this user has a specific permission
  bool hasPermission(String permission) => permissions.contains(permission);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'permissions': permissions,
    };
  }
}
