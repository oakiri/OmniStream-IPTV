import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/features/playlist/data/models/channel_model.dart';
import 'package:omnistream_iptv/core/errors/exceptions.dart';

abstract class FirebaseChannelDataSource {
  Future<void> syncChannels(String playlistId, List<ChannelModel> channels);
  Future<List<ChannelModel>> getChannels(String playlistId); // AÑADIDO
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

    for (var channel in channels) {
      final docRef = collection.doc(channel.id);
      batch.set(docRef, {
        'id': channel.id,
        'name': channel.name,
        'logoUrl': channel.logoUrl,
        'url': channel.url,
        'group': channel.group,
      });
    }
    await batch.commit();
  }

  @override
  Future<List<ChannelModel>> getChannels(String playlistId) async {
     // Implementación básica para que compile
     return [];
  }
}