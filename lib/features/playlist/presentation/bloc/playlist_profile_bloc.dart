import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/core/usecases/no_params.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/add_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/update_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/delete_playlist_profile.dart';
import 'package:omnistream_iptv/core/utils/xtream_api_helper.dart';
import 'package:omnistream_iptv/core/utils/app_logger.dart';

// --- DECLARACIÓN DE PARTES (CRÍTICO PARA QUE FUNCIONE) ---
part 'playlist_profile_event.dart';
part 'playlist_profile_state.dart';

class PlaylistProfileBloc extends Bloc<PlaylistProfileEvent, PlaylistProfileState> {
  final GetPlaylistProfiles getPlaylistProfiles;
  final AddPlaylistProfile addPlaylistProfile;
  final UpdatePlaylistProfile updatePlaylistProfile;
  final DeletePlaylistProfile deletePlaylistProfile;

  static const _log = AppLogger('playlist.profiles');

  PlaylistProfileBloc({
    required this.getPlaylistProfiles,
    required this.addPlaylistProfile,
    required this.updatePlaylistProfile,
    required this.deletePlaylistProfile,
  }) : super(PlaylistProfileInitial()) {
    on<LoadPlaylistProfiles>(_onLoadPlaylistProfiles);
    on<AddProfileEvent>(_onAddPlaylistProfile);
    on<UpdateProfileEvent>(_onUpdatePlaylistProfile);
    on<DeleteProfileEvent>(_onDeletePlaylistProfile);
  }

  Future<void> _onLoadPlaylistProfiles(
    LoadPlaylistProfiles event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());
    final result = await getPlaylistProfiles(NoParams());
    result.fold(
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (profiles) => emit(PlaylistProfilesLoaded(profiles: profiles)),
    );
  }

  Future<void> _onAddPlaylistProfile(
    AddProfileEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());
    
    DateTime? expiration;
    try {
      // Intentamos obtener la fecha real de la API
      expiration = await XtreamApiHelper.checkExpiration(event.url);
    } catch (e) {
      // Si falla, guardamos sin fecha, pero no bloqueamos la app
      _log.warn('No se pudo verificar caducidad (add): $e');
    }

    final profile = PlaylistProfile(
      id: const Uuid().v4(),
      name: event.name,
      url: event.url,
      userId: event.username,
      expirationDate: expiration,
    );

    final result = await addPlaylistProfile(profile);

    result.fold(
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (_) => add(LoadPlaylistProfiles()),
    );
  }

  Future<void> _onUpdatePlaylistProfile(
    UpdateProfileEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());

    DateTime? expiration = event.existing.expirationDate;
    try {
      expiration = await XtreamApiHelper.checkExpiration(event.url);
    } catch (e) {
      _log.warn('No se pudo verificar caducidad (update): $e');
    }

    final updated = event.existing.copyWith(
      name: event.name,
      url: event.url,
      userId: event.username,
      expirationDate: expiration,
    );

    final result = await updatePlaylistProfile(updated);
    result.fold(
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (_) => add(LoadPlaylistProfiles()),
    );
  }

  Future<void> _onDeletePlaylistProfile(
    DeleteProfileEvent event,
    Emitter<PlaylistProfileState> emit,
  ) async {
    emit(PlaylistProfileLoading());
    final result = await deletePlaylistProfile(event.id);
    result.fold(
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (_) => add(LoadPlaylistProfiles()),
    );
  }

  String _mapFailureToMessage(dynamic failure) {
    if (failure is Failure) return failure.message;
    return "Error inesperado en la base de datos";
  }
}