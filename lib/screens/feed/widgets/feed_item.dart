import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/post_model.dart';

/// Widget hiển thị 1 bài post FULL SCREEN (giống TikTok)
/// 
/// Chiếm toàn bộ màn hình, hiển thị:
/// - Ảnh bìa làm background
/// - Thông tin bài hát (title, artist) ở bottom
/// - Icon play/pause ở center (nếu cần)
class FeedItem extends StatelessWidget {
  final PostModel post;
  final bool isPlaying; // Có đang phát nhạc không?

  const FeedItem({
    super.key,
    required this.post,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black, // Background đen nếu không có ảnh
      child: Stack(
        children: [
          // 1. Ảnh bìa làm background (full screen)
          _buildCoverImage(),

          // 2. Gradient overlay (tối dần từ trên xuống dưới)
          _buildGradientOverlay(),

          // 3. Thông tin bài hát (ở bottom)
          _buildPostInfo(context),

          // 4. Icon play/pause ở giữa màn hình (khi nhạc đang phát)
          if (isPlaying) _buildPlayingIndicator(),
        ],
      ),
    );
  }

  /// Ảnh bìa full screen
  Widget _buildCoverImage() {
    if (post.coverUrl != null && post.coverUrl!.isNotEmpty) {
      return Positioned.fill(
        child: CachedNetworkImage(
          imageUrl: post.coverUrl!,
          fit: BoxFit.cover, // Phủ kín màn hình
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Icon(
              Icons.music_note,
              size: 100,
              color: Colors.white38,
            ),
          ),
        ),
      );
    } else {
      // Không có ảnh → hiển thị icon nhạc
      return Positioned.fill(
        child: Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(
              Icons.music_note,
              size: 120,
              color: Colors.white38,
            ),
          ),
        ),
      );
    }
  }

  /// Gradient tối dần (để chữ trên bottom dễ đọc)
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

  /// Thông tin bài hát (bottom của màn hình)
  Widget _buildPostInfo(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100, // Để chừa chỗ cho bottom nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên người đăng
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: post.authorAvatarUrl != null
                    ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                    : null,
                child: post.authorAvatarUrl == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                post.authorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tên bài hát (title)
          Text(
            post.musicTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Tên nghệ sĩ
          Text(
            post.musicOwnerName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Caption (nếu có)
          if (post.caption != null && post.caption!.isNotEmpty)
            Text(
              post.caption!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),

          // Stats (reactions + comments)
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red[400], size: 18),
              const SizedBox(width: 4),
              Text(
                _getTotalReactions(post.reactionSummary).toString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.comment, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(
                post.commentCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Icon "đang phát nhạc" ở giữa màn hình
  Widget _buildPlayingIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.music_note,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  /// Tính tổng số reactions
  int _getTotalReactions(Map<String, int> reactionSummary) {
    return reactionSummary.values.fold(0, (sum, count) => sum + count);
  }
}
