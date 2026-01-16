import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/playlist_profile_model.dart';

abstract class PlaylistProfileRemoteDataSource {
  Future<List<PlaylistProfileModel>> getPlaylistProfiles(String userId);

  // API "nueva"
  Future<void> addPlaylistProfile(String userId, PlaylistProfileModel profile);
  Future<void> deletePlaylistProfile(String userId, String profileId);

  // Compatibilidad con código que llame a "saveProfile/deleteProfile"
  Future<void> saveProfile(String userId, PlaylistProfileModel profile);
  Future<void> deleteProfile(String userId, String profileId);
}

class PlaylistProfileRemoteDataSourceImpl
    implements PlaylistProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  PlaylistProfileRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> _col(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('playlist_profiles');
  }

  @override
  Future<List<PlaylistProfileModel>> getPlaylistProfiles(String userId) async {
    final snap = await _col(userId).get();
    return snap.docs
        .map((d) => PlaylistProfileModel.fromJson(d.data()))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  @override
  Future<void> addPlaylistProfile(
      String userId, PlaylistProfileModel profile) async {
    await _col(userId).doc(profile.id).set(profile.toJson());
  }

  @override
  Future<void> deletePlaylistProfile(String userId, String profileId) async {
    await _col(userId).doc(profileId).delete();
  }

  // ---- Compat ----
  @override
  Future<void> saveProfile(String userId, PlaylistProfileModel profile) =>
      addPlaylistProfile(userId, profile);

  @override
  Future<void> deleteProfile(String userId, String profileId) =>
      deletePlaylistProfile(userId, profileId);
}
