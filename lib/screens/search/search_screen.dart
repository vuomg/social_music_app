import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/music_model.dart';
import '../../models/user_model.dart';
import '../../repositories/music_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/post_model.dart';
import '../../providers/audio_player_provider.dart';
import '../post_detail/post_detail_screen.dart';
import '../profile/user_profile_screen.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MusicRepository _musicRepo = MusicRepository();
  final UserRepository _userRepo = UserRepository();
  Timer? _debounce;

  List<MusicModel> _musicResults = [];
  List<UserModel> _userResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _onSearch(query);
    });
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _musicResults = [];
        _userResults = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      // Tìm nhạc
      final musicList = await _musicRepo.searchMusics(query);
      
      // Tìm người dùng
      // Giả sử UserRepository có hàm searchUsers, nếu chưa có tôi sẽ dùng getAll rồi filter
      final allUsers = await _userRepo.getAllUsers();
      final userList = allUsers.where((u) => 
        u.displayName.toLowerCase().contains(query.toLowerCase())
      ).toList();

      if (mounted) {
        setState(() {
          _musicResults = musicList;
          _userResults = userList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tìm kiếm: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm bài hát, nghệ sĩ, bạn bè...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearch('');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchQuery.isEmpty
              ? _buildEmptyState()
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Bài hát'),
                          Tab(text: 'Người dùng'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildMusicList(),
                            _buildUserList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'Nhập nội dung để khám phá',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicList() {
    if (_musicResults.isEmpty) {
      return const Center(child: Text('Không tìm thấy bài hát nào'));
    }
    return ListView.builder(
      itemCount: _musicResults.length,
      itemBuilder: (context, index) {
        final music = _musicResults[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: music.coverUrl != null
                ? Image.network(music.coverUrl!, width: 50, height: 50, fit: BoxFit.cover)
                : Container(width: 50, height: 50, color: Colors.grey),
          ),
          title: Text(music.title),
          subtitle: Text(music.ownerName),
          onTap: () {
            // Phát nhạc ngay khi nhấnvào
            final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
            audioProvider.playUrl(
              music.audioUrl,
              title: music.title,
              author: music.ownerName,
              coverUrl: music.coverUrl,
              postId: music.musicId,
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đang phát: ${music.title} 🎵'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserList() {
    if (_userResults.isEmpty) {
      return const Center(child: Text('Không tìm thấy người dùng nào'));
    }
    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user.displayName),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.uid)),
            );
          },
        );
      },
    );
  }
}
