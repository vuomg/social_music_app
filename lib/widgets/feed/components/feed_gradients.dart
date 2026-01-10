import 'package:flutter/material.dart';

/// Enhanced gradient overlays with smoother transitions
class FeedGradients extends StatelessWidget {
  const FeedGradients({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top gradient - darker for better contrast
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.75),
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        const Spacer(),
        // Bottom gradient - enhanced for premium look
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.85),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
