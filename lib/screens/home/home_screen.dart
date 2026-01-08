import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../feed/feed_screen.dart';
import '../music_library/music_library_screen.dart';
import '../create_post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../friends/friends_screen.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/notification_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _switchToFeed() {
    setState(() {
      _currentIndex = 0;
    });
  }

  List<Widget> get _screens => [
    const FeedScreen(),
    const MusicLibraryScreen(),
    CreatePostScreen(onPostSuccess: _switchToFeed),
    const FriendsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content với padding bottom để tránh bị che bởi mini player
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          // Mini player ở bottom (trên bottom navigation bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 56, // Height của BottomNavigationBar (fixed type)
            child: const MiniPlayer(),
          ),
          // Nút Tìm kiếm và Thông báo ở góc trên bên phải
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Row(
              children: [
                _buildSearchButton(),
                const SizedBox(width: 8),
                _buildNotificationButton(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[400],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Thư viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Widget nút thông báo với badge
  Widget _buildNotificationButton() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: NotificationBadge(
        userId: userId,
        badgeColor: Colors.red,
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Mở màn hình thông báo
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Widget nút tìm kiếm
  Widget _buildSearchButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
      ),
    );
  }
}
