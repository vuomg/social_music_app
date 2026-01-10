import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Background widget for feed items
/// Shows cover image if available, otherwise shows gradient background
class FeedBackground extends StatelessWidget {
  final String? coverUrl;

  const FeedBackground({
    super.key,
    this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return coverUrl != null
        ? CachedNetworkImage(
            imageUrl: coverUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.music_note, size: 80, color: Colors.grey),
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900,
                  Colors.deepPurple.shade900,
                  Colors.black,
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.music_note, size: 100, color: Colors.white30),
            ),
          );
  }
}
