import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/music_repository.dart';
import '../../models/music_model.dart';
import '../../widgets/music_library_card.dart';
import '../upload_music/upload_music_screen.dart';
import 'edit_music_screen.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MusicRepository _musicRepository = MusicRepository();
  
  // Stream state cho "Tất cả" tab - chỉ load 50 bài gần nhất
  List<MusicModel>? _cachedAllMusics;
  Stream<List<MusicModel>>? _allMusicsStream;
  
  // State cho "Của tôi" tab
  List<MusicModel>? _cachedMyMusics;
  Stream<List<MusicModel>>? _myMusicsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Update IndexedStack index
      }
    });
    
    // Setup streams
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Stream cho "Tất cả" - limit 50 bài mới nhất
      _allMusicsStream = _musicRepository.streamRecentMusics(limit: 50);
      // Stream cho "Của tôi"
      _myMusicsStream = _musicRepository.streamMyMusics(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteMusic(
    BuildContext context,
    MusicModel music,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Kiểm tra quyền
    if (music.uid != currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có quyền xóa nhạc này')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhạc?'),
        content: const Text(
          'Xóa nhạc này? Các bài post đã dùng nhạc vẫn giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _musicRepository.deleteMusic(
        musicId: music.musicId,
        uid: currentUser.uid,
      );

      // Stream sẽ tự động update khi data thay đổi

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa nhạc')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa nhạc: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện nhạc'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Của tôi'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
          // Tab 1: Tất cả nhạc
          _buildAllMusicsTab(currentUser),
          // Tab 2: Nhạc của tôi
          _buildMyMusicsTab(currentUser),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadMusicScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAllMusicsTab(User currentUser) {
    return StreamBuilder<List<MusicModel>>(
      stream: _allMusicsStream,
      initialData: _cachedAllMusics,
      builder: (context, snapshot) {
        // Update cache
        if (snapshot.hasData && snapshot.data != null) {
          _cachedAllMusics = snapshot.data;
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting && 
            _cachedAllMusics == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state  
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cachedAllMusics = null;
                      _allMusicsStream = _musicRepository.streamRecentMusics(limit: 50);
                    });
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final musics = snapshot.data ?? [];
        
        // Empty state
        if (musics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có nhạc nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút + để upload nhạc mới',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // List view
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Space for FAB
          itemCount: musics.length,
          itemBuilder: (context, index) {
            final music = musics[index];
            final canEdit = music.uid == currentUser.uid;

            return MusicLibraryCard(
              music: music,
              canEdit: canEdit,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMusicScreen(music: music),
                  ),
                );
              },
              onDelete: () {
                _handleDeleteMusic(context, music);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMyMusicsTab(User currentUser) {
    // Dùng cached stream để không bị dispose
    _myMusicsStream ??= _musicRepository.streamMyMusics(currentUser.uid);
    
    return StreamBuilder<List<MusicModel>>(
      stream: _myMusicsStream,
      initialData: _cachedMyMusics, // Hiển thị cached data ngay
      builder: (context, snapshot) {
        // Cập nhật cache khi có data mới
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _cachedMyMusics = snapshot.data;
              });
            }
          });
        }

        // Nếu đã có cached data, hiển thị ngay (không cần loading)
        if (snapshot.connectionState == ConnectionState.waiting && 
            _cachedMyMusics == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }

        final musics = snapshot.data ?? [];
        if (musics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có nhạc nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút + để upload nhạc mới',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Space for FAB
          itemCount: musics.length,
          itemBuilder: (context, index) {
            final music = musics[index];

            return MusicLibraryCard(
              music: music,
              canEdit: true, // Luôn có quyền edit vì là nhạc của mình
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMusicScreen(music: music),
                  ),
                );
              },
              onDelete: () {
                _handleDeleteMusic(context, music);
              },
            );
          },
        );
      },
    );
  }
}

