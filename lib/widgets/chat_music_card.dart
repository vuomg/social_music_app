import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../providers/audio_player_provider.dart';

class ChatMusicCard extends StatelessWidget {
  final PostModel post;
  final bool isMe; // Để style theo người gửi

  const ChatMusicCard({
    super.key,
    required this.post,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        final isPlaying = audioProvider.currentPost?.postId == post.postId &&
            audioProvider.isPlaying;

        return GestureDetector(
          onTap: () {
            // Play/Pause khi tap vào card
            if (isPlaying) {
              audioProvider.togglePlayPause();
            } else {
              audioProvider.playUrl(
                post.audioUrl,
                title: post.musicTitle,
                author: post.authorName,
                coverUrl: post.coverUrl,
                postId: post.postId,
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.grey[800]!.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Cover image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: post.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: post.coverUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[700],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[700],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Title và artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.musicTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.musicOwnerName,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Play/Pause button
                Container(
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        audioProvider.togglePlayPause();
                      } else {
                        audioProvider.playUrl(
                          post.audioUrl,
                          title: post.musicTitle,
                          author: post.authorName,
                          coverUrl: post.coverUrl,
                          postId: post.postId,
                        );
                      }
                    },
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

