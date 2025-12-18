import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';
import '../models/music_model.dart';
import '../services/realtime_db_service.dart';
import '../services/storage_service.dart';

class PostRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final StorageService _storageService = StorageService();
  
  // Cache streams để tránh tạo lại mỗi lần
  final Map<String, Stream<List<PostModel>>> _userPostsStreams = {};

  Stream<List<PostModel>> streamPosts() {
    final postsRef = _dbService.postsRef();
    
    return postsRef
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <PostModel>[];
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      
      final List<PostModel> posts = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          try {
            final post = PostModel.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            );
            posts.add(post);
          } catch (e) {
            // Skip invalid posts
          }
        }
      });

      // Sort by createdAt descending (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return posts;
    });
  }

  Stream<List<PostModel>> streamUserPosts(String uid) {
    // Cache stream theo uid để tránh tạo lại
    if (!_userPostsStreams.containsKey(uid)) {
      final postsRef = _dbService.postsRef();
      
      _userPostsStreams[uid] = postsRef
          .orderByChild('uid')
          .equalTo(uid)
          .onValue
          .asBroadcastStream()
          .map((event) {
        if (event.snapshot.value == null) {
          return <PostModel>[];
        }

        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        
        final List<PostModel> posts = [];
        
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final post = PostModel.fromJson(
                Map<String, dynamic>.from(value),
                key.toString(),
              );
              posts.add(post);
            } catch (e) {
              // Skip invalid posts
            }
          }
        });

        // Sort by createdAt descending (newest first)
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return posts;
      });
    }
    return _userPostsStreams[uid]!;
  }

  /// Tạo post từ music đã có
  Future<void> createPostFromMusic({
    required String uid,
    required String authorName,
    String? authorAvatarUrl,
    String? caption,
    required MusicModel music,
    File? postCoverFile, // Cover riêng cho post (optional)
  }) async {
    final postId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Upload cover riêng cho post nếu có
    String? coverUrl = music.coverUrl; // Mặc định dùng cover của music
    if (postCoverFile != null) {
      try {
        final coverResult = await _storageService.uploadCover(
          uid: uid,
          postId: postId,
          coverFile: postCoverFile,
        );
        coverUrl = coverResult['coverUrl'];
      } catch (e) {
        // Nếu upload cover fail, dùng cover của music
      }
    }

    // Lưu post vào DB
    final postRef = _dbService.postsRef().child(postId);
    await postRef.set({
      'uid': uid,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'caption': caption,
      'musicId': music.musicId,
      'musicTitle': music.title,
      'musicOwnerName': music.ownerName,
      'audioUrl': music.audioUrl, // Snapshot để play nhanh
      'coverUrl': coverUrl,
      'createdAt': ServerValue.timestamp,
      'commentCount': 0,
      'reactionSummary': {
        'like': 0,
        'love': 0,
        'haha': 0,
        'wow': 0,
        'sad': 0,
        'angry': 0,
      },
    });
  }

  Future<void> deletePost(PostModel post) async {
    final postId = post.postId;
    
    // 1. Xóa comments
    final commentsRef = _dbService.commentsRef(postId);
    await commentsRef.remove();
    
    // 2. Xóa reactions
    final reactionsRef = _dbService.reactionsRef(postId);
    await reactionsRef.remove();
    
    // 3. Xóa post
    final postsRef = _dbService.postsRef();
    await postsRef.child(postId).remove();
    
    // Lưu ý: KHÔNG xóa audio/cover files vì post chỉ tham chiếu music
    // Nếu cần xóa nhạc thì xóa ở musics/ node
  }
}
