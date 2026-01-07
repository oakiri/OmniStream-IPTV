import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';

import 'package:omnistream_iptv/core/usecases/no_params.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';

class GetPlaylistProfiles implements UseCase<List<PlaylistProfile>, NoParams> {
  final PlaylistProfileRepository repository;

  GetPlaylistProfiles(this.repository);

  @override
  Future<Either<Failure, List<PlaylistProfile>>> call(NoParams params) async {
    return await repository.getPlaylistProfiles();
  }
}
