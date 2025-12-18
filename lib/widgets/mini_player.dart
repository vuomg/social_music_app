import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../screens/post_detail/post_detail_screen.dart';
import 'seekbar.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        final post = audioProvider.currentPost;
        
        // Ẩn mini player nếu không có bài hát nào đang phát
        if (post == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 70),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Cover image hoặc placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        image: post.coverUrl != null
                            ? DecorationImage(
                                image: NetworkImage(post.coverUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: post.coverUrl == null
                          ? Icon(Icons.music_note, size: 24, color: Colors.grey[400])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    
                    // Title và artist
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            post.musicTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.authorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Nút tắt
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Tắt',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        audioProvider.stop();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                // Seekbar và controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      // Tua ngược 10s
                      IconButton(
                        icon: const Icon(Icons.replay_10, size: 20),
                        tooltip: 'Tua ngược 10s',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          audioProvider.seekBackward();
                        },
                      ),
                      const SizedBox(width: 4),
                      // Seekbar
                      Expanded(
                        child: SeekBar(
                          position: audioProvider.position,
                          duration: audioProvider.duration,
                          onSeek: (position) {
                            audioProvider.seekTo(position);
                          },
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          audioProvider.togglePlayPause();
                        },
                      ),
                      const SizedBox(width: 4),
                      // Tua tới 10s
                      IconButton(
                        icon: const Icon(Icons.forward_10, size: 20),
                        tooltip: 'Tua tới 10s',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          audioProvider.seekForward();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
