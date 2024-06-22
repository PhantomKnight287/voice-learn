import 'package:app/models/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc()
      : super(
          UserInitial(
            createdAt: '',
            paths: 0,
            id: '',
            name: '',
            token: '',
            updatedAt: '',
            emeralds: -1,
            lives: -1,
            xp: -1,
            streaks: -1,
            isStreakActive: false,
            tier: Tiers.free,
          ),
        ) {
    on<UserLoggedInEvent>((event, emit) {
      emit(
        UserLoggedInState(
          id: event.id,
          name: event.name,
          token: event.token,
          email: event.email,
          createdAt: event.createdAt,
          paths: event.paths,
          updatedAt: event.updatedAt,
          emeralds: event.emeralds,
          lives: event.lives,
          xp: event.xp,
          streaks: event.streaks,
          isStreakActive: event.isStreakActive,
          tier: event.tier,
        ),
      );
    });
    on<UserLoggedOutEvent>((event, emit) {
      emit(
        UserLoggedOutState(),
      );
    });

    on<DecreaseUserHeartEvent>((event, emit) {
      emit(
        UserLoggedInState(
          createdAt: event.createdAt,
          emeralds: event.emeralds,
          id: event.id,
          lives: event.lives,
          name: event.name,
          paths: event.paths,
          token: event.token,
          updatedAt: event.updatedAt,
          xp: event.xp,
          streaks: event.streaks,
          isStreakActive: event.isStreakActive,
          tier: event.tier,
        ),
      );
    });
  }
}
