import 'package:app/models/user.dart';

class LoginResponse {
  final String token;
  final UserModel user;

  const LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJSON(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: UserModel.fromJSON(
        json['user'],
        json['token'],
      ),
    );
  }

  @override
  String toString() {
    return 'LoginResponse{token: $token, user: $user}';
  }
}

class RegisterResponse extends LoginResponse {
  const RegisterResponse({
    required super.token,
    required super.user,
  });

  factory RegisterResponse.fromJSON(Map<String, dynamic> json) {
    return RegisterResponse(
      token: json['token'],
      user: UserModel.fromJSON(json['user'], json['token']),
    );
  }

  @override
  String toString() {
    return 'RegisterResponse{token: $token, user: $user}';
  }
}
