part of 'user_bloc.dart';

@immutable
abstract class UserState {
  final String id;
  final String? email;
  final String name;
  final int gems;
  final String updatedAt;
  final String createdAt;
  final String token;

  const UserState({
    this.name = '',
    this.id = '',
    this.token = '',
    this.email = '',
    this.createdAt = '',
    this.gems = 0,
    this.updatedAt = '',
  });
}

class UserInitial extends UserState {
  const UserInitial() : super();
}

class UserLoggedInState extends UserState {
  const UserLoggedInState({
    required super.name,
    required super.id,
    required super.token,
    required super.createdAt,
    required super.gems,
    required super.updatedAt,
    super.email = null,
  });
}

class UserLoggedOutState extends UserState {
  const UserLoggedOutState() : super();
}
