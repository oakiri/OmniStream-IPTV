import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/add_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'package:omnistream_iptv/core/usecases/no_params.dart';

part 'playlist_profile_event.dart';
part 'playlist_profile_state.dart';

class PlaylistProfileBloc extends Bloc<PlaylistProfileEvent, PlaylistProfileState> {
  final GetPlaylistProfiles getPlaylistProfiles;
  final AddPlaylistProfile addPlaylistProfile;
  final DeletePlaylistProfile deletePlaylistProfile;

  PlaylistProfileBloc({
    required this.getPlaylistProfiles,
    required this.addPlaylistProfile,
    required this.deletePlaylistProfile,
  }) : super(PlaylistProfileInitial()) {
    on<LoadPlaylistProfiles>(_onLoadPlaylistProfiles);
    on<AddProfileEvent>(_onAddProfile);
    on<DeleteProfileEvent>(_onDeleteProfile);
  }

  Future<void> _onLoadPlaylistProfiles(
    LoadPlaylistProfiles event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());
    final failureOrProfiles = await getPlaylistProfiles(NoParams());
    failureOrProfiles.fold(
      // CORREGIDO: message: ...
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      // CORREGIDO: profiles: ...
      (profiles) => emit(PlaylistProfileLoaded(profiles: profiles)),
    );
  }

  Future<void> _onAddProfile(
    AddProfileEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());
    final failureOrSuccess = await addPlaylistProfile(event.profile);
    failureOrSuccess.fold(
      // CORREGIDO: message: ...
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (_) => add(LoadPlaylistProfiles()), 
    );
  }

  Future<void> _onDeleteProfile(
    DeleteProfileEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());
    final failureOrSuccess = await deletePlaylistProfile(event.id);
    failureOrSuccess.fold(
      // CORREGIDO: message: ...
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (_) => add(LoadPlaylistProfiles()),
    );
  }

  String _mapFailureToMessage(dynamic failure) {
    return "Error inesperado cargando perfiles";
  }
}