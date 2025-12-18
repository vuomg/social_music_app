import 'package:flutter/material.dart';
import '../feed/feed_screen.dart';
import '../music_library/music_library_screen.dart';
import '../create_post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../friends/friends_screen.dart';
import '../../widgets/mini_player.dart';

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
}
