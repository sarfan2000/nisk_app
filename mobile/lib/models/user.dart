class User {
  final String id;
  final String name;
  final String userType;
  final String? phone;
  final String? email;
  final String token;

  User({
    required this.id,
    required this.name,
    required this.userType,
    this.phone,
    this.email,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      userType: json['userType'] ?? '',
      phone: json['phone'],
      email: json['email'],
      token: token,
    );
  }
}
