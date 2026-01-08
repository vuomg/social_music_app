import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../providers/audio_player_provider.dart';
import '../repositories/reaction_repository.dart';
import '../screens/post_detail/post_detail_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import 'favorite_button.dart';
import 'send_music_sheet.dart';

/// Widget card hiển thị bài đăng nhạc với nút tim tương tác ở ngoài
class MusicPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const MusicPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  State<MusicPostCard> createState() => _MusicPostCardState();
}

class _MusicPostCardState extends State<MusicPostCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _myReactionType;
  final ReactionRepository _reactionRepository = ReactionRepository();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadMyReaction();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadMyReaction() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _reactionRepository.streamMyReaction(widget.post.postId, user.uid).listen((reactionType) {
        if (mounted) {
          setState(() {
            _myReactionType = reactionType;
          });
        }
      });
    }
  }

  void _handleLike() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _myReactionType = _myReactionType == null ? 'like' : null;
    });
    _animationController.forward(from: 0.0).then((_) {
      _animationController.reverse();
    });

    _reactionRepository.setReaction(
      postId: widget.post.postId,
      uid: user.uid,
      newType: _myReactionType,
    );
  }

  Future<void> _showReactionPicker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    final selectedType = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn cảm xúc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(child: _buildReactionButton('like', '👍', context)),
                  Flexible(child: _buildReactionButton('love', '❤️', context)),
                  Flexible(child: _buildReactionButton('haha', '😂', context)),
                  Flexible(child: _buildReactionButton('wow', '😮', context)),
                  Flexible(child: _buildReactionButton('sad', '😢', context)),
                  Flexible(child: _buildReactionButton('angry', '😠', context)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'Bỏ chọn',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selectedType != null && mounted) {
      setState(() {
        _myReactionType = selectedType == _myReactionType ? null : selectedType;
      });
      _animationController.forward(from: 0.0).then((_) {
        _animationController.reverse();
      });

      _reactionRepository.setReaction(
        postId: widget.post.postId,
        uid: user.uid,
        newType: _myReactionType,
      );
    }
  }

  Widget _buildReactionButton(String type, String emoji, BuildContext context) {
    final isSelected = _myReactionType == type;
    return GestureDetector(
      onTap: () => Navigator.pop(context, type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.grey[800],
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  /// Tính tổng reactions từ reactionSummary
  int get _totalReactions {
    return widget.post.reactionSummary.values.fold(0, (sum, count) => sum + count);
  }

  /// Format timestamp thành relative time
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
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

  /// Lấy emoji theo reaction type
  String _getReactionEmoji(String? reactionType) {
    switch (reactionType) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _myReactionType != null;
    final reactionEmoji = _getReactionEmoji(_myReactionType);
    
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: widget.onTap ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: widget.post),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A) Header: Avatar + Name + Subtitle + More
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // CircleAvatar (clickable để mở profile)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: widget.post.uid),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[700],
                          backgroundImage: widget.post.authorAvatarUrl != null
                              ? NetworkImage(widget.post.authorAvatarUrl!)
                              : null,
                          child: widget.post.authorAvatarUrl == null
                              ? Icon(Icons.person, color: Colors.grey[400])
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Author name và subtitle
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(userId: widget.post.uid),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author name (bold) - người đăng post
                              Text(
                                widget.post.authorName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(height: 2),
                            // Subtitle: genre • timeAgo
                            Text(
                              '${_formatTimestamp(widget.post.createdAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                          ),
                        ),
                      ),
                      // More button
                      IconButton(
                        icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // B) Content: Title + Caption
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (font 18 bold, maxLines 2) - dùng musicTitle
                      Text(
                        widget.post.musicTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Caption (màu xám, maxLines 2, optional)
                      if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.post.caption!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // C) Cover + play overlay
                Stack(
                  children: [
                    // Cover image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: widget.post.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.post.coverUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.grey[400],
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                    // Overlay nút play/pause tròn ở giữa
                    Positioned.fill(
                      child: Center(
                        child: Consumer<AudioPlayerProvider>(
                          builder: (context, audioProvider, child) {
                            final isCurrentPost = audioProvider.currentPost?.postId == widget.post.postId;
                            final isPlaying = isCurrentPost && audioProvider.isPlaying;
                            
                            return InkWell(
                              onTap: () async {
                                if (isCurrentPost) {
                                  audioProvider.togglePlayPause();
                                } else {
                                  audioProvider.playPost(widget.post);
                                }
                              },
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Góc trái dưới: pill text
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Consumer<AudioPlayerProvider>(
                        builder: (context, audioProvider, child) {
                          final isCurrentPost = audioProvider.currentPost?.postId == widget.post.postId;
                          final isPlaying = isCurrentPost && audioProvider.isPlaying;
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isPlaying ? 'Đang phát' : 'Nhấn để nghe',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Góc phải dưới: nút thêm vào yêu thích
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: FavoriteButton(
                          post: widget.post,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // D) Stats: reactionTotal + commentCount
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      // Total reactions
                      const Icon(
                        Icons.favorite,
                        color: Colors.pink,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_totalReactions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Total comments
                      Icon(
                        Icons.comment_outlined,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.post.commentCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // E) Actions: Reaction, Comment, Share
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      // Reaction button (tap để like/unlike, long press để chọn cảm xúc)
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleLike,
                          onLongPress: _showReactionPicker,
                          child: TextButton.icon(
                            onPressed: _handleLike,
                            icon: isLiked && reactionEmoji.isNotEmpty
                                ? Text(
                                    reactionEmoji,
                                    style: const TextStyle(fontSize: 20),
                                  )
                                : Icon(
                                    Icons.favorite_border,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                            label: Text(
                              isLiked ? 'Đã thích' : 'Like',
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Comment button
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(post: widget.post),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.comment_outlined,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          label: Text(
                            'Comment',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Share button
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            _showShareDialog(context);
                          },
                          icon: Icon(
                            Icons.share_outlined,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          label: Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Nút tim floating ở góc phải trên (ngoài card) - tap để like, long press để chọn cảm xúc
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: _handleLike,
            onLongPress: _showReactionPicker,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animationController.value * 0.3),
                  child: Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLiked && reactionEmoji.isNotEmpty
                          ? Text(
                              reactionEmoji,
                              style: const TextStyle(fontSize: 26),
                            )
                          : Icon(
                              Icons.favorite_border,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showShareDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Chia sẻ bài nhạc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.send_rounded, color: Colors.blue),
                    title: const Text('Gửi cho bạn bè trong app'),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => SendMusicSheet(post: widget.post),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.link, color: Colors.grey),
                    title: const Text('Sao chép liên kết'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép liên kết'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

