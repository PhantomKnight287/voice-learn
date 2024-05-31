class UserModel {
  final String id;
  final String? email;
  final String name;
  final int paths;
  final String updatedAt;
  final String createdAt;
  final String token;

  UserModel({
    required this.id,
    this.email,
    required this.name,
    required this.createdAt,
    required this.paths,
    required this.updatedAt,
    required this.token,
  });

  factory UserModel.fromJSON(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: json["createdAt"],
      paths: json["_count"]?["paths"] ?? 0,
      updatedAt: json["updatedAt"],
      token: token,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, name: $name}';
  }
}
