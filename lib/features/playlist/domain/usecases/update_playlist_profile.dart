import 'package:dartz/dartz.dart';

import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';

class UpdatePlaylistProfile implements UseCase<void, PlaylistProfile> {
  final PlaylistProfileRepository repository;

  UpdatePlaylistProfile(this.repository);

  @override
  Future<Either<Failure, void>> call(PlaylistProfile params) async {
    return repository.updatePlaylistProfile(params);
  }
}
