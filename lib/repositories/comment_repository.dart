import '../models/comment_model.dart';
import '../services/realtime_db_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class CommentRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final _uuid = const Uuid();

  Stream<List<CommentModel>> streamComments(String postId) {
    final commentsRef = _dbService.commentsRef(postId);
    
    return commentsRef
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <CommentModel>[];
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      
      final List<CommentModel> comments = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          try {
            final comment = CommentModel.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            );
            comments.add(comment);
          } catch (e) {
            // Skip invalid comments
          }
        }
      });

      // Sort by createdAt ascending (oldest first)
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return comments;
    });
  }

  Future<void> addComment({
    required String postId,
    required String uid,
    required String authorName,
    String? authorAvatarUrl,
    required String content,
  }) async {
    final commentId = _uuid.v4();
    final commentsRef = _dbService.commentsRef(postId).child(commentId);
    
    // Save comment
    await commentsRef.set({
      'uid': uid,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'createdAt': ServerValue.timestamp,
    });

    // Update commentCount using transaction
    final postRef = _dbService.postsRef().child(postId);
    await postRef.runTransaction((currentData) {
      if (currentData == null) {
        return Transaction.abort();
      }
      
      final data = Map<String, dynamic>.from(currentData as Map);
      final currentCount = (data['commentCount'] as num?)?.toInt() ?? 0;
      data['commentCount'] = currentCount + 1;
      
      return Transaction.success(data);
    });
  }
}
