// lib/models/user.dart

class User {
  final String createdAt;
  final String email;
  final String publicId;
  final String role;
  final String username;

  User({
    required this.createdAt,
    required this.email,
    required this.publicId,
    required this.role,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      createdAt: json['created_at'] as String,
      email: json['email'] as String,
      publicId: json['public_id'] as String,
      role: json['role'] as String,
      username: json['username'] as String,
    );
  }
}
