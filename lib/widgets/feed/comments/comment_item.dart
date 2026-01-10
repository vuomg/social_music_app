import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/comment_model.dart';
import '../feed_utils.dart';

/// Single comment item widget
class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final bool isCurrentUser;
  final VoidCallback? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    required this.isCurrentUser,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                  FeedUtils.formatTimeAgo(comment.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Delete button (if own comment)
          if (isCurrentUser && onDelete != null)
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
                  onDelete?.call();
                }
              },
            ),
        ],
      ),
    );
  }
}
