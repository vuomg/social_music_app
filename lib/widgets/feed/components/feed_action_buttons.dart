import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../../../models/post_model.dart';
import '../feed_utils.dart';
import 'action_button.dart';
import 'music_disc_animation.dart';

/// Premium right-side action buttons with enhanced design
class FeedActionButtons extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool isLiked;
  final int likeCount;
  final AnimationController likeAnimationController;
  final Future<bool> Function() checkIfSaved;
  final Function(bool) onToggleSave;

  const FeedActionButtons({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.isLiked,
    required this.likeCount,
    required this.likeAnimationController,
    required this.checkIfSaved,
    required this.onToggleSave,
  });

  @override
  State<FeedActionButtons> createState() => _FeedActionButtonsState();
}

class _FeedActionButtonsState extends State<FeedActionButtons> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 110,
      child: Column(
        children: [
          // Author avatar với premium border
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.pink.shade400,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  image: widget.post.authorAvatarUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(widget.post.authorAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: widget.post.authorAvatarUrl == null ? Colors.grey[800] : null,
                ),
                child: widget.post.authorAvatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Like button với glow effect
          ActionButton(
            onTap: widget.onLike,
            label: FeedUtils.formatCount(widget.likeCount),
            enableGlow: widget.isLiked,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.4).animate(
                CurvedAnimation(
                  parent: widget.likeAnimationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                color: widget.isLiked ? Colors.red.shade400 : Colors.white,
                size: 30,
                shadows: widget.isLiked
                    ? [
                        Shadow(
                          color: Colors.red.withOpacity(0.8),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 22),
          
          // Comment button
          ActionButton(
            onTap: widget.onComment,
            label: FeedUtils.formatCount(widget.post.commentsCount),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 22),
          
          // Share button
          ActionButton(
            onTap: widget.onShare,
            label: 'Share',
            child: const Icon(
              Icons.ios_share_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 22),
          
          // Save button với gradient
          FutureBuilder<bool>(
            future: widget.checkIfSaved(),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;
              
              return ActionButton(
                onTap: () => widget.onToggleSave(isSaved),
                enableGlow: isSaved,
                child: Container(
                  decoration: isSaved
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade400,
                            ],
                          ),
                        )
                      : null,
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                    color: isSaved ? Colors.white : Colors.white,
                    size: 28,
                    shadows: isSaved
                        ? [
                            Shadow(
                              color: Colors.amber.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 26),
          
          // Rotating music disc
          MusicDiscAnimation(post: widget.post),
        ],
      ),
    );
  }
}
