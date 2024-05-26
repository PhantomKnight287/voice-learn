part of 'user_bloc.dart';

@immutable
abstract class UserEvent extends UserModel {
  UserEvent({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.gems,
    required super.updatedAt,
    required super.token,
    super.email,
  });
}

class UserLoggedInEvent extends UserEvent {
  UserLoggedInEvent({
    required super.id,
    required super.name,
    required super.token,
    super.email,
    required super.createdAt,
    required super.gems,
    required super.updatedAt,
  });
}

class UserLoggedOutEvent extends UserEvent {
  UserLoggedOutEvent({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.gems,
    required super.updatedAt,
    required super.token,
  });
}
