import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../repositories/like_repository.dart';

/// Controller to handle feed item interactions (like, save)
class FeedInteractionController {
  final LikeRepository _likeRepository = LikeRepository();

  /// Toggle like for a post
  Future<void> togglePostLike(String postId, String uid) async {
    await _likeRepository.togglePostLike(postId: postId, uid: uid);
  }

  /// Check if user has saved this music
  Future<bool> checkIfMusicSaved(String musicId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('saved/${user.uid}/$musicId')
          .get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Toggle save/unsave music
  Future<void> toggleMusicSave({
    required String musicId,
    required String musicTitle,
    required String ownerName,
    String? coverUrl,
    bool currentlySaved = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    if (currentlySaved) {
      await FirebaseDatabase.instance
          .ref('saved/${user.uid}/$musicId')
          .remove();
    } else {
      await FirebaseDatabase.instance
          .ref('saved/${user.uid}/$musicId')
          .set({
        'userId': user.uid,
        'title': musicTitle,
        'ownerName': ownerName,
        'coverUrl': coverUrl,
        'createdAt': ServerValue.timestamp,
      });
    }
  }
}
