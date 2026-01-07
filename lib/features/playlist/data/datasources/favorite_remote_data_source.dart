import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnistream_iptv/features/playlist/data/models/favorite_channel_model.dart';

abstract class FavoriteRemoteDataSource {
  Future<void> addFavorite(String userId, FavoriteChannelModel favorite);
  Future<void> removeFavorite(String userId, String channelId);
  Future<List<FavoriteChannelModel>> getFavorites(String userId);
}

class FavoriteRemoteDataSourceImpl implements FavoriteRemoteDataSource {
  final FirebaseFirestore firestore;

  FavoriteRemoteDataSourceImpl({required this.firestore});

  // Collection structure: users_favorites/{userId}/favorites/{channelId}
  CollectionReference _favoritesCollection(String userId) {
    return firestore
        .collection('users_favorites')
        .doc(userId)
        .collection('favorites');
  }

  @override
  Future<void> addFavorite(String userId, FavoriteChannelModel favorite) {
    return _favoritesCollection(userId).doc(favorite.id).set(favorite.toJson());
  }

  @override
  Future<void> removeFavorite(String userId, String channelId) {
    return _favoritesCollection(userId).doc(channelId).delete();
  }

  @override
  Future<List<FavoriteChannelModel>> getFavorites(String userId) async {
    final snapshot = await _favoritesCollection(userId).get();
    return snapshot.docs
        .map((doc) => FavoriteChannelModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
