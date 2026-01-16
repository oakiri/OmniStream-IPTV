import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/error/failure.dart'; // <--- CORREGIDO
import 'package:omnistream_iptv/core/usecases/usecase.dart';
// Usamos la entidad de playlist
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';

class GetChannels implements UseCase<List<Channel>, String> {
  final ChannelRepository repository;

  GetChannels(this.repository);

  @override
  Future<Either<Failure, List<Channel>>> call(String params) async {
    return await repository.getChannels(params);
  }
}
