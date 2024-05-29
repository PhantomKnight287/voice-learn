part of 'user_bloc.dart';

@immutable
abstract class UserState extends UserModel {
  UserState({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.paths,
    required super.updatedAt,
    required super.token,
    super.email,
  });
}

class UserInitial extends UserState {
  UserInitial({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.paths,
    required super.updatedAt,
    required super.token,
    super.email,
  });
}

class UserLoggedInState extends UserState {
  UserLoggedInState({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.paths,
    required super.updatedAt,
    required super.token,
    super.email,
  });
}

class UserLoggedOutState extends UserState {
  UserLoggedOutState({
    super.id = '',
    super.name = '',
    super.createdAt = '',
    super.paths = 0,
    super.updatedAt = '',
    super.token = '',
    super.email = '',
  });
}
