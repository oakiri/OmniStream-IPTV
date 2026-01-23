import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/core/usecases/no_params.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/get_playlist_profiles.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/add_playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/delete_playlist_profile.dart';
// Importa el Helper para la fecha de caducidad
import 'package:omnistream_iptv/core/utils/xtream_api_helper.dart';

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
    on<AddProfileEvent>(_onAddPlaylistProfile);
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
    
    // 1. Intentar obtener fecha de caducidad (Lógica Xtream)
    DateTime? expiration;
    try {
      // Si tienes el archivo xtream_api_helper.dart actualizado (con User-Agent), esto funcionará
      expiration = await XtreamApiHelper.checkExpiration(event.url);
    } catch (e) {
      // Si falla, no pasa nada, se guarda sin fecha
      print("Error checkExpiration: $e");
    }

    // 2. Crear el perfil con los datos recibidos
    final profile = PlaylistProfile(
      id: const Uuid().v4(),
      name: event.name,
      url: event.url,
      userId: event.username, // Guardamos el user si viene
      expirationDate: expiration,
    );

    // 3. Guardar en BD
    final result = await addPlaylistProfile(profile);

    result.fold(
      (failure) => emit(PlaylistProfileError(message: _mapFailureToMessage(failure))),
      (_) => add(LoadPlaylistProfiles()), // Recargar la lista para que aparezca
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
    return "Error inesperado";
  }
}