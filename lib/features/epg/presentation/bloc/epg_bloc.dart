import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_epg_data.dart';
import 'epg_event.dart';
import 'epg_state.dart';

class EpgBloc extends Bloc<EpgEvent, EpgState> {
  final GetEpgData getEpgData;

  EpgBloc({required this.getEpgData}) : super(EpgInitial()) {
    on<FetchEpgData>((event, emit) async {
      emit(EpgLoading());
      final failureOrEpgData = await getEpgData(Params(url: event.url));
      failureOrEpgData.fold(
        (failure) => emit(EpgError(_mapFailureToMessage(failure))),
        (epgData) => emit(EpgLoaded(epgData)),
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
