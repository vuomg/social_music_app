import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../../../repositories/comment_repository.dart';
import 'comment_item.dart';
import 'comment_input.dart';
import 'comments_empty_state.dart';

/// Comments bottom sheet with list and input
class CommentsBottomSheet extends StatefulWidget {
  final PostModel post;

  const CommentsBottomSheet({
    super.key,
    required this.post,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final CommentRepository _commentRepository = CommentRepository();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
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
                      return const CommentsEmptyState();
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isCurrentUser = FirebaseAuth.instance.currentUser?.uid == comment.uid;

                        return CommentItem(
                          comment: comment,
                          isCurrentUser: isCurrentUser,
                          onDelete: () => _commentRepository.deleteComment(
                            widget.post.postId,
                            comment.commentId,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Comment input
              CommentInput(
                controller: _commentController,
                onSend: _sendComment,
              ),
            ],
          ),
        );
      },
    );
  }
}
