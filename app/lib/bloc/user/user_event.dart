part of 'user_bloc.dart';

@immutable
abstract class UserEvent extends UserModel {
  UserEvent({
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

class UserLoggedInEvent extends UserEvent {
  UserLoggedInEvent({
    required super.id,
    required super.name,
    required super.token,
    super.email,
    required super.createdAt,
    required super.paths,
    required super.updatedAt,
    required super.emeralds,
    required super.lives,
  });
}

class UserLoggedOutEvent extends UserEvent {
  UserLoggedOutEvent({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.paths,
    required super.updatedAt,
    required super.token,
    required super.emeralds,
    required super.lives,
  });
}
