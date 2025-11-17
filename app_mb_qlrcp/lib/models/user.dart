class User {
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String role; // "Customer", "Staff", "Admin"

  User({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'Customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }

  bool get isCustomer => role == 'Customer';
  bool get isStaff => role == 'Staff' || role == 'Admin';
}
