import 'package:equatable/equatable.dart';

abstract class EpgEvent extends Equatable {
  const EpgEvent();

  @override
  List<Object> get props => [];
}

class FetchEpgData extends EpgEvent {
  final String url;

  const FetchEpgData(this.url);

  @override
  List<Object> get props => [url];
}
