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
    required super.xp,
    required super.streaks,
    required super.tier,
    super.isStreakActive,
    super.avatarHash,
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
    required super.xp,
    required super.streaks,
    super.isStreakActive,
    required super.tier,
    super.avatarHash,
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
    required super.xp,
    required super.tier,
    required super.streaks,
    super.isStreakActive,
    super.avatarHash,
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
    super.xp = -1,
    super.streaks = -1,
    super.isStreakActive = false,
    super.tier = Tiers.free,
    super.avatarHash = "",
  });
}
