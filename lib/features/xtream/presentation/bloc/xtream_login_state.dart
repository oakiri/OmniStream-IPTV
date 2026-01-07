'''
import 'package:equatable/equatable.dart';

import '../../data/models/xtream_user_info_model.dart';

abstract class XtreamLoginState extends Equatable {
  const XtreamLoginState();

  @override
  List<Object> get props => [];
}

class XtreamLoginInitial extends XtreamLoginState {}

class XtreamLoginLoading extends XtreamLoginState {}

class XtreamLoginSuccess extends XtreamLoginState {
  final XtreamUserInfoModel userInfo;

  const XtreamLoginSuccess({required this.userInfo});

  @override
  List<Object> get props => [userInfo];
}

class XtreamLoginError extends XtreamLoginState {
  final String message;

  const XtreamLoginError({required this.message});

  @override
  List<Object> get props => [message];
}
'''
