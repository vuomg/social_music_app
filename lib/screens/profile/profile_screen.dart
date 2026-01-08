import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/music_repository.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../models/music_model.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../auth/login_screen.dart';
import '../post_detail/post_detail_screen.dart';
import 'edit_profile_screen.dart';
import '../music_library/edit_music_screen.dart';
import '../favorites/favorites_screen.dart';
import '../../widgets/send_music_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostRepository _postRepository = PostRepository();
  final MusicRepository _musicRepository = MusicRepository();
  
  // Cache streams và data
  Stream<List<PostModel>>? _postsStream;
  Stream<List<MusicModel>>? _musicsStream;
  Stream<UserModel>? _userStream;
  List<PostModel>? _cachedPosts;
  List<MusicModel>? _cachedMusics;
  UserModel? _cachedUser;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen to tab changes để update IndexedStack
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Update IndexedStack index
      }
    });
    
    // Preload data
    _preloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _preloadData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userRepository = UserRepository();
      // Cache user stream
      _userStream = userRepository.streamUser(currentUser.uid);
      // Preload user
      _cachedUser = await _userStream!.first;
      // Preload posts
      _postsStream = _postRepository.streamUserPosts(currentUser.uid);
      _cachedPosts = await _postsStream!.first;
      // Preload musics
      _musicsStream = _musicRepository.streamMyMusics(currentUser.uid);
      _cachedMusics = await _musicsStream!.first;
    } catch (e) {
      // Ignore errors during preload
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài đăng?'),
        content: const Text('Bạn có chắc chắn muốn xóa bài đăng này?'),
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

    if (confirmed != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _postRepository.deletePost(post);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài đăng')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa bài đăng: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final firebaseUser = authProvider.user;
    final uid = firebaseUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Chưa đăng nhập')),
      );
    }

    final userRepository = UserRepository();
    
    // Cache user stream để không bị dispose
    _userStream ??= userRepository.streamUser(uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              try {
                // Load current user data
                UserModel? userSnapshot;
                
                // Thử lấy từ cache trước
                if (_cachedUser != null) {
                  userSnapshot = _cachedUser;
                } else {
                  // Nếu chưa có cache, đợi stream
                  userSnapshot = await _userStream!.first;
                }
                
                if (mounted && userSnapshot != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(currentUser: userSnapshot!),
                    ),
                  );
                  
                  // Refresh if profile was updated
                  if (result == true && mounted) {
                    // The stream will automatically update
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật profile'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi mở màn hình chỉnh sửa: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<UserModel>(
          stream: _userStream,
          initialData: _cachedUser,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            // Cập nhật cache khi có data mới
            if (userSnapshot.hasData && userSnapshot.data != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _cachedUser = userSnapshot.data;
                  });
                }
              });
            }

            if (userSnapshot.connectionState == ConnectionState.waiting && _cachedUser == null) {
              return const LoadingWidget();
            }

            if (userSnapshot.hasError) {
              return ErrorStateWidget(
                message: 'Lỗi: ${userSnapshot.error}',
                onRetry: () {},
              );
            }

            final userModel = userSnapshot.data ?? _cachedUser;
            final displayName = userModel?.displayName ?? firebaseUser?.displayName ?? 'User';
            final email = firebaseUser?.email ?? '';

            return Column(
              children: [
                // User info header (giữ nguyên)
                _buildProfileHeader(userModel, displayName, email),
                // TabBar ở dưới logout button
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Giới thiệu'),
                    Tab(text: 'Bài đăng'),
                    Tab(text: 'Nhạc của tôi'),
                  ],
                ),
                // Tabs content
                Expanded(
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildAboutTab(userModel, email),
                      _buildPostsTab(uid),
                      _buildMusicsTab(uid),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? userModel, String displayName, String email) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[800],
            backgroundImage: userModel?.avatarUrl != null
                ? CachedNetworkImageProvider(userModel!.avatarUrl!)
                : null,
            child: userModel?.avatarUrl == null
                ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Quick access buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nút Đã lưu
              _buildQuickAccessButton(
                icon: Icons.bookmark,
                label: 'Đã lưu',
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab(String uid) {
    // Dùng cached stream để không bị dispose
    _postsStream ??= _postRepository.streamUserPosts(uid);
    
    return StreamBuilder<List<PostModel>>(
      stream: _postsStream,
      initialData: _cachedPosts,
      builder: (context, snapshot) {
        // Cập nhật cache khi có data mới
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _cachedPosts = snapshot.data;
              });
            }
          });
        }

        if (snapshot.connectionState == ConnectionState.waiting && _cachedPosts == null) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            message: 'Lỗi: ${snapshot.error}',
            onRetry: () {},
          );
        }

        final posts = snapshot.data ?? _cachedPosts ?? [];

        if (posts.isEmpty) {
          return const EmptyStateWidget(
            message: 'Bạn chưa có bài đăng',
            icon: Icons.music_note_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.musicTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.blue),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => SendMusicSheet(post: post),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _handleDeletePost(post),
                          ),
                        ],
                      ),
                      if (post.caption != null && post.caption!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(post.caption!),
                      ],
                      if (post.coverUrl != null) ...[
                        const SizedBox(height: 12),
                        Image.network(
                          post.coverUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[800],
                              child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMusicsTab(String uid) {
    // Dùng cached stream để không bị dispose
    _musicsStream ??= _musicRepository.streamMyMusics(uid);
    
    return StreamBuilder<List<MusicModel>>(
      stream: _musicsStream,
      initialData: _cachedMusics,
      builder: (context, snapshot) {
        // Cập nhật cache khi có data mới
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _cachedMusics = snapshot.data;
              });
            }
          });
        }

        if (snapshot.connectionState == ConnectionState.waiting && _cachedMusics == null) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            message: 'Lỗi: ${snapshot.error}',
            onRetry: () {},
          );
        }

        final musics = snapshot.data ?? _cachedMusics ?? [];

        if (musics.isEmpty) {
          return const EmptyStateWidget(
            message: 'Bạn chưa có nhạc nào',
            icon: Icons.music_off,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: musics.length,
          itemBuilder: (context, index) {
            final music = musics[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: music.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: music.coverUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note),
                          ),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note),
                      ),
                title: Text(
                  music.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(music.genre),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditMusicScreen(music: music),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(UserModel? userModel, String email) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userModel != null) ...[
            if (userModel.phone != null && userModel.phone!.isNotEmpty) ...[
              _buildInfoRow(Icons.phone, 'Số điện thoại', userModel.phone!),
              const SizedBox(height: 16),
            ],
            if (userModel.birthday != null && userModel.birthday!.isNotEmpty) ...[
              _buildInfoRow(Icons.cake, 'Ngày sinh', userModel.birthday!),
              const SizedBox(height: 16),
            ],
            if (userModel.address != null && userModel.address!.isNotEmpty) ...[
              _buildInfoRow(Icons.location_on, 'Địa chỉ', userModel.address!),
              const SizedBox(height: 16),
            ],
            if (userModel.bio != null && userModel.bio!.isNotEmpty) ...[
              const Text(
                'Giới thiệu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  userModel.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', email),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
