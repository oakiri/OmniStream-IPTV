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
  Future<void> addPlaylistProfile(String userId, PlaylistProfileModel profile) {
    return firestore
        .collection('users_playlists')
        .doc(userId)
        .collection('playlists')
        .doc(profile.id)
        .set(profile.toJson());
  }

  @override
  Future<void> deletePlaylistProfile(String userId, String id) {
    return firestore
        .collection('users_playlists')
        .doc(userId)
        .collection('playlists')
        .doc(id)
        .delete();
  }

  @override
  Future<List<PlaylistProfileModel>> getPlaylistProfiles(String userId) async {
    final snapshot = await firestore
        .collection('users_playlists')
        .doc(userId)
        .collection('playlists')
        .get();
    return snapshot.docs
        .map((doc) => PlaylistProfileModel.fromJson(doc.data()))
        .toList();
  }
}
