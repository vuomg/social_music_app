# API CONTRACTS – Services / Repositories (MVP)
## Mục tiêu: Cursor AI code đúng tên hàm + đúng input/output + không bịa logic

---

## 0) Conventions
- Timestamp: dùng `ServerValue.timestamp` (Realtime DB) -> lưu kiểu `int`
- IDs:
  - postId/commentId: uuid v4
- ReactionType:
  - "like" | "love" | "haha" | "wow" | "sad" | "angry"

---

## 1) DTOs (Data Transfer Objects)

### CreatePostDto
- title: String
- caption: String? (optional)
- genre: String
- audioFile: File (required)
- coverFile: File? (optional)

### CreateCommentDto
- content: String

### UserProfileDto
- displayName: String
- avatarFile: File? (optional)

---

## 2) Models (from/to JSON)
### UserModel
- uid: String
- displayName: String
- avatarUrl: String?
- createdAt: int
- updatedAt: int

### PostModel
- postId: String
- uid: String
- authorName: String
- authorAvatarUrl: String?
- title: String
- caption: String?
- genre: String
- audioUrl: String
- audioPath: String
- coverUrl: String?
- coverPath: String?
- createdAt: int
- updatedAt: int?
- commentCount: int
- reactionSummary: Map<String,int>

### CommentModel
- commentId: String
- uid: String
- authorName: String
- authorAvatarUrl: String?
- content: String
- createdAt: int
- updatedAt: int?

---

## 3) Services

### AuthService
- authStateChanges(): Stream<User?>  
- currentUser(): User?  
- signUp(email: String, password: String, displayName: String): Future<User>
  - side effect: tạo `users/{uid}` trong Realtime DB
- signIn(email: String, password: String): Future<User>
- signOut(): Future<void>

### RealtimeDbService
- usersRef(): DatabaseReference -> `/users`
- postsRef(): DatabaseReference -> `/posts`
- commentsRef(postId: String): DatabaseReference -> `/comments/{postId}`
- reactionsRef(postId: String): DatabaseReference -> `/postReactions/{postId}`

### StorageService
- uploadAudio(uid: String, postId: String, audioFile: File): Future<{audioUrl: String, audioPath: String}>
  - audioPath = `audio/{uid}/{postId}.{ext}`
- uploadCover(uid: String, postId: String, coverFile: File): Future<{coverUrl: String, coverPath: String}>
  - coverPath = `covers/{uid}/{postId}.jpg`
- uploadAvatar(uid: String, avatarFile: File): Future<{avatarUrl: String, avatarPath: String}>
  - avatarPath = `avatars/{uid}/avatar.jpg`
- deleteByPath(path: String): Future<void>

---

## 4) Repositories

### UserRepository
- streamUser(uid: String): Stream<UserModel>
- updateProfile(uid: String, dto: UserProfileDto): Future<void>
  - nếu có avatarFile -> uploadAvatar -> update users/{uid}.avatarUrl
  - update users/{uid}.updatedAt

### PostRepository
- createPost(dto: CreatePostDto): Future<void>
  - flow theo `flow_upload_post.md`
- streamFeed(limit: int): Stream<List<PostModel>>
  - query: orderByChild('createdAt') + limitToLast(limit)
- streamPost(postId: String): Stream<PostModel>
- streamMyPosts(uid: String, limit: int): Stream<List<PostModel>>
  - filter: posts where uid == current uid (client-side filter nếu RTDB query hạn chế)
- deletePost(postId: String): Future<void>
  - xóa posts/{postId}
  - xóa comments/{postId}
  - xóa postReactions/{postId}
  - xóa Storage audio/cover theo audioPath/coverPath

### ReactionRepository
- streamMyReaction(postId: String, uid: String): Stream<String?> // reaction type
- setReaction(postId: String, uid: String, newType: String): Future<void>
- removeReaction(postId: String, uid: String): Future<void> (optional)

### CommentRepository
- streamComments(postId: String, limit: int): Stream<List<CommentModel>>
  - orderByChild('createdAt') + limitToLast(limit)
- addComment(postId: String, dto: CreateCommentDto): Future<void>
- deleteComment(postId: String, commentId: String): Future<void> (optional)
