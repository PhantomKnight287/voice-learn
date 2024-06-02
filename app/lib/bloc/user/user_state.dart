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
    required super.emeralds,
    required super.lives,
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
    required super.emeralds,
    required super.lives,
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
    required super.emeralds,
    required super.lives,
  });
}

class UserLoggedOutState extends UserState {
  UserLoggedOutState({
    super.id = '',
    super.name = '',
    super.createdAt = '',
    super.paths = -1,
    super.updatedAt = '',
    super.token = '',
    super.email = '',
    super.emeralds = -1,
    super.lives = -1,
  });
}
