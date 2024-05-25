class UserModel {
  final String id;
  final String? email;
  final String name;
  final int gems;
  final String updatedAt;
  final String createdAt;

  UserModel({
    required this.id,
    this.email,
    required this.name,
    required this.createdAt,
    required this.gems,
    required this.updatedAt,
  });

  factory UserModel.fromJSON(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: json["createdAt"],
      gems: json["gems"],
      updatedAt: json["updatedAt"],
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, name: $name}';
  }
}
