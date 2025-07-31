// lib/models/user_model.dart (Conceptual - adapt to your actual file)
class CurrentUser { // Or whatever your user model is named
  final String uid;
  final String email;
  final String accessToken;
  final String refreshToken;
  final String role; // <--- THIS IS CRUCIAL

  CurrentUser({
    required this.uid,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.role, // <--- Add this to your constructor
  });

  // Add a fromJson factory if you deserialize user data from your backend
  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      uid: json['public_id'] as String, // Assuming public_id is your user ID
      email: json['email'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      role: json['role'] as String, // <--- Make sure your backend sends this
    );
  }
}