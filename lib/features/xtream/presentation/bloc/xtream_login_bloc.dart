import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/login.dart' as xtream_login;
import 'xtream_login_event.dart';
import 'xtream_login_state.dart';

class XtreamLoginBloc extends Bloc<XtreamLoginEvent, XtreamLoginState> {
  final xtream_login.Login login;

  XtreamLoginBloc({required this.login}) : super(XtreamLoginInitial()) {
    on<LoginButtonPressed>((event, emit) async {
      emit(XtreamLoginLoading());
      final failureOrUserInfo = await login(
        xtream_login.Params(
          serverUrl: event.serverUrl,
          username: event.username,
          password: event.password,
        ),
      );
      failureOrUserInfo.fold(
        (failure) => emit(XtreamLoginError(message: _mapFailureToMessage(failure))),
        (userInfo) => emit(XtreamLoginSuccess(userInfo: userInfo)),
      );
    });
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Failure';
      default:
        return 'Unexpected error';
    }
  }
}
