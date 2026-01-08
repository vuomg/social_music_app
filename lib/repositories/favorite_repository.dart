import 'package:firebase_database/firebase_database.dart';
import '../models/favorite_model.dart';
import '../models/music_model.dart';
import '../models/post_model.dart';

/// Repository cho các bài hát đã Lưu (Saved)
class FavoriteRepository {

  DatabaseReference _savedRef(String userId) {
    return FirebaseDatabase.instance.ref('saved/$userId');
  }

  /// Thêm vào danh sách Lưu (Dùng thông tin từ PostModel)
  Future<void> saveFromPost(String userId, PostModel post) async {
    await _savedRef(userId).child(post.musicId).set({
      'userId': userId,
      'title': post.musicTitle,
      'ownerName': post.musicOwnerName,
      'coverUrl': post.coverUrl,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Thêm vào danh sách Lưu (Dùng thông tin từ MusicModel)
  Future<void> saveFromMusic(String userId, MusicModel music) async {
    await _savedRef(userId).child(music.musicId).set({
      'userId': userId,
      'title': music.title,
      'ownerName': music.ownerName,
      'coverUrl': music.coverUrl,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Xóa khỏi danh sách Lưu
  Future<void> removeFavorite(String userId, String musicId) async {
    await _savedRef(userId).child(musicId).remove();
  }

  /// Kiểm tra đã lưu chưa
  Future<bool> isFavorite(String userId, String musicId) async {
    final snapshot = await _savedRef(userId).child(musicId).get();
    return snapshot.exists;
  }

  /// Stream danh sách các bài hát đã lưu
  Stream<List<FavoriteModel>> streamFavorites(String userId) {
    return _savedRef(userId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <FavoriteModel>[];
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<FavoriteModel> favorites = [];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            favorites.add(FavoriteModel.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            ));
          } catch (e) {
            // Skip invalid data
          }
        }
      });

      // Sắp xếp mới nhất lên đầu
      favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return favorites;
    });
  }
}
