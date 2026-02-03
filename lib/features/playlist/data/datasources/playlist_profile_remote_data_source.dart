import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnistream_iptv/features/playlist/data/models/playlist_profile_model.dart';

abstract class PlaylistProfileRemoteDataSource {
  Future<void> addPlaylistProfile(String userId, PlaylistProfileModel profile);
  Future<void> deletePlaylistProfile(String userId, String id);
  Future<List<PlaylistProfileModel>> getPlaylistProfiles(String userId);
}

class PlaylistProfileRemoteDataSourceImpl implements PlaylistProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  PlaylistProfileRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> addPlaylistProfile(String userId, PlaylistProfileModel profile) async {
    // Usamos la misma estructura que en Channels: users/{uid}/profiles
    await firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profile.id)
        .set(profile.toJson());
  }

  @override
  Future<void> deletePlaylistProfile(String userId, String id) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(id)
        .delete();
  }

  @override
  Future<List<PlaylistProfileModel>> getPlaylistProfiles(String userId) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .get();

    return snapshot.docs
        .map((doc) => PlaylistProfileModel.fromJson(doc.data()))
        .toList();
  }
}