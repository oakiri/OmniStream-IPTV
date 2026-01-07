import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/repositories/favorite_repository.dart';

class ToggleFavorite implements UseCase<void, Channel> {
  final FavoriteRepository repository;

  ToggleFavorite({required this.repository});

  @override
  Future<Either<Failure, void>> call(Channel params) async {
    return repository.toggleFavorite(params);
  }
}
