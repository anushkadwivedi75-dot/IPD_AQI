class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? token;
  final String role;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.token,
    this.role = 'user',
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: json['email'] as String? ?? json['phone_or_email'] as String? ?? '',
      name: json['name'] as String? ?? (json['email'] as String?)?.split('@').first ?? 'AirSentinel User',
      token: json['token'] as String? ?? json['access_token'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'token': token,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? token,
    String? role,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      token: token ?? this.token,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
