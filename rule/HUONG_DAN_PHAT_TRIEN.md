# HƯỚNG DẪN PHÁT TRIỂN TÍNH NĂNG MỚI

## 📋 MỤC LỤC
1. [Quy trình phát triển](#quy-trình-phát-triển)
2. [Templates code mẫu](#templates-code-mẫu)
3. [Ví dụ: Phát triển tính năng Playlist](#ví-dụ-phát-triển-tính-năng-playlist)
4. [Checklist trước khi deploy](#checklist-trước-khi-deploy)

---

## 1. QUY TRÌNH PHÁT TRIỂN

### Bước 1: Planning & Design

#### 1.1. Xác định requirements
```markdown
Feature: User Playlist Management

User stories:
- Là user, tôi muốn tạo playlist để organize nhạc yêu thích
- Là user, tôi muốn thêm/xóa nhạc vào playlist
- Là user, tôi muốn share playlist cho bạn bè
- Là user, tôi muốn xem danh sách playlists của mình

Acceptance criteria:
- [ ] User có thể tạo playlist với name và description
- [ ] User có thể thêm nhạc vào playlist từ music library
- [ ] User có thể xóa nhạc khỏi playlist
- [ ] User có thể xóa playlist
- [ ] User có thể share playlist (tạo post type="playlist")
- [ ] Playlist được lưu realtime và sync cross-device
```

#### 1.2. Database schema design
```javascript
// Firebase Realtime Database schema
{
  "playlists": {
    "{uid}": {
      "{playlistId}": {
        "playlistId": "pl_123",
        "uid": "user_123",
        "name": "My Favorites",
        "description": "Best songs ever",
        "coverUrl": "https://...",  // optional
        "createdAt": 1234567890,
        "updatedAt": 1234567891,
        "musicCount": 5
      }
    }
  },
  
  "playlistMusics": {
    "{playlistId}": {
      "{musicId}": {
        "musicId": "music_123",
        "addedAt": 1234567890,
        "order": 0  // for sorting
      }
    }
  }
}
```

#### 1.3. API design (Repository methods)
```dart
// PlaylistRepository
class PlaylistRepository {
  // CREATE
  Future<String> createPlaylist({
    required String uid,
    required String name,
    String? description,
    File? coverFile,
  });
  
  // READ
  Stream<List<PlaylistModel>> streamUserPlaylists(String uid);
  Future<PlaylistModel?> getPlaylist(String playlistId, String uid);
  Stream<List<MusicModel>> streamPlaylistMusics(String playlistId);
  
  // UPDATE
  Future<void> updatePlaylist({
    required String playlistId,
    required String uid,
    String? name,
    String? description,
    File? coverFile,
  });
  
  Future<void> addMusicToPlaylist({
    required String playlistId,
    required String musicId,
    required String uid,
  });
  
  Future<void> removeMusicFromPlaylist({
    required String playlistId,
    required String musicId,
    required String uid,
  });
  
  // DELETE
  Future<void> deletePlaylist({
    required String playlistId,
    required String uid,
  });
}
```

---

### Bước 2: Implementation

#### 2.1. Tạo Model
```dart
// lib/models/playlist_model.dart
class PlaylistModel {
  final String playlistId;
  final String uid;
  final String name;
  final String? description;
  final String? coverUrl;
  final int createdAt;
  final int? updatedAt;
  final int musicCount;

  PlaylistModel({
    required this.playlistId,
    required this.uid,
    required this.name,
    this.description,
    this.coverUrl,
    required this.createdAt,
    this.updatedAt,
    this.musicCount = 0,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json, String playlistId) {
    return PlaylistModel(
      playlistId: playlistId,
      uid: json['uid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      musicCount: json['musicCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'musicCount': musicCount,
    };
  }
}
```

#### 2.2. Update Service
```dart
// lib/services/realtime_db_service.dart
class RealtimeDatabaseService {
  // ... existing methods
  
  DatabaseReference playlistsRef(String uid) {
    return _database.ref('playlists/$uid');
  }
  
  DatabaseReference playlistMusicsRef(String playlistId) {
    return _database.ref('playlistMusics/$playlistId');
  }
}
```

#### 2.3. Implement Repository
```dart
// lib/repositories/playlist_repository.dart
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import '../models/playlist_model.dart';
import '../models/music_model.dart';
import '../services/realtime_db_service.dart';
import '../services/storage_service.dart';

class PlaylistRepository {
  final _dbService = RealtimeDatabaseService();
  final _storageService = StorageService();

  /// Tạo playlist mới
  Future<String> createPlaylist({
    required String uid,
    required String name,
    String? description,
    File? coverFile,
  }) async {
    try {
      // Validation
      if (name.trim().isEmpty) {
        throw Exception('Playlist name cannot be empty');
      }

      // Generate ID
      final playlistId = _dbService.playlistsRef(uid).push().key!;

      // Upload cover if provided
      String? coverUrl;
      if (coverFile != null) {
        final coverPath = 'playlist_covers/$uid/$playlistId.jpg';
        coverUrl = await _storageService.uploadImage(coverFile, coverPath);
      }

      // Create playlist
      final playlist = PlaylistModel(
        playlistId: playlistId,
        uid: uid,
        name: name,
        description: description,
        coverUrl: coverUrl,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _dbService
          .playlistsRef(uid)
          .child(playlistId)
          .set(playlist.toJson());

      return playlistId;
    } catch (e) {
      throw Exception('Failed to create playlist: $e');
    }
  }

  /// Stream user playlists
  Stream<List<PlaylistModel>> streamUserPlaylists(String uid) {
    return _dbService.playlistsRef(uid).onValue.map((event) {
      if (event.snapshot.value == null) return [];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => PlaylistModel.fromJson(
                Map<String, dynamic>.from(e.value as Map),
                e.key as String,
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Add music to playlist
  Future<void> addMusicToPlaylist({
    required String playlistId,
    required String musicId,
    required String uid,
  }) async {
    try {
      // Check if already exists
      final existingSnapshot = await _dbService
          .playlistMusicsRef(playlistId)
          .child(musicId)
          .get();

      if (existingSnapshot.exists) {
        throw Exception('Music already in playlist');
      }

      // Get current music count
      final playlistSnapshot = await _dbService
          .playlistsRef(uid)
          .child(playlistId)
          .get();

      if (!playlistSnapshot.exists) {
        throw Exception('Playlist not found');
      }

      final playlistData = playlistSnapshot.value as Map;
      final currentCount = playlistData['musicCount'] as int? ?? 0;

      // Add music and update count
      await Future.wait([
        _dbService.playlistMusicsRef(playlistId).child(musicId).set({
          'musicId': musicId,
          'addedAt': ServerValue.timestamp,
          'order': currentCount,
        }),
        _dbService
            .playlistsRef(uid)
            .child(playlistId)
            .child('musicCount')
            .set(currentCount + 1),
        _dbService
            .playlistsRef(uid)
            .child(playlistId)
            .child('updatedAt')
            .set(ServerValue.timestamp),
      ]);
    } catch (e) {
      throw Exception('Failed to add music to playlist: $e');
    }
  }

  /// Remove music from playlist
  Future<void> removeMusicFromPlaylist({
    required String playlistId,
    required String musicId,
    required String uid,
  }) async {
    try {
      // Check if exists
      final existingSnapshot = await _dbService
          .playlistMusicsRef(playlistId)
          .child(musicId)
          .get();

      if (!existingSnapshot.exists) {
        throw Exception('Music not in playlist');
      }

      // Get current count
      final playlistSnapshot = await _dbService
          .playlistsRef(uid)
          .child(playlistId)
          .get();
      final playlistData = playlistSnapshot.value as Map;
      final currentCount = playlistData['musicCount'] as int? ?? 0;

      // Remove music and decrement count
      await Future.wait([
        _dbService.playlistMusicsRef(playlistId).child(musicId).remove(),
        _dbService
            .playlistsRef(uid)
            .child(playlistId)
            .child('musicCount')
            .set(currentCount > 0 ? currentCount - 1 : 0),
        _dbService
            .playlistsRef(uid)
            .child(playlistId)
            .child('updatedAt')
            .set(ServerValue.timestamp),
      ]);
    } catch (e) {
      throw Exception('Failed to remove music from playlist: $e');
    }
  }

  /// Delete playlist
  Future<void> deletePlaylist({
    required String playlistId,
    required String uid,
  }) async {
    try {
      // Get playlist data
      final playlistSnapshot = await _dbService
          .playlistsRef(uid)
          .child(playlistId)
          .get();

      if (!playlistSnapshot.exists) {
        throw Exception('Playlist not found');
      }

      final playlist = PlaylistModel.fromJson(
        Map<String, dynamic>.from(playlistSnapshot.value as Map),
        playlistId,
      );

      // Delete playlist, musics, and cover
      await Future.wait([
        _dbService.playlistsRef(uid).child(playlistId).remove(),
        _dbService.playlistMusicsRef(playlistId).remove(),
        if (playlist.coverUrl != null)
          _storageService.deleteFile('playlist_covers/$uid/$playlistId.jpg'),
      ]);
    } catch (e) {
      throw Exception('Failed to delete playlist: $e');
    }
  }

  /// Stream playlist musics
  Stream<List<MusicModel>> streamPlaylistMusics(String playlistId) {
    return _dbService.playlistMusicsRef(playlistId).onValue.asyncMap((event) async {
      if (event.snapshot.value == null) return [];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final musicIds = data.keys.toList();

      // Fetch music details
      final musicFutures = musicIds.map((musicId) async {
        final musicSnapshot = await _dbService.musicsRef().child(musicId).get();
        if (musicSnapshot.exists) {
          return MusicModel.fromJson(
            Map<String, dynamic>.from(musicSnapshot.value as Map),
            musicId,
          );
        }
        return null;
      }).toList();

      final musics = await Future.wait(musicFutures);
      return musics.whereType<MusicModel>().toList();
    });
  }
}
```

#### 2.4. Tạo UI Screens

**Screen 1: Playlist List**
```dart
// lib/screens/playlist/playlist_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/playlist_model.dart';
import '../../repositories/playlist_repository.dart';
import '../../providers/auth_provider.dart' as app_auth;
import 'package:provider/provider.dart';

class PlaylistListScreen extends StatefulWidget {
  const PlaylistListScreen({super.key});

  @override
  State<PlaylistListScreen> createState() => _PlaylistListScreenState();
}

class _PlaylistListScreenState extends State<PlaylistListScreen> {
  final _playlistRepo = PlaylistRepository();

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<app_auth.AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
      ),
      body: StreamBuilder<List<PlaylistModel>>(
        stream: _playlistRepo.streamUserPlaylists(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final playlists = snapshot.data ?? [];

          if (playlists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No playlists yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _buildPlaylistCard(playlist);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePlaylistDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlaylistCard(PlaylistModel playlist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: playlist.coverUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  playlist.coverUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.playlist_play,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
        title: Text(playlist.name),
        subtitle: Text('${playlist.musicCount} songs'),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showPlaylistOptions(playlist),
        ),
        onTap: () {
          // Navigate to playlist detail
          Navigator.pushNamed(
            context,
            '/playlist-detail',
            arguments: playlist,
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist name',
                hintText: 'e.g. My Favorites',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter playlist name')),
                );
                return;
              }

              try {
                final currentUser =
                    Provider.of<app_auth.AuthProvider>(context, listen: false).user;
                await _playlistRepo.createPlaylist(
                  uid: currentUser!.uid,
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist created!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(PlaylistModel playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to edit screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Create post with playlist
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await _deletePlaylist(playlist);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlaylist(PlaylistModel playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final currentUser =
            Provider.of<app_auth.AuthProvider>(context, listen: false).user;
        await _playlistRepo.deletePlaylist(
          playlistId: playlist.playlistId,
          uid: currentUser!.uid,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playlist deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
```

#### 2.5. Update Navigation
```dart
// lib/app/app.dart
MaterialApp(
  routes: {
    '/playlist-list': (context) => const PlaylistListScreen(),
    '/playlist-detail': (context) => const PlaylistDetailScreen(),
  },
)
```

---

### Bước 3: Testing

#### 3.1. Manual Testing Checklist
```markdown
## Playlist Feature Testing

### Create Playlist
- [ ] Tạo playlist với name only → Success
- [ ] Tạo playlist với name + description → Success
- [ ] Tạo playlist với empty name → Show error
- [ ] Tạo playlist với cover image → Upload thành công

### View Playlists
- [ ] User mới chưa có playlist → Show empty state
- [ ] User có playlists → Hiển thị danh sách
- [ ] Playlists sorted by createdAt desc → Đúng order
- [ ] Pull to refresh → Data update

### Add Music
- [ ] Add music vào playlist → musicCount tăng
- [ ] Add duplicate music → Show error
- [ ] Add music vào playlist không tồn tại → Show error

### Remove Music
- [ ] Remove music khỏi playlist → musicCount giảm
- [ ] Remove music không tồn tại → Show error

### Delete Playlist
- [ ] Delete playlist → Xóa hết data (playlist, playlistMusics, cover)
- [ ] Delete playlist của user khác → Unauthorized error

### Realtime Sync
- [ ] Tạo playlist trên device A → Device B thấy realtime
- [ ] Xóa playlist trên device A → Device B update realtime
```

#### 3.2. Unit Test Example
```dart
// test/repositories/playlist_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('PlaylistRepository', () {
    late PlaylistRepository repository;
    late MockRealtimeDatabaseService mockDbService;

    setUp(() {
      mockDbService = MockRealtimeDatabaseService();
      repository = PlaylistRepository();
      // Inject mock
    });

    test('createPlaylist should throw exception if name is empty', () async {
      expect(
        () => repository.createPlaylist(
          uid: 'user123',
          name: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('createPlaylist should create playlist with valid data', () async {
      when(mockDbService.playlistsRef(any).push())
          .thenReturn(MockDatabaseReference());

      final playlistId = await repository.createPlaylist(
        uid: 'user123',
        name: 'Test Playlist',
      );

      expect(playlistId, isNotEmpty);
      verify(mockDbService.playlistsRef('user123').push()).called(1);
    });
  });
}
```

---

### Bước 4: Firebase Security Rules

```json
// firebase_realtime_database.rules.json
{
  "rules": {
    "playlists": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid",
        "$playlistId": {
          ".validate": "newData.hasChildren(['uid', 'name', 'createdAt']) && newData.child('uid').val() == auth.uid"
        }
      }
    },
    
    "playlistMusics": {
      "$playlistId": {
        ".read": "auth != null",
        ".write": "auth != null && root.child('playlists').child(auth.uid).child($playlistId).exists()",
        "$musicId": {
          ".validate": "newData.hasChildren(['musicId', 'addedAt'])"
        }
      }
    }
  }
}
```

---

## 2. TEMPLATES CODE MẪU

### Template: Basic CRUD Repository

```dart
class MyRepository {
  final _dbService = RealtimeDatabaseService();
  final _storageService = StorageService();

  // CREATE
  Future<String> create({required String uid, required Map<String, dynamic> data}) async {
    try {
      final id = _dbService.ref().push().key!;
      await _dbService.ref().child(id).set({
        ...data,
        'createdAt': ServerValue.timestamp,
      });
      return id;
    } catch (e) {
      throw Exception('Create failed: $e');
    }
  }

  // READ (Stream)
  Stream<List<MyModel>> streamAll() {
    return _dbService.ref().onValue.map((event) {
      if (event.snapshot.value == null) return [];
      final data = event.snapshot.value as Map;
      return data.entries
          .map((e) => MyModel.fromJson(e.value, e.key))
          .toList();
    });
  }

  // READ (Single)
  Future<MyModel?> getById(String id) async {
    final snapshot = await _dbService.ref().child(id).get();
    if (!snapshot.exists) return null;
    return MyModel.fromJson(snapshot.value as Map, id);
  }

  // UPDATE
  Future<void> update(String id, Map<String, dynamic> updates) async {
    try {
      await _dbService.ref().child(id).update({
        ...updates,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  // DELETE
  Future<void> delete(String id) async {
    try {
      await _dbService.ref().child(id).remove();
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }
}
```

### Template: StatefulWidget Screen with StreamBuilder

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _repository = MyRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Init logic
  }

  @override
  void dispose() {
    // Cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Screen'),
      ),
      body: StreamBuilder<List<MyModel>>(
        stream: _repository.streamAll(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          // Empty state
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No items yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Data state
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildItemCard(items[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemCard(MyModel item) {
    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(item.description ?? ''),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteItem(item.id),
        ),
      ),
    );
  }

  Future<void> _createItem() async {
    // TODO: Show dialog/navigate to create screen
  }

  Future<void> _deleteItem(String id) async {
    try {
      await _repository.delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

---

## 3. CHECKLIST TRƯỚC KHI DEPLOY

### Code Quality
- [ ] Code đã format (dart format .)
- [ ] Không có warnings/errors
- [ ] Removed debug prints
- [ ] Dispose controllers properly
- [ ] Handle null safety
- [ ] Error handling đầy đủ

### Testing
- [ ] Manual testing all happy paths
- [ ] Manual testing error cases
- [ ] Testing on multiple devices/screen sizes
- [ ] Testing network offline scenarios

### Firebase
- [ ] Security rules đã update
- [ ] Indexes đã tạo (nếu cần)
- [ ] Storage rules đã update
- [ ] Test rules với Firebase Emulator

### UI/UX
- [ ] Loading states
- [ ] Error states
- [ ] Empty states
- [ ] Success feedback (SnackBar, Dialog)
- [ ] Navigation flows đúng

### Performance
- [ ] Không có memory leaks
- [ ] Images được optimize
- [ ] Pagination nếu cần
- [ ] Debounce search inputs

### Documentation
- [ ] Update README.md
- [ ] Update TODOLIST.md
- [ ] Add code comments cho logic phức tạp
- [ ] Update API documentation

---

## 📚 TÀI LIỆU THAM KHẢO

- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)
- [Firebase Best Practices](https://firebase.google.com/docs/database/usage/best-practices)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
