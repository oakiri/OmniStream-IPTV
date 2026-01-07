import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/add_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'playlist_profile_event.dart';
import 'playlist_profile_state.dart';

import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart' as entity;

class PlaylistProfileBloc extends Bloc<PlaylistProfileEvent, PlaylistProfileState> {
  final GetPlaylistProfiles getPlaylistProfiles;
  final AddPlaylistProfile addPlaylistProfile;
  final DeletePlaylistProfile deletePlaylistProfile;

  PlaylistProfileBloc({
    required this.getPlaylistProfiles,
    required this.addPlaylistProfile,
    required this.deletePlaylistProfile,
  }) : super(PlaylistProfileInitial()) {
    on<GetProfilesEvent>(_onGetProfiles);
    on<AddProfileEvent>(_onAddProfile);
    on<DeleteProfileEvent>(_onDeleteProfile);
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Failure: Could not sync with cloud.';
      default:
        return 'Unexpected error';
    }
  }

  Future<void> _onGetProfiles(
    GetProfilesEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());
    final failureOrProfiles = await getPlaylistProfiles(NoParams());
    failureOrProfiles.fold(
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (profiles) => emit(PlaylistProfileLoaded(profiles: profiles)),
    );
  }

  Future<void> _onAddProfile(
    AddProfileEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is PlaylistProfileLoaded) {
      // Optimistic update
      final newProfiles = List<entity.PlaylistProfile>.from(currentState.profiles)..add(event.profile);
      emit(PlaylistProfileLoaded(profiles: newProfiles));
    } else {
      emit(PlaylistProfileLoading());
    }

    final failureOrVoid = await addPlaylistProfile(event.profile);
    failureOrVoid.fold(
      (failure) {
        // Revert on failure and show error
        if (currentState is PlaylistProfileLoaded) {
          emit(PlaylistProfileLoaded(profiles: currentState.profiles));
        }
        emit(PlaylistProfileError(message: _mapFailureToMessage(failure)));
      },
      (_) {
        // If successful, reload to ensure cloud sync is reflected
        add(GetProfilesEvent());
      },
    );
  }

  Future<void> _onDeleteProfile(
    DeleteProfileEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is PlaylistProfileLoaded) {
      // Optimistic update
      final newProfiles = currentState.profiles.where((p) => p.id != event.id).toList();
      emit(PlaylistProfileLoaded(profiles: newProfiles));
    } else {
      emit(PlaylistProfileLoading());
    }

    final failureOrVoid = await deletePlaylistProfile(event.id);
    failureOrVoid.fold(
      (failure) {
        // Revert on failure and show error
        if (currentState is PlaylistProfileLoaded) {
          emit(PlaylistProfileLoaded(profiles: currentState.profiles));
        }
        emit(PlaylistProfileError(message: _mapFailureToMessage(failure)));
      },
      (_) {
        // If successful, reload to ensure cloud sync is reflected
        add(GetProfilesEvent());
      },
    );
  }
}
