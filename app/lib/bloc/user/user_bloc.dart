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
        ),
      );
    });
    on<UserLoggedOutEvent>((event, emit) {
      emit(
        UserLoggedOutState(),
      );
    });
  }
}
