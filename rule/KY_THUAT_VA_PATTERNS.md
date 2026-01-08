# CÁC KỸ THUẬT VÀ DESIGN PATTERNS SỬ DỤNG

## 📋 MỤC LỤC
1. [State Management](#state-management)
2. [Architecture Patterns](#architecture-patterns)
3. [Data Patterns](#data-patterns)
4. [UI Patterns](#ui-patterns)
5. [Concurrency Patterns](#concurrency-patterns)
6. [Firebase Patterns](#firebase-patterns)

---

## 1. STATE MANAGEMENT

### 1.1. Provider Pattern (ChangeNotifier)

**Mô tả:** Quản lý state global bằng Provider package

**Ví dụ trong project:**

```dart
// providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  void setUser(User? user) {
    _user = user;
    notifyListeners(); // Thông báo UI update
  }
}

// app/app.dart - Setup provider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
  ],
  child: MaterialApp(...),
)

// Sử dụng trong widget
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Text(authProvider.user?.displayName ?? 'Guest');
  },
)
```

**Khi nào dùng:**
- State cần share giữa nhiều screens (auth, audio player)
- State cần persist trong suốt app lifecycle

**Ưu điểm:**
- Đơn giản, dễ hiểu
- Built-in với Flutter (InheritedWidget)
- Tự động rebuild khi state thay đổi

**Nhược điểm:**
- Có thể rebuild nhiều widgets không cần thiết
- Khó debug khi app lớn

---

### 1.2. StreamBuilder Pattern

**Mô tả:** Rebuild UI tự động khi Stream emit data mới

**Ví dụ trong project:**

```dart
// screens/feed/feed_screen.dart
StreamBuilder<DatabaseEvent>(
  stream: _postRepo.streamPosts(), // Stream từ Firebase
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingWidget();
    }
    
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error.toString());
    }
    
    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
      return EmptyStateWidget();
    }
    
    final posts = _parsePosts(snapshot.data!);
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(posts[index]),
    );
  },
)
```

**Khi nào dùng:**
- Realtime updates từ Firebase
- WebSocket connections
- Periodic updates

**Ưu điểm:**
- Tự động sync với backend
- Declarative UI
- Handle loading/error states dễ dàng

**Nhược điểm:**
- Memory leaks nếu không dispose
- Phức tạp với nested streams

---

### 1.3. setState Pattern (Local State)

**Mô tả:** Quản lý state local trong StatefulWidget

**Ví dụ trong project:**

```dart
class _CreatePostScreenState extends State<CreatePostScreen> {
  bool _isUploading = false;
  File? _audioFile;
  
  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(...);
    setState(() {
      _audioFile = File(result!.files.single.path!);
    });
  }
  
  Future<void> _createPost() async {
    setState(() => _isUploading = true);
    
    try {
      await _repository.createPost(...);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
```

**Khi nào dùng:**
- State chỉ dùng trong 1 screen
- Form inputs, loading states
- Toggle states

**Best practices:**
- Always check `mounted` trước setState sau async
- Dispose controllers trong dispose()
- Không setState trong build()

---

## 2. ARCHITECTURE PATTERNS

### 2.1. Repository Pattern

**Mô tả:** Tách biệt data access logic khỏi business logic

**Cấu trúc:**
```
UI Layer (Screen/Widget)
    ↓
Business Logic Layer (Repository)
    ↓
Data Access Layer (Service)
    ↓
Data Source (Firebase)
```

**Ví dụ trong project:**

```dart
// repositories/post_repository.dart
class PostRepository {
  final _dbService = RealtimeDatabaseService();
  final _storageService = StorageService();
  
  /// Business logic: Create post
  Future<void> createPost({
    required String uid,
    required String musicId,
    String? caption,
  }) async {
    // 1. Validation
    if (musicId.isEmpty) {
      throw Exception('Music ID is required');
    }
    
    // 2. Fetch music data
    final musicSnapshot = await _dbService.musicsRef().child(musicId).get();
    final music = MusicModel.fromJson(...);
    
    // 3. Create post object
    final postId = _dbService.postsRef().push().key!;
    final post = PostModel(
      postId: postId,
      musicId: musicId,
      musicTitle: music.title, // Denormalization
      ...
    );
    
    // 4. Save to database
    await _dbService.postsRef().child(postId).set(post.toJson());
  }
  
  /// Data access: Stream posts
  Stream<List<PostModel>> streamPosts() {
    return _dbService.postsRef()
      .orderByChild('createdAt')
      .onValue
      .map((event) => _parsePosts(event));
  }
}
```

**Ưu điểm:**
- Separation of concerns
- Dễ test (mock repository)
- Reusable business logic
- Dễ switch data source (Firebase → REST API)

**Nhược điểm:**
- Thêm boilerplate code
- Có thể overkill cho app nhỏ

---

### 2.2. Service Layer Pattern

**Mô tả:** Wrapper cho external services (Firebase, API, etc.)

**Ví dụ trong project:**

```dart
// services/realtime_db_service.dart
class RealtimeDatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Provide references, không chứa business logic
  DatabaseReference usersRef() => _database.ref('users');
  DatabaseReference postsRef() => _database.ref('posts');
  DatabaseReference musicsRef() => _database.ref('musics');
}

// services/storage_service.dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload file và trả về download URL
  Future<String> uploadAudio(File file, String path) async {
    final ref = _storage.ref(path);
    final uploadTask = ref.putFile(file);
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  
  /// Delete file
  Future<void> deleteFile(String path) async {
    await _storage.ref(path).delete();
  }
}
```

**Khi nào dùng:**
- Tương tác với external APIs
- File operations
- Third-party integrations

---

### 2.3. Model-View Pattern

**Mô tả:** Tách data models ra khỏi UI

**Ví dụ trong project:**

```dart
// models/post_model.dart
class PostModel {
  final String postId;
  final String uid;
  final String authorName;
  final int createdAt;
  final Map<String, int> reactionSummary;
  
  PostModel({...});
  
  // Factory cho parsing JSON
  factory PostModel.fromJson(Map<String, dynamic> json, String postId) {
    return PostModel(
      postId: postId,
      uid: json['uid'] as String,
      createdAt: json['createdAt'] as int,
      reactionSummary: (json['reactionSummary'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value as int)
      ) ?? _defaultReactions,
    );
  }
  
  // Serialize về JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'authorName': authorName,
      'createdAt': createdAt,
      'reactionSummary': reactionSummary,
    };
  }
}
```

**Best practices:**
- Models là immutable (final fields)
- Không có business logic trong models
- Provide factory constructors cho parsing
- Use named constructors cho clarity

---

## 3. DATA PATTERNS

### 3.1. Data Denormalization

**Mô tả:** Lưu duplicate data để optimize read performance

**Ví dụ trong project:**

```dart
// Thay vì chỉ lưu musicId trong posts
{
  "posts": {
    "post1": {
      "musicId": "music1"  // ❌ Cần query thêm để lấy music info
    }
  }
}

// Denormalize: lưu snapshot của music
{
  "posts": {
    "post1": {
      "musicId": "music1",
      "musicTitle": "Song Name",        // ✅ Duplicate từ musics
      "musicOwnerName": "Artist",       // ✅ Duplicate từ musics
      "audioUrl": "https://...",        // ✅ Duplicate từ musics
      "coverUrl": "https://..."         // ✅ Duplicate từ musics
    }
  }
}
```

**Trade-offs:**
- ✅ Read nhanh hơn (1 query thay vì multiple)
- ✅ Reduce Firebase read operations → save cost
- ❌ Data có thể outdated (cần sync khi update)
- ❌ Tốn storage hơn

**Khi nào dùng:**
- Data ít thay đổi
- Read operations >> Write operations
- Display data (titles, names, avatars)

---

### 3.2. Transaction Pattern

**Mô tả:** Atomic updates để đảm bảo data consistency

**Ví dụ trong project:**

```dart
// repositories/reaction_repository.dart
Future<void> addReaction({
  required String postId,
  required String uid,
  required String reactionType,
}) async {
  // 1. Check existing reaction
  final existingSnapshot = await _dbService
    .reactionsRef(postId)
    .child(uid)
    .get();
  
  if (existingSnapshot.exists) {
    final oldReaction = existingSnapshot.value as Map;
    final oldType = oldReaction['reactionType'] as String;
    
    if (oldType == reactionType) return; // Same reaction
    
    // 2. Transaction: decrement old, increment new
    await Future.wait([
      // Decrement old reaction count
      _dbService.postsRef()
        .child('$postId/reactionSummary/$oldType')
        .runTransaction((mutableData) {
          final count = (mutableData as int?) ?? 0;
          return Transaction.success(count > 0 ? count - 1 : 0);
        }),
      
      // Increment new reaction count
      _dbService.postsRef()
        .child('$postId/reactionSummary/$reactionType')
        .runTransaction((mutableData) {
          final count = (mutableData as int?) ?? 0;
          return Transaction.success(count + 1);
        }),
    ]);
  } else {
    // 3. New reaction: just increment
    await _dbService.postsRef()
      .child('$postId/reactionSummary/$reactionType')
      .runTransaction((mutableData) {
        final count = (mutableData as int?) ?? 0;
        return Transaction.success(count + 1);
      });
  }
  
  // 4. Save user's reaction
  await _dbService.reactionsRef(postId).child(uid).set({
    'uid': uid,
    'reactionType': reactionType,
    'createdAt': ServerValue.timestamp,
  });
}
```

**Khi nào dùng:**
- Counter fields (commentCount, reactionCount)
- Bank transactions
- Inventory management
- Concurrent updates

**Lưu ý:**
- Firebase transactions có retry mechanism
- Có thể conflict với security rules (cần allow .validate)

---

### 3.3. Lazy Loading / Pagination Pattern

**Mô tả:** Load data theo chunks thay vì load toàn bộ

**Ví dụ implementation (chưa có trong project):**

```dart
class PostRepository {
  static const int PAGE_SIZE = 20;
  int? _lastCreatedAt;
  
  Future<List<PostModel>> loadMorePosts() async {
    Query query = _dbService.postsRef()
      .orderByChild('createdAt')
      .limitToLast(PAGE_SIZE);
    
    // Nếu có _lastCreatedAt, query từ đó
    if (_lastCreatedAt != null) {
      query = query.endBefore(_lastCreatedAt);
    }
    
    final snapshot = await query.get();
    final posts = _parsePosts(snapshot);
    
    // Update cursor
    if (posts.isNotEmpty) {
      _lastCreatedAt = posts.last.createdAt;
    }
    
    return posts;
  }
}
```

**Ưu điểm:**
- Reduce initial load time
- Save bandwidth
- Better UX (infinite scroll)

---

## 4. UI PATTERNS

### 4.1. Widget Composition Pattern

**Mô tả:** Build complex UIs từ small, reusable widgets

**Ví dụ trong project:**

```dart
// widgets/music_post_card.dart
class MusicPostCard extends StatelessWidget {
  final PostModel post;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(),      // Extracted widget method
          _buildContent(),     // Extracted widget method
          _buildCoverImage(),  // Extracted widget method
          _buildStats(),       // Extracted widget method
          _buildActions(),     // Extracted widget method
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(...),
        Column(
          children: [
            Text(post.authorName),
            Text(formatTimeAgo(post.createdAt)),
          ],
        ),
      ],
    );
  }
}
```

**Best practices:**
- Extract methods cho readability (_buildXxx)
- Extract classes cho reusability (separate file)
- Use const constructors khi có thể
- Avoid deep nesting (max 3-4 levels)

---

### 4.2. Builder Pattern

**Mô tả:** Conditional UI rendering

**Ví dụ trong project:**

```dart
// Sử dụng ternary operator
Widget build(BuildContext context) {
  return _isLoading 
    ? LoadingWidget()
    : _error != null
      ? ErrorWidget(_error)
      : _posts.isEmpty
        ? EmptyStateWidget()
        : ListView.builder(...);
}

// Sử dụng builder method
Widget _buildBody() {
  if (_isLoading) return LoadingWidget();
  if (_error != null) return ErrorWidget(_error);
  if (_posts.isEmpty) return EmptyStateWidget();
  return _buildPostList();
}
```

---

### 4.3. Callback Pattern

**Mô tả:** Pass functions as parameters để communicate giữa parent-child

**Ví dụ trong project:**

```dart
// screens/home/home_screen.dart
class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  void _switchToFeed() {
    setState(() => _currentIndex = 0);
  }
  
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      children: [
        FeedScreen(),
        CreatePostScreen(
          onPostSuccess: _switchToFeed,  // ✅ Callback
        ),
      ],
    );
  }
}

// screens/create_post/create_post_screen.dart
class CreatePostScreen extends StatefulWidget {
  final VoidCallback onPostSuccess;
  
  const CreatePostScreen({required this.onPostSuccess});
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  Future<void> _createPost() async {
    await _repository.createPost(...);
    widget.onPostSuccess();  // ✅ Trigger callback
  }
}
```

**Khi nào dùng:**
- Parent cần biết khi child action complete
- Update parent state từ child
- Navigation logic

---

### 4.4. Theme Pattern

**Mô tả:** Centralized styling configuration

**Ví dụ trong project:**

```dart
// app/theme.dart
class AppTheme {
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color accentPurple = Color(0xFF8B5CF6);
  
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: accentPurple,
        surface: darkSurface,
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }
}

// Sử dụng
Container(
  color: Theme.of(context).colorScheme.surface,  // ✅ Use theme
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.titleLarge,  // ✅ Use theme
  ),
)
```

**Ưu điểm:**
- Consistent design
- Dễ thay đổi theme (light/dark)
- Reusable styles

---

## 5. CONCURRENCY PATTERNS

### 5.1. Async/Await Pattern

**Mô tả:** Handle asynchronous operations

**Ví dụ trong project:**

```dart
Future<void> uploadMusic({
  required File audioFile,
  File? coverFile,
}) async {
  try {
    // Sequential operations
    final audioUrl = await _storageService.uploadAudio(audioFile, path);
    
    String? coverUrl;
    if (coverFile != null) {
      coverUrl = await _storageService.uploadCover(coverFile, path);
    }
    
    await _dbService.musicsRef().child(musicId).set({
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
    });
    
  } catch (e) {
    print('Upload failed: $e');
    rethrow;
  }
}
```

**Best practices:**
- Always use try-catch
- Check `mounted` trước setState sau await
- Use `unawaited()` cho fire-and-forget
- Avoid blocking UI thread

---

### 5.2. Future.wait Pattern (Parallel Execution)

**Mô tả:** Execute multiple async operations đồng thời

**Ví dụ trong project:**

```dart
// repositories/post_repository.dart
Future<void> deletePost(String postId) async {
  final post = await getPost(postId);
  
  // Execute all deletes in parallel
  await Future.wait([
    _dbService.postsRef().child(postId).remove(),
    _dbService.commentsRef(postId).remove(),
    _dbService.reactionsRef(postId).remove(),
    _storageService.deleteFile(post.coverPath),
  ]);
}
```

**Khi nào dùng:**
- Operations không depend on nhau
- Improve performance (parallel > sequential)

**Lưu ý:**
- Nếu 1 operation fail, tất cả sẽ fail
- Use `Future.wait(..., eagerError: false)` để continue nếu có lỗi

---

### 5.3. Stream Pattern

**Mô tả:** Continuous data flow

**Ví dụ trong project:**

```dart
// repositories/post_repository.dart
Stream<List<PostModel>> streamPosts() {
  return _dbService.postsRef()
    .orderByChild('createdAt')
    .onValue
    .map((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];
      
      return data.entries
        .map((e) => PostModel.fromJson(e.value, e.key))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
}

// Sử dụng
StreamBuilder<List<PostModel>>(
  stream: _repository.streamPosts(),
  builder: (context, snapshot) {
    // Handle snapshot states
  },
)
```

**Operators hữu ích:**
- `map()`: Transform data
- `where()`: Filter data
- `distinct()`: Remove duplicates
- `debounceTime()`: Delay emissions (rxdart)

---

## 6. FIREBASE PATTERNS

### 6.1. ServerValue.timestamp Pattern

**Mô tả:** Sử dụng server timestamp thay vì client

**Ví dụ trong project:**

```dart
import 'package:firebase_database/firebase_database.dart';

await _dbService.postsRef().child(postId).set({
  'title': title,
  'createdAt': ServerValue.timestamp,  // ✅ Server time
});

// ❌ TRÁNH sử dụng
'createdAt': DateTime.now().millisecondsSinceEpoch  // Client time có thể sai
```

**Lý do:**
- Client time có thể bị chỉnh sửa
- Multiple clients có thể có time zones khác nhau
- Server time consistent across all clients

---

### 6.2. Push Key Pattern

**Mô tả:** Generate unique IDs cho database nodes

**Ví dụ trong project:**

```dart
// Generate unique post ID
final postId = _dbService.postsRef().push().key!;

final post = PostModel(
  postId: postId,
  ...
);

await _dbService.postsRef().child(postId).set(post.toJson());
```

**Đặc điểm push keys:**
- Lexicographically sortable (theo thời gian)
- Globally unique
- Length: 20 characters

---

### 6.3. Query Pattern

**Mô tả:** Query data efficiently với indexing

**Ví dụ trong project:**

```dart
// Query posts by user
Stream<List<PostModel>> streamUserPosts(String uid) {
  return _dbService.postsRef()
    .orderByChild('uid')        // ✅ Index by uid
    .equalTo(uid)
    .onValue
    .map(_parsePosts);
}

// Query recent posts
Stream<List<PostModel>> streamRecentPosts({int limit = 20}) {
  return _dbService.postsRef()
    .orderByChild('createdAt')  // ✅ Index by createdAt
    .limitToLast(limit)
    .onValue
    .map(_parsePosts);
}
```

**Firebase indexing rules:**
```json
{
  "rules": {
    "posts": {
      ".indexOn": ["uid", "createdAt", "musicId"]
    }
  }
}
```

---

### 6.4. Batch Delete Pattern

**Mô tả:** Delete related data khi xóa entity

**Ví dụ trong project:**

```dart
// repositories/post_repository.dart
Future<void> deletePost(String postId, String uid) async {
  // 1. Get post data
  final postSnapshot = await _dbService.postsRef().child(postId).get();
  final post = PostModel.fromJson(...);
  
  // 2. Check ownership
  if (post.uid != uid) {
    throw Exception('Unauthorized');
  }
  
  // 3. Delete all related data
  await Future.wait([
    // Delete post node
    _dbService.postsRef().child(postId).remove(),
    
    // Delete comments
    _dbService.commentsRef(postId).remove(),
    
    // Delete reactions
    _dbService.reactionsRef(postId).remove(),
    
    // Delete cover image (if exists and not from music)
    if (post.coverPath != null && post.coverPath!.contains(uid))
      _storageService.deleteFile(post.coverPath!),
  ]);
}
```

---

### 6.5. Listener Cleanup Pattern

**Mô tả:** Always dispose Firebase listeners

**Ví dụ:**

```dart
class _FeedScreenState extends State<FeedScreen> {
  late StreamSubscription<DatabaseEvent> _postsSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to stream
    _postsSubscription = _repository.streamPosts().listen((posts) {
      setState(() => _posts = posts);
    });
  }
  
  @override
  void dispose() {
    _postsSubscription.cancel();  // ✅ Cleanup
    super.dispose();
  }
}
```

**Lưu ý:**
- StreamBuilder tự động cleanup
- Manual streams phải cancel trong dispose()

---

## 🎯 CHEAT SHEET: KHI NÀO DÙNG PATTERN NÀO?

| Scenario | Pattern | File Example |
|----------|---------|--------------|
| Global state (auth, player) | Provider | `providers/auth_provider.dart` |
| Local state (form, loading) | setState | `screens/create_post/create_post_screen.dart` |
| Realtime updates | StreamBuilder | `screens/feed/feed_screen.dart` |
| Data access | Repository | `repositories/post_repository.dart` |
| External service | Service | `services/storage_service.dart` |
| Data model | Model | `models/post_model.dart` |
| Reusable UI | Widget | `widgets/music_post_card.dart` |
| Async operation | async/await | Everywhere |
| Parallel operations | Future.wait | `repositories/post_repository.dart` |
| Counter fields | Transaction | `repositories/reaction_repository.dart` |
| Unique IDs | Push key | `repositories/music_repository.dart` |
| Timestamps | ServerValue.timestamp | Everywhere |

---

## 📚 TÀI LIỆU THAM KHẢO

### Flutter
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Provider Package](https://pub.dev/packages/provider)

### Firebase
- [Firebase Best Practices](https://firebase.google.com/docs/database/usage/best-practices)
- [Structuring Your Database](https://firebase.google.com/docs/database/android/structure-data)
- [Offline Capabilities](https://firebase.google.com/docs/database/android/offline-capabilities)

### Design Patterns
- [Refactoring Guru - Dart Patterns](https://refactoring.guru/design-patterns/dart)
- [Clean Code in Dart](https://github.com/dart-lang/linter)
