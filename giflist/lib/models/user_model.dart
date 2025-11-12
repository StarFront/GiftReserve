class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'host' o 'guest'
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'profileImage': profileImage,
    };
  }
}
