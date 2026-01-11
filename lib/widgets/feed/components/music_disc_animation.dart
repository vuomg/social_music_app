import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../providers/audio_player_provider.dart';
import '../../../models/post_model.dart';

/// Premium animated rotating music disc with glassmorphism
class MusicDiscAnimation extends StatelessWidget {
  final PostModel post;

  const MusicDiscAnimation({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        final isCurrentPost = audioProvider.currentPost?.postId == post.postId;
        final isPlaying = isCurrentPost && audioProvider.isPlaying;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isPlaying ? 360.0 : 0.0),
          duration: const Duration(seconds: 4),
          curve: Curves.linear,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 3.14159 / 180,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade300,
                      Colors.pink.shade400,
                      Colors.deepPurple.shade500,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.6),
                      blurRadius: isPlaying ? 25 : 15,
                      spreadRadius: isPlaying ? 5 : 2,
                    ),
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.4),
                      blurRadius: isPlaying ? 20 : 10,
                      spreadRadius: isPlaying ? 3 : 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isPlaying ? Icons.music_note : Icons.music_note_outlined,
                          color: Colors.white,
                          size: 28,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
