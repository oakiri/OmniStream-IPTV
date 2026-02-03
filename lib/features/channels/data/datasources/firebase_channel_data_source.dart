import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/core/errors/exceptions.dart';

abstract class FirebaseChannelDataSource {
  Future<void> syncChannels(String playlistId, List<ChannelModel> channels);
  Future<List<ChannelModel>> getChannels(String playlistId);
}

class FirebaseChannelDataSourceImpl implements FirebaseChannelDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FirebaseChannelDataSourceImpl({required this.firestore, required this.auth});

  @override
  Future<void> syncChannels(String playlistId, List<ChannelModel> channels) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException();

    final batch = firestore.batch();
    final collection = firestore
        .collection('users')
        .doc(user.uid)
        .collection('playlists')
        .doc(playlistId)
        .collection('channels');

    // Limitamos a 450 para no pasarnos del límite de batch de Firestore (500)
    for (var channel in channels.take(450)) {
      final docRef = collection.doc(channel.id);
      // AHORA SÍ funcionará porque hemos añadido el método toJson() al modelo
      batch.set(docRef, channel.toJson());
    }
    await batch.commit();
  }

  @override
  Future<List<ChannelModel>> getChannels(String playlistId) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException();

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('playlists')
        .doc(playlistId)
        .collection('channels')
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      // AHORA SÍ funcionará porque hemos añadido el método fromJson() al modelo
      return ChannelModel.fromJson(doc.data());
    }).toList();
  }
}