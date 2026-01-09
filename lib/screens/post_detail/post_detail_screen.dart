import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/audio_player_provider.dart';
import '../../repositories/comment_repository.dart';
import '../../repositories/like_repository.dart';
import '../../repositories/post_repository.dart';
import '../../services/realtime_db_service.dart';
import '../../models/user_model.dart';
import '../../widgets/seekbar.dart';
import '../profile/user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostRepository _postRepository = PostRepository();
  final LikeRepository _likeRepository = LikeRepository();
  final CommentRepository _commentRepository = CommentRepository();
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  
  final TextEditingController _commentController = TextEditingController();
  bool _isLoadingComment = false;
  bool _isReacting = false;
  bool _isDeleting = false;
  Timer? _debounceTimer;

  PostModel? _currentPost;
  bool _isLiked = false;

  // Stream subscriptions
  StreamSubscription<bool>? _myLikeSubscription;
  StreamSubscription<DatabaseEvent>? _postUpdateSubscription;

  // Cached streams
  Stream<bool>? _myLikeStream;
  Stream<List<CommentModel>>? _commentsStream;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    
    // Cache comments stream
    _commentsStream = _commentRepository.streamComments(_currentPost!.postId);
    
    _initAudio();
    _loadMyLike();
    _listenToPostUpdates();
  }

  void _initAudio() {
    // Sử dụng AudioPlayerProvider để phát nhạc
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.playPost(_currentPost!);
  }

  Stream<bool>? _getMyLikeStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentPost == null) return null;
    
    _myLikeStream ??= _likeRepository.streamUserLike(_currentPost!.postId, user.uid);
    return _myLikeStream;
  }

  void _loadMyLike() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentPost != null) {
      _myLikeStream ??= _likeRepository.streamUserLike(_currentPost!.postId, user.uid);
      
      _myLikeSubscription = _myLikeStream!.listen((isLiked) {
        if (mounted) {
          setState(() {
            _isLiked = isLiked;
          });
        }
      });
    }
  }

  void _listenToPostUpdates() {
    _postUpdateSubscription = _dbService.postsRef().child(_currentPost!.postId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _currentPost = PostModel.fromJson(data, _currentPost!.postId);
          });
        } catch (e) {
          // Ignore parse errors
        }
      }
    });
  }


  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _showReactionBottomSheet() async {
    if (_isReacting) return;
    
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    final selectedType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn cảm xúc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReactionButton('like', '👍', context),
                _buildReactionButton('love', '❤️', context),
                _buildReactionButton('haha', '😂', context),
                _buildReactionButton('wow', '😮', context),
                _buildReactionButton('sad', '😢', context),
                _buildReactionButton('angry', '😠', context),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Bỏ chọn'),
            ),
          ],
        ),
      ),
    );

    if (selectedType != null && mounted) {
      // Debounce
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        setState(() {
          _isReacting = true;
        });

        try {
          if (_currentPost != null) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await _likeRepository.togglePostLike(
                postId: _currentPost!.postId,
                uid: user.uid,
              );
            }
          }
        } catch (e) {
          debugPrint('Error toggling like: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${e.toString()}')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isReacting = false;
            });
          }
        }
      });
    }
  }

  Widget _buildReactionButton(String type, String emoji, BuildContext context) {
    final isSelected = _isLiked;
    return GestureDetector(
      onTap: () => Navigator.pop(context, type),
      child: Container(
        padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.withValues(alpha: 0.2) : null,
                                shape: BoxShape.circle,
                              ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  Future<void> _handleDeletePost() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null || _currentPost == null || _currentPost!.uid != user.uid) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài đăng?'),
        content: const Text('Bạn có chắc chắn muốn xóa bài đăng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _postRepository.deletePost(_currentPost!);
      
      if (mounted) {
        Navigator.pop(context); // Quay về màn hình trước
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài đăng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa bài đăng: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty || _isLoadingComment) {
      return;
    }

    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() {
      _isLoadingComment = true;
    });

    try {
      // Get user info
      final userRef = _dbService.usersRef().child(user.uid);
      final snapshot = await userRef.get();
      String authorName = user.displayName ?? 'Unknown';
      String? authorAvatarUrl;
      
      if (snapshot.exists && snapshot.value != null) {
        final userData = UserModel.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
        authorName = userData.displayName;
        authorAvatarUrl = userData.avatarUrl;
      }

      await _commentRepository.addComment(
        postId: _currentPost!.postId,
        uid: user.uid,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        content: _commentController.text.trim(),
      );

      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm bình luận: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingComment = false;
        });
      }
    }
  }


  @override
  void dispose() {
    // Cancel all subscriptions
    _myLikeSubscription?.cancel();
    _postUpdateSubscription?.cancel();
    
    _commentController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPost == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.user;
    final isOwner = user != null && _currentPost!.uid == user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài đăng'),
        actions: isOwner
            ? [
                if (_isDeleting)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _isDeleting ? null : _handleDeletePost,
                  ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info (clickable để mở profile)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: _currentPost!.uid),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _currentPost!.authorAvatarUrl != null
                              ? NetworkImage(_currentPost!.authorAvatarUrl!)
                              : null,
                          child: _currentPost!.authorAvatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _currentPost!.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title - dùng musicTitle
                  Text(
                    _currentPost!.musicTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Thông tin nhạc và thời gian
                  Row(
                    children: [
                      Chip(
                        label: Text('Nhạc: ${_currentPost!.musicOwnerName}'),
                        avatar: const Icon(Icons.music_note, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(_currentPost!.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Caption
                  if (_currentPost!.caption != null && _currentPost!.caption!.isNotEmpty) ...[
                    Text(
                      _currentPost!.caption!,
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Cover image
                  if (_currentPost!.coverUrl != null) ...[
                    Image.network(
                      _currentPost!.coverUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[800],
                          child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Audio player với SeekBar
                  Consumer<AudioPlayerProvider>(
                    builder: (context, audioProvider, child) {
                      final isCurrentPost = audioProvider.currentPost?.postId == _currentPost?.postId;
                      final currentPosition = isCurrentPost ? audioProvider.position : Duration.zero;
                      final currentDuration = isCurrentPost ? audioProvider.duration : Duration.zero;
                      
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Controls: Rewind, Play/Pause, Forward
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Rewind 10s button
                                  IconButton(
                                    icon: const Icon(Icons.replay_10, size: 32),
                                    onPressed: isCurrentPost && currentDuration.inMilliseconds > 0
                                        ? () {
                                            audioProvider.seekBackward();
                                          }
                                        : null,
                                    tooltip: 'Tua ngược 10 giây',
                                  ),
                                  const SizedBox(width: 16),
                                  // Play/Pause button
                                  IconButton(
                                    icon: Icon(
                                      isCurrentPost && audioProvider.isPlaying
                                          ? Icons.pause_circle
                                          : Icons.play_circle,
                                      size: 56,
                                    ),
                                    onPressed: () {
                                      if (isCurrentPost) {
                                        audioProvider.togglePlayPause();
                                      } else {
                                        audioProvider.playPost(_currentPost!);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  // Forward 10s button
                                  IconButton(
                                    icon: const Icon(Icons.forward_10, size: 32),
                                    onPressed: isCurrentPost && currentDuration.inMilliseconds > 0
                                        ? () {
                                            audioProvider.seekForward();
                                          }
                                        : null,
                                    tooltip: 'Tua đi 10 giây',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // SeekBar
                              SeekBar(
                                position: currentPosition,
                                duration: currentDuration,
                                onSeek: (position) {
                                  audioProvider.seekTo(position);
                                },
                                compact: false,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Reactions
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showReactionBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[700]!),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentPost!.likesCount}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Comments section
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Bình luận (${_currentPost!.commentCount})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  StreamBuilder<List<CommentModel>>(
                    stream: _commentsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Lỗi: ${snapshot.error}');
                      }

                      final comments = snapshot.data ?? [];

                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Chưa có bình luận nào',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                backgroundImage: comment.authorAvatarUrl != null
                                    ? NetworkImage(comment.authorAvatarUrl!)
                                    : null,
                                child: comment.authorAvatarUrl == null
                                    ? Icon(Icons.person, color: Colors.grey[400])
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    comment.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimestamp(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  comment.content,
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Viết bình luận...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoadingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoadingComment ? null : _handleAddComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
