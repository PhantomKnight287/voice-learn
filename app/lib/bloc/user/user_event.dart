part of 'user_bloc.dart';

@immutable
abstract class UserEvent {}

class UserLoggedInEvent extends UserEvent {
  final String id;
  final String? email;
  final String name;
  final int gems;
  final String updatedAt;
  final String createdAt;
  final String token;

  UserLoggedInEvent({
    required this.id,
    required this.name,
    required this.token,
    this.email,
    required this.createdAt,
    required this.gems,
    required this.updatedAt,
  });
}

class UserLoggedOutEvent extends UserEvent {}
