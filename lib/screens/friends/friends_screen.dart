import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../repositories/friends_repository.dart';
import '../../models/friend_request_model.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';
import '../../services/realtime_db_service.dart';
import '../chat/chat_room_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsRepository _friendsRepository = FriendsRepository();
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  
  // Cache stream instances và data để không bị dispose khi chuyển tab
  Stream<List<FriendRequestModel>>? _friendRequestsStream;
  Stream<List<FriendModel>>? _friendsStream;
  List<FriendRequestModel>? _cachedFriendRequests;
  List<FriendModel>? _cachedFriends;
  
  // Cache danh sách friendUids để check nhanh trong tab tìm kiếm
  Set<String> _friendUids = {};

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
    
    // Cache streams ngay từ đầu để không bị dispose
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _friendRequestsStream = _friendsRepository.streamFriendRequests(currentUser.uid);
      _friendsStream = _friendsRepository.streamFriends(currentUser.uid);
    }
    
    // Preload data
    _preloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _preloadData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Preload friend requests
      _cachedFriendRequests = await _friendsRepository.streamFriendRequests(currentUser.uid).first;
      // Preload friends
      _cachedFriends = await _friendsRepository.streamFriends(currentUser.uid).first;
      // Cache friendUids để check nhanh
      _friendUids = _cachedFriends?.map((f) => f.friendUid).toSet() ?? {};
    } catch (e) {
      // Ignore errors during preload
    }
  }

  Future<void> _searchUsers() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Lấy tất cả users (limit 50) và filter client-side
      final usersRef = _dbService.usersRef();
      final snapshot = await usersRef.limitToFirst(50).get();
      
      final List<UserModel> results = [];
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final query = _searchQuery.toLowerCase();

      if (snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map && key.toString() != currentUid) {
            try {
              final user = UserModel.fromJson(Map<String, dynamic>.from(value));
              final displayNameLower = user.displayName.toLowerCase();
              if (displayNameLower.contains(query)) {
                results.add(user);
              }
            } catch (e) {
              // Skip invalid users
            }
          }
        });
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(String toUid) async {
    try {
      await _friendsRepository.sendFriendRequest(toUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lời mời kết bạn')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
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
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bạn bè'),
            Tab(text: 'Lời mời'),
            Tab(text: 'Tìm kiếm'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
            // Friends tab (tab đầu tiên)
            _buildFriendsTab(currentUser),
            // Requests tab
            _buildFriendRequestsTab(currentUser),
            // Search tab
            _buildSearchTab(currentUser),
          ],
        ),
    );
  }

  Widget _buildSearchTab(User currentUser) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm người dùng...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _searchUsers();
            },
          ),
        ),
        if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_searchResults.isEmpty && _searchQuery.isNotEmpty)
          const Center(
            child: Text('Không tìm thấy người dùng'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final isFriend = _friendUids.contains(user.uid);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user.displayName),
                  trailing: isFriend
                      ? const Text(
                          'Đã là bạn bè',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => _sendFriendRequest(user.uid),
                          child: const Text('Kết bạn'),
                        ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFriendRequestsTab(User currentUser) {
    // Dùng cached stream để không bị dispose
    _friendRequestsStream ??= _friendsRepository.streamFriendRequests(currentUser.uid);
    
    return StreamBuilder<List<FriendRequestModel>>(
      stream: _friendRequestsStream,
      initialData: _cachedFriendRequests, // Hiển thị cached data ngay
      builder: (context, snapshot) {
        // Cập nhật cache khi có data mới
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _cachedFriendRequests = snapshot.data;
              });
            }
          });
        }

        // Nếu đã có cached data, hiển thị ngay (không cần loading)
        if (snapshot.connectionState == ConnectionState.waiting && 
            _cachedFriendRequests == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('Chưa có lời mời kết bạn'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: request.fromAvatarUrl != null
                      ? CachedNetworkImageProvider(request.fromAvatarUrl!)
                      : null,
                  child: request.fromAvatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(request.fromName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _friendsRepository.rejectFriendRequest(
                          request.fromUid,
                        );
                      },
                      child: const Text('Từ chối'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _friendsRepository.acceptFriendRequest(
                          request.fromUid,
                        );
                      },
                      child: const Text('Chấp nhận'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildFriendsTab(User currentUser) {
    // Dùng cached stream để không bị dispose
    _friendsStream ??= _friendsRepository.streamFriends(currentUser.uid);
    
    return StreamBuilder<List<FriendModel>>(
      stream: _friendsStream,
      initialData: _cachedFriends, // Hiển thị cached data ngay
      builder: (context, snapshot) {
        // Cập nhật cache khi có data mới
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _cachedFriends = snapshot.data;
                // Cập nhật friendUids để check trong tab tìm kiếm
                _friendUids = snapshot.data!.map((f) => f.friendUid).toSet();
              });
            }
          });
        }

        // Nếu đã có cached data, hiển thị ngay (không cần loading)
        if (snapshot.connectionState == ConnectionState.waiting && 
            _cachedFriends == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(child: Text('Chưa có bạn bè'));
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.avatarUrl != null
                      ? CachedNetworkImageProvider(friend.avatarUrl!)
                      : null,
                  child: friend.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(friend.displayName),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        friendUid: friend.friendUid,
                        friendName: friend.displayName,
                        friendAvatarUrl: friend.avatarUrl,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
