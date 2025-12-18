import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../post_detail/post_detail_screen.dart';

/// Màn hình xem profile của user khác
class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  Future<void> _handleDeletePost(BuildContext context, PostModel post) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;
    
    // Chỉ cho phép xóa nếu là owner
    if (currentUserId != post.uid) {
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

    if (confirmed != true || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final postRepository = PostRepository();
      await postRepository.deletePost(post);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài đăng')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa bài đăng: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;
    final isOwnProfile = currentUserId == userId;

    final userRepository = UserRepository();
    final postRepository = PostRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: StreamBuilder<UserModel>(
          stream: userRepository.streamUser(userId),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (userSnapshot.hasError) {
              return ErrorStateWidget(
                message: 'Lỗi: ${userSnapshot.error}',
                onRetry: () {},
              );
            }

            final userModel = userSnapshot.data;
            final displayName = userModel?.displayName ?? 'User';

            return Column(
              children: [
                // User info section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: userModel?.avatarUrl != null
                            ? CachedNetworkImageProvider(userModel!.avatarUrl!)
                            : null,
                        child: userModel?.avatarUrl == null
                            ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Additional info
                      if (userModel != null) ...[
                        if (userModel.phone != null && userModel.phone!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                userModel.phone!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (userModel.birthday != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cake, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                userModel.birthday!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (userModel.bio != null && userModel.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              userModel.bio!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const Divider(),
                // Posts list section
                Expanded(
                  child: StreamBuilder<List<PostModel>>(
                    stream: postRepository.streamUserPosts(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingWidget();
                      }

                      if (snapshot.hasError) {
                        return ErrorStateWidget(
                          message: 'Lỗi: ${snapshot.error}',
                          onRetry: () {},
                        );
                      }

                      final posts = snapshot.data ?? [];

                      if (posts.isEmpty) {
                        return EmptyStateWidget(
                          message: isOwnProfile 
                              ? 'Bạn chưa có bài đăng'
                              : 'Người dùng này chưa có bài đăng',
                          icon: Icons.music_note_outlined,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final canDelete = isOwnProfile && post.uid == currentUserId;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(post: post),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            post.musicTitle,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (canDelete)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _handleDeletePost(context, post),
                                          ),
                                      ],
                                    ),
                                    if (post.caption != null && post.caption!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(post.caption!),
                                    ],
                                    if (post.coverUrl != null) ...[
                                      const SizedBox(height: 12),
                                      Image.network(
                                        post.coverUrl!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 150,
                                            color: Colors.grey[800],
                                            child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

