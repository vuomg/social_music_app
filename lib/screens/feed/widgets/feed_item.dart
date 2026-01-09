import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../../../providers/audio_player_provider.dart';
import '../../../repositories/comment_repository.dart';
import '../../../repositories/like_repository.dart';

/// TikTok-style Feed Item with fullscreen immersive UI
class FeedItem extends StatefulWidget {
  final PostModel post;
  final bool isActive;

  const FeedItem({
    super.key,
    required this.post,
    this.isActive = false,
  });

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  bool _isLiked = false;
  int _likeCount = 0;
  final CommentRepository _commentRepository = CommentRepository();
  final LikeRepository _likeRepository = LikeRepository();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likesCount;
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadInitialLikeState();
  }

  Future<void> _loadInitialLikeState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final isLiked = await _likeRepository.hasUserLiked(
        widget.post.postId,
        currentUser.uid,
      );
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      debugPrint('Error loading like state: $e');
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    
    if (audioProvider.currentPost?.postId == widget.post.postId) {
      if (audioProvider.isPlaying) {
        audioProvider.stop();
      } else {
        audioProvider.playPost(widget.post);
      }
    } else {
      audioProvider.playPost(widget.post);
    }
  }

  void _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Optimistic update
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Animation
    if (_isLiked) {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }

    try {
      // Toggle like in Firebase
      await _likeRepository.togglePostLike(
        postId: widget.post.postId,
        uid: currentUser.uid,
      );
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
      }
    }
  }

  Future<bool> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('saved/${user.uid}/${widget.post.musicId}')
          .get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleSave(bool currentlySaved) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để lưu')),
        );
      }
      return;
    }

    try {
      if (currentlySaved) {
        await FirebaseDatabase.instance
            .ref('saved/${user.uid}/${widget.post.musicId}')
            .remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Đã bỏ lưu'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        await FirebaseDatabase.instance
            .ref('saved/${user.uid}/${widget.post.musicId}')
            .set({
          'userId': user.uid,
          'title': widget.post.musicTitle,
          'ownerName': widget.post.musicOwnerName,
          'coverUrl': widget.post.coverUrl,
          'createdAt': ServerValue.timestamp,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã lưu'), duration: Duration(seconds: 1)),
          );
        }
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chia sẻ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text('Sao chép liên kết', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Chia sẻ qua...', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(),
        _buildGradients(),
        _buildRightActions(),
        _buildBottomInfo(),
      ],
    );
  }

  Widget _buildBackground() {
    return widget.post.coverUrl != null
        ? CachedNetworkImage(
            imageUrl: widget.post.coverUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.music_note, size: 80, color: Colors.grey),
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900,
                  Colors.deepPurple.shade900,
                  Colors.black,
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.music_note, size: 100, color: Colors.white30),
            ),
          );
  }

  Widget _buildGradients() {
    return Column(
      children: [
        // Top gradient
        Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom gradient
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      right: 12,
      bottom: 100,
      child: Column(
        children: [
          // Author avatar
          _buildActionButton(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: widget.post.authorAvatarUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(widget.post.authorAvatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: widget.post.authorAvatarUrl == null ? Colors.grey : null,
              ),
              child: widget.post.authorAvatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            onTap: () {},
          ),
          
          const SizedBox(height: 20),
          
          // Like button (simple tap only)
          _buildActionButton(
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                CurvedAnimation(
                  parent: _likeAnimationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white,
                size: 28,
              ),
            ),
            label: _formatCount(_likeCount),
            onTap: _toggleLike,
          ),
          
          const SizedBox(height: 20),
          
          // Comment button
          _buildActionButton(
            child: const Icon(Icons.comment_rounded, color: Colors.white, size: 28),
            label: _formatCount(widget.post.commentsCount),
            onTap: _showComments,
          ),
          
          const SizedBox(height: 20),
          
          // Share button
          _buildActionButton(
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 28),
            label: 'Chia sẻ',
            onTap: _showShareOptions,
          ),
          
          const SizedBox(height: 20),
          
          // Save/Bookmark button with dynamic state
          FutureBuilder<bool>(
            future: _checkIfSaved(),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;
              
              return _buildActionButton(
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.yellow : Colors.white,
                  size: 28,
                ),
                label: null,
                onTap: () => _toggleSave(isSaved),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Rotating music disc
          _buildMusicDisc(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget child,
    String? label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          child,
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMusicDisc() {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        final isCurrentPost = audioProvider.currentPost?.postId == widget.post.postId;
        final isPlaying = isCurrentPost && audioProvider.isPlaying;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isPlaying ? 360.0 : 0.0),
          duration: const Duration(seconds: 3),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 3.14159 / 180,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400,
                      Colors.pink.shade400,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author name
          Row(
            children: [
              Text(
                '@${widget.post.authorName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Text(
              widget.post.caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Music info (scrolling marquee style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.post.musicTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                Colors.black,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.comment_rounded, color: Colors.purpleAccent),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.post.commentsCount} bình luận',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: Colors.grey[800]),
              
              // Comments list with StreamBuilder
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: _commentRepository.streamComments(widget.post.postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.purpleAccent),
                      );
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 80,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có bình luận',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy là người đầu tiên bình luận!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isCurrentUser = FirebaseAuth.instance.currentUser?.uid == comment.uid;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.purple,
                                backgroundImage: comment.authorAvatarUrl != null
                                    ? CachedNetworkImageProvider(comment.authorAvatarUrl!)
                                    : null,
                                child: comment.authorAvatarUrl == null
                                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              
                              // Comment content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Author name
                                    Text(
                                      comment.authorName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Comment text
                                    Text(
                                      comment.content,
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Time ago
                                    Text(
                                      _formatTimeAgo(comment.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Delete button (if own comment)
                              if (isCurrentUser)
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.grey[600], size: 20),
                                  onPressed: () async {
                                    // Confirm before delete
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Xóa bình luận?'),
                                        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
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

                                    if (confirm == true) {
                                      await _commentRepository.deleteComment(
                                        widget.post.postId,
                                        comment.commentId,
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                    top: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.purple,
                        child: const Icon(Icons.person, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.purple.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Thêm bình luận...',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _sendComment(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.deepPurple],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _sendComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    try {
      await _commentRepository.addComment(
        postId: widget.post.postId,
        uid: currentUser.uid,
        authorName: currentUser.displayName ?? 'User',
        authorAvatarUrl: currentUser.photoURL,
        content: text,
      );

      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi bình luận'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  String _formatTimeAgo(int timestamp) {
    final now = DateTime.now();
    final commentTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(commentTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
