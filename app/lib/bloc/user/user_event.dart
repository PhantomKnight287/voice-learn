part of 'user_bloc.dart';

@immutable
abstract class UserEvent {}

class UserLoggedInEvent extends UserEvent {
  final String name;
  final String token;
  final String id;
  final String? email;

  UserLoggedInEvent({
    required this.id,
    required this.name,
    required this.token,
    this.email,
  });
}

class UserLoggedOutEvent extends UserEvent {}
