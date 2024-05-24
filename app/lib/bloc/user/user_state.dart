part of 'user_bloc.dart';

@immutable
abstract class UserState {
  final String name;
  final String id;
  final String token;
  final String? email;

  const UserState({
    this.name = '',
    this.id = '',
    this.token = '',
    this.email = '',
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
    super.email = null,
  });
}

class UserLoggedOutState extends UserState {
  const UserLoggedOutState() : super();
}
