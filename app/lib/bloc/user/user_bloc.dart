import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<UserLoggedInEvent>((event, emit) {
      emit(UserLoggedInState(
        id: event.id,
        name: event.name,
        token: event.token,
        email: event.email,
      ));
    });
    on<UserLoggedOutEvent>((event, emit) {
      emit(UserLoggedOutState());
    });
  }
}
