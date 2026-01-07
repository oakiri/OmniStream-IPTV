import 'package:equatable/equatable.dart';

import '../../data/models/epg_program.dart';

abstract class EpgState extends Equatable {
  const EpgState();

  @override
  List<Object> get props => [];
}

class EpgInitial extends EpgState {}

class EpgLoading extends EpgState {}

class EpgLoaded extends EpgState {
  final List<EpgProgram> programs;

  const EpgLoaded(this.programs);

  @override
  List<Object> get props => [programs];
}

class EpgError extends EpgState {
  final String message;

  const EpgError(this.message);

  @override
  List<Object> get props => [message];
}
