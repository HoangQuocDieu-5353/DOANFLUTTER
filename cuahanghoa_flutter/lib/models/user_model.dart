class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String role;
  final bool isLocked;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatarUrl,
    this.createdAt,
    this.role = "user",
    this.isLocked = false,
    this.dateOfBirth,
    this.gender,
    this.notificationsEnabled = true,
  });
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
      'role': role,
      'isLocked': isLocked,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'notificationsEnabled': notificationsEnabled,
    };
  }
  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      avatarUrl: map['avatarUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      role: map['role'] ?? 'user',
      isLocked: map['isLocked'] ?? false,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'])
          : null,
      gender: map['gender'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    DateTime? createdAt,
    String? role,
    bool? isLocked,
    DateTime? dateOfBirth,
    String? gender,

    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      isLocked: isLocked ?? this.isLocked,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,

      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role, '
        'isLocked: $isLocked, dateOfBirth: $dateOfBirth, gender: $gender, '
        'notificationsEnabled: $notificationsEnabled)';
  }
}
