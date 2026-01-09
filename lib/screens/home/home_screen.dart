import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../feed/feed_screen.dart';
import '../music_library/music_library_screen.dart';
import '../create_post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../music_rooms/music_rooms_screen.dart'; // Changed from friends_screen.dart
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/notification_badge.dart';
import '../../providers/audio_player_provider.dart';

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
    const MusicRoomsScreen(), // Changed from FriendsScreen()
    const ProfileScreen(),
  ];

  void _onTabChanged(int index) {
    // Stop audio khi chuyển tab KHỎI Feed (tab 0)
    if (_currentIndex == 0 && index != 0) {
      final audioProvider =
          Provider.of<AudioPlayerProvider>(context, listen: false);
      audioProvider.stop();
      print('🔇 Stopped audio (leaving Feed tab)');
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[400],
        onTap: _onTabChanged, // Use new method
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
            icon: Icon(Icons.music_note_outlined),
            activeIcon: Icon(Icons.music_note),
            label: 'Phòng',
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
