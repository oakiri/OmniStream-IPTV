import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/playlist_profile_repository.dart';

class DeletePlaylistProfile implements UseCase<void, String> {
  final PlaylistProfileRepository repository;

  DeletePlaylistProfile(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deletePlaylistProfile(params);
  }
}
