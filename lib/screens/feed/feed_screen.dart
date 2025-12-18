import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../repositories/post_repository.dart';
import '../../providers/audio_player_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/music_post_card.dart';
import '../post_detail/post_detail_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postRepository = PostRepository();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Social'),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: postRepository.streamPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: 'Lỗi: ${snapshot.error}',
              onRetry: () {
                // Stream sẽ tự động reload
              },
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const EmptyStateWidget(
              message: 'Chưa có bài đăng',
              icon: Icons.music_note_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Stream sẽ tự động reload khi có thay đổi
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return MusicPostCard(
                post: post,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ),
                  );
                },
              );
            },
            ),
          );
        },
      ),
    );
  }
}
