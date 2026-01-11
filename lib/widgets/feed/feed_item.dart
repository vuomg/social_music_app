import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/post_model.dart';
import '../../../widgets/feed/components/feed_background.dart';
import '../../../widgets/feed/components/feed_gradients.dart';
import '../../../widgets/feed/components/feed_action_buttons.dart';
import '../../../widgets/feed/components/feed_bottom_info.dart';
import '../../../widgets/feed/comments/comments_bottom_sheet.dart';
import '../../../repositories/like_repository.dart';
import '../../../controllers/feed_interaction_controller.dart';

/// TikTok-style Feed Item with fullscreen immersive UI
/// Refactored to ~150 lines using composition pattern
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
  
  final LikeRepository _likeRepository = LikeRepository();
  final FeedInteractionController _interactionController = FeedInteractionController();

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

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
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
      // Silently fail
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final wasLiked = _isLiked;
    
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      if (_isLiked) {
        _likeAnimationController.forward().then((_) {
          _likeAnimationController.reverse();
        });
      }
    });

    try {
      await _interactionController.togglePostLike(
        widget.post.postId,
        currentUser.uid,
      );
    } catch (e) {
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
    return await _interactionController.checkIfMusicSaved(widget.post.musicId);
  }

  Future<void> _toggleSave(bool currentlySaved) async {
    try {
      await _interactionController.toggleMusicSave(
        musicId: widget.post.musicId,
        musicTitle: widget.post.musicTitle,
        ownerName: widget.post.musicOwnerName,
        coverUrl: widget.post.coverUrl,
        currentlySaved: currentlySaved,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlySaved ? '❌ Đã bỏ lưu' : '✅ Đã lưu'),
            duration: const Duration(seconds: 1),
          ),
        );
        setState(() {}); // Refresh UI
      }
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
      builder: (context) => CommentsBottomSheet(post: widget.post),
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
        // Background (image or gradient)
        FeedBackground(coverUrl: widget.post.coverUrl),
        
        // Top and bottom gradients
        const FeedGradients(),
        
        // Right action buttons column
        FeedActionButtons(
          post: widget.post,
          onLike: _toggleLike,
          onComment: _showComments,
          onShare: _showShareOptions,
          isLiked: _isLiked,
          likeCount: _likeCount,
          likeAnimationController: _likeAnimationController,
          checkIfSaved: _checkIfSaved,
          onToggleSave: _toggleSave,
        ),
        
        // Bottom info (author, caption, music)
        FeedBottomInfo(post: widget.post),
      ],
    );
  }
}
