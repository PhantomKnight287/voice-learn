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
    required super.xp,
    required super.streaks,
    super.isStreakActive,
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
    required super.xp,
    required super.streaks,
    super.isStreakActive,
  });
  factory UserLoggedInEvent.fromUser(UserModel user, String token) {
    return UserLoggedInEvent(
      id: user.id,
      name: user.name,
      token: token,
      email: user.email,
      createdAt: user.createdAt,
      paths: user.paths,
      updatedAt: user.updatedAt,
      emeralds: user.emeralds,
      lives: user.lives,
      xp: user.xp,
      streaks: user.streaks,
      isStreakActive: user.isStreakActive,
    );
  }
  factory UserLoggedInEvent.setEmeraldsAndLives(UserModel user, int emeralds, int lives) {
    return UserLoggedInEvent(
      id: user.id,
      name: user.name,
      token: user.token,
      email: user.email,
      createdAt: user.createdAt,
      paths: user.paths,
      updatedAt: user.updatedAt,
      emeralds: emeralds,
      lives: lives,
      xp: user.xp,
      streaks: user.streaks,
      isStreakActive: user.isStreakActive,
    );
  }
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
    required super.xp,
    required super.streaks,
    super.isStreakActive,
  });
}

class DecreaseUserHeartEvent extends UserEvent {
  DecreaseUserHeartEvent({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.paths,
    required super.updatedAt,
    required super.token,
    required super.emeralds,
    required super.lives,
    required super.streaks,
    required super.xp,
    super.isStreakActive,
  });
}
