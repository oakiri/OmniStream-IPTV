import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/channel.dart'; // O channel_old.dart según uses, pero debe ser consistente
import '../../domain/repositories/channel_repository.dart';
import '../datasources/channel_remote_data_source.dart';
import '../datasources/firebase_channel_data_source.dart';
import '../../../playlist/data/models/channel_model.dart';
// Asegúrate de importar tu M3uParser si lo usas aquí dentro para parsear el string del remoteDataSource
import '../../../../core/utils/m3u_parser.dart'; 

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource remoteDataSource;
  final FirebaseChannelDataSource firebaseDataSource;
  final M3uParser m3uParser = M3uParser(); // Lo instanciamos aquí o lo inyectamos si prefieres

  ChannelRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseDataSource,
  });

  @override
  Future<Either<Failure, List<Channel>>> getChannels(String playlistUrl) async {
    try {
      // 1. Intentar obtener de la red
      final String m3uContent = await remoteDataSource.getM3UContent(playlistUrl);
      
      // 2. Parsear
      final List<Channel> channels = await m3uParser.parse(m3uContent);
      
      // 3. (Opcional) Sincronizar con Firebase si es necesario
      // Aquí podrías convertir a Model y guardar, pero por ahora devolvemos la lista
      
      return Right(channels);
    } on ServerException {
      return const Left(ServerFailure(message: 'Error al conectar con el servidor'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}