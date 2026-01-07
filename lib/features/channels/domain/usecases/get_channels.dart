import 'package:dartz/dartz.dart';
import 'package:omnistream_iptv/core/errors/failures.dart';
import 'package:omnistream_iptv/core/usecases/usecase.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/domain/repositories/channel_repository.dart';

class GetChannels implements UseCase<List<Channel>, String> {
  final ChannelRepository repository;

  GetChannels(this.repository);

  @override
  Future<Either<Failure, List<Channel>>> call(String params) async {
    return await repository.getChannels(params);
  }
}
