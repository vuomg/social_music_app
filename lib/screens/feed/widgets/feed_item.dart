import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/post_model.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/send_music_sheet.dart';

/// Widget hiển thị 1 bài post FULL SCREEN (giống TikTok)
class FeedItem extends StatelessWidget {
  final PostModel post;
  final bool isPlaying;

  const FeedItem({
    super.key,
    required this.post,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black,
      child: Stack(
        children: [
          _buildCoverImage(),
          _buildGradientOverlay(),
          _buildPostInfo(context),
          if (isPlaying) _buildPlayingIndicator(),

          // Nút bấm ở cạnh phải
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                // 1. Nút Lưu (Bookmark)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: FavoriteButton(
                    post: post,
                    size: 28,
                    activeColor: Colors.amber,
                    inactiveColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Lưu', style: TextStyle(color: Colors.white, fontSize: 12)),
                
                const SizedBox(height: 20),

                // 2. Nút Chia sẻ (Gửi cho bạn bè)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white, size: 28),
                    onPressed: () => _showShareDialog(context),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Chia sẻ', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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
                  const Text('Chia sẻ bài nhạc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        builder: (context) => SendMusicSheet(post: post),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.link, color: Colors.grey),
                    title: const Text('Sao chép liên kết'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép liên kết')));
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

  Widget _buildCoverImage() {
    if (post.coverUrl != null && post.coverUrl!.isNotEmpty) {
      return Positioned.fill(
        child: CachedNetworkImage(
          imageUrl: post.coverUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Icon(Icons.music_note, size: 100, color: Colors.white38),
          ),
        ),
      );
    }
    return Positioned.fill(
      child: Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.music_note, size: 120, color: Colors.white38)),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostInfo(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: post.authorAvatarUrl != null ? CachedNetworkImageProvider(post.authorAvatarUrl!) : null,
                child: post.authorAvatarUrl == null ? const Icon(Icons.person, size: 16) : null,
              ),
              const SizedBox(width: 8),
              Text(post.authorName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.musicTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(post.musicOwnerName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 8),
          if (post.caption != null && post.caption!.isNotEmpty)
            Text(post.caption!, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red[400], size: 18),
              const SizedBox(width: 4),
              Text(_getTotalReactions(post.reactionSummary).toString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(width: 16),
              const Icon(Icons.comment, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(post.commentCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
        child: const Icon(Icons.music_note, color: Colors.white, size: 40),
      ),
    );
  }

  int _getTotalReactions(Map<String, int> reactionSummary) {
    return reactionSummary.values.fold(0, (sum, count) => sum + count);
  }
}
