import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

abstract class FirebaseChannelDataSource {
  Future<void> syncChannels(String playlistId, List<Channel> channels);
  Future<List<Channel>> getChannelsPaginated(String playlistId, {int limit = 50, DocumentSnapshot? lastDocument});
  Future<List<String>> getCategories(String playlistId);
}

class FirebaseChannelDataSourceImpl implements FirebaseChannelDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FirebaseChannelDataSourceImpl({required this.firestore, required this.auth});

  String get _userId => auth.currentUser?.uid ?? 'anonymous';

  @override
  Future<void> syncChannels(String playlistId, List<Channel> channels) async {
    final batch = firestore.batch();
    final playlistRef = firestore.collection('users').doc(_userId).collection('playlists').doc(playlistId);
    
    // Guardar canales en subcolección
    for (var channel in channels) {
      final channelRef = playlistRef.collection('channels').doc();
      batch.set(channelRef, {
        'id': channel.id,
        'name': channel.name,
        'url': channel.url,
        'logoUrl': channel.logoUrl,
        'group': channel.group,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Guardar categorías únicas
    final categories = channels.map((e) => e.group ?? 'Otros').toSet().toList();
    batch.set(playlistRef, {'categories': categories}, SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Future<List<Channel>> getChannelsPaginated(String playlistId, {int limit = 50, DocumentSnapshot? lastDocument}) async {
    var query = firestore
        .collection('users')
        .doc(_userId)
        .collection('playlists')
        .doc(playlistId)
        .collection('channels')
        .orderBy('name')
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Channel(
        id: data['id'] ?? doc.id,
        name: data['name'] ?? '',
        url: data['url'] ?? '',
        logoUrl: data['logoUrl'],
        group: data['group'],
      );
    }).toList();
  }

  @override
  Future<List<String>> getCategories(String playlistId) async {
    final doc = await firestore
        .collection('users')
        .doc(_userId)
        .collection('playlists')
        .doc(playlistId)
        .get();
    
    final data = doc.data();
    if (data != null && data['categories'] != null) {
      return List<String>.from(data['categories']);
    }
    return [];
  }
}
