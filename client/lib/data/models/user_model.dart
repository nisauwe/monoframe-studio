class UserModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String phone;
  final String address;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.phone,
    required this.address,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phone:
          json['phone']?.toString() ??
          json['whatsapp']?.toString() ??
          json['phone_number']?.toString() ??
          '',
      address: json['address']?.toString() ?? json['alamat']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'phone': phone,
      'address': address,
      'role': role,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? username,
    String? phone,
    String? address,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
