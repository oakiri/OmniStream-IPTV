import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart'; // CORREGIDO: errors (plural)
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';
import 'package:omnistream_iptv/core/usecases/no_params.dart';

class GetPlaylistProfiles implements UseCase<List<PlaylistProfile>, NoParams> {
  final PlaylistProfileRepository repository;

  GetPlaylistProfiles(this.repository);

  @override
  Future<Either<Failure, List<PlaylistProfile>>> call(NoParams params) async {
    // CORREGIDO: El método del repo se llama getPlaylistProfiles
    return await repository.getPlaylistProfiles();
  }
}