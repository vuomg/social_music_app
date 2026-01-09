import 'package:firebase_database/firebase_database.dart';
import '../services/realtime_db_service.dart';

class LikeRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Toggle like on a post (simple heart only)
  Future<void> togglePostLike({
    required String postId,
    required String uid,
  }) async {
    final userLikeRef = _db
        .child('postLikes')
        .child(postId)
        .child(uid);

    final snapshot = await userLikeRef.get();

    if (snapshot.exists) {
      // Unlike
      await userLikeRef.remove();
      await _decrementLikesCount(postId);
    } else {
      // Like
      await userLikeRef.set(true);
      await _incrementLikesCount(postId);
    }
  }

  Future<void> _incrementLikesCount(String postId) async {
    final likesCountRef = _dbService.postsRef()
        .child(postId)
        .child('likesCount');

    await likesCountRef.runTransaction((currentValue) {
      final current = (currentValue as num?)?.toInt() ?? 0;
      return Transaction.success(current + 1);
    });
  }

  Future<void> _decrementLikesCount(String postId) async {
    final likesCountRef = _dbService.postsRef()
        .child(postId)
        .child('likesCount');

    await likesCountRef.runTransaction((currentValue) {
      final current = (currentValue as num?)?.toInt() ?? 0;
      return Transaction.success(current > 0 ? current - 1 : 0);
    });
  }

  /// Check if user has liked a post
  Future<bool> hasUserLiked(String postId, String uid) async {
    final snapshot = await _db
        .child('postLikes')
        .child(postId)
        .child(uid)
        .get();

    return snapshot.exists;
  }

  /// Stream user's like status
  Stream<bool> streamUserLike(String postId, String uid) {
    return _db
        .child('postLikes')
        .child(postId)
        .child(uid)
        .onValue
        .map((event) => event.snapshot.exists);
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final userLikeRef = _db
        .child('commentLikes')
        .child(commentId)
        .child(uid);

    final snapshot = await userLikeRef.get();

    if (snapshot.exists) {
      // Unlike
      await userLikeRef.remove();
      await _decrementCommentLikesCount(postId, commentId);
    } else {
      // Like
      await userLikeRef.set(true);
      await _incrementCommentLikesCount(postId, commentId);
    }
  }

  Future<void> _incrementCommentLikesCount(String postId, String commentId) async {
    final likesCountRef = _db
        .child('comments')
        .child(postId)
        .child(commentId)
        .child('likesCount');

    await likesCountRef.runTransaction((currentValue) {
      final current = (currentValue as num?)?.toInt() ?? 0;
      return Transaction.success(current + 1);
    });
  }

  Future<void> _decrementCommentLikesCount(String postId, String commentId) async {
    final likesCountRef = _db
        .child('comments')
        .child(postId)
        .child(commentId)
        .child('likesCount');

    await likesCountRef.runTransaction((currentValue) {
      final current = (currentValue as num?)?.toInt() ?? 0;
      return Transaction.success(current > 0 ? current - 1 : 0);
    });
  }
}
