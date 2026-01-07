'''
import 'package:equatable/equatable.dart';

abstract class XtreamLoginEvent extends Equatable {
  const XtreamLoginEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends XtreamLoginEvent {
  final String serverUrl;
  final String username;
  final String password;

  const LoginButtonPressed({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [serverUrl, username, password];
}
'''
