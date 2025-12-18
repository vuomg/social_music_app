# TODO LIST – ĐỒ ÁN MOBILE FLUTTER
## Ứng dụng chia sẻ nhạc (Music Social App)
Công nghệ: Flutter + Firebase (Auth, Realtime Database, Storage)

---

## I. KHỞI TẠO DỰ ÁN
- [x] Tạo Flutter project
- [x] Đặt package name (Android/iOS)
- [x] Cấu hình môi trường Android / iOS / Web
- [x] Cài đặt FlutterFire CLI
- [x] Kết nối Firebase project
- [x] Enable Firebase services:
  - [x] Authentication (Email/Password)
  - [x] Realtime Database
  - [x] Firebase Storage
- [x] Thêm dependencies:
  - [x] firebase_core
  - [x] firebase_auth
  - [x] firebase_database
  - [x] firebase_storage
  - [x] provider (hoặc riverpod)
  - [x] file_picker
  - [x] image_picker
  - [x] just_audio / audioplayers
  - [x] uuid
  - [x] intl
  - [x] cached_network_image
  - [x] geolocator
  - [x] geocoding
  - [x] google_fonts
  - [x] flutter_localizations

---

## II. THIẾT KẾ DỮ LIỆU (REALTIME DATABASE)
- [x] Xây dựng schema dữ liệu:
  - [x] users/{uid}
  - [x] posts/{postId}
  - [x] comments/{postId}/{commentId}
  - [x] postReactions/{postId}/{uid}
- [x] Thiết kế fields cho `users`:
  - [x] uid
  - [x] displayName
  - [x] avatarUrl
  - [x] createdAt
  - [x] birthday (optional)
  - [x] phone (optional)
  - [x] bio (optional)
  - [x] address (optional)
- [x] Thiết kế fields cho `posts`:
  - [x] uid (authorId)
  - [x] authorName
  - [x] authorAvatarUrl
  - [x] title
  - [x] caption
  - [x] genre
  - [x] audioUrl
  - [x] audioPath
  - [x] coverUrl
  - [x] coverPath
  - [x] createdAt
  - [x] reactionSummary (like, love, haha, wow, sad, angry)
  - [x] commentCount
- [x] Thiết kế fields cho `comments`:
  - [x] uid
  - [x] authorName
  - [x] authorAvatarUrl
  - [x] content
  - [x] createdAt
- [x] Quy ước reaction types

---

## III. FIREBASE SECURITY RULES
### Realtime Database
- [x] Chỉ user đăng nhập mới được read (rules đã có)
- [x] User chỉ được tạo/sửa/xóa bài đăng của mình (rules đã có)
- [x] User chỉ được xóa bình luận của mình (rules đã có)
- [x] Mỗi user chỉ được 1 reaction / bài đăng (rules đã có)
- [ ] **Cần áp dụng rules vào Firebase Console** (xem FIREBASE_RULES_SETUP.md)

### Firebase Storage
- [x] Upload audio theo path: audio/{uid}/{postId} (code đã implement)
- [x] Upload cover theo path: covers/{uid}/{postId} (code đã implement)
- [x] Chỉ owner được write (rules đã có)
- [x] Read cho user đã đăng nhập (rules đã có)
- [ ] **Cần áp dụng rules vào Firebase Console** (xem FIREBASE_RULES_SETUP.md)

---

## IV. KIẾN TRÚC & CẤU TRÚC CODE
- [x] Tạo thư mục:
  - [x] models
  - [x] services
  - [x] repositories
  - [x] providers
  - [x] screens
  - [x] widgets
- [x] Xây dựng models:
  - [x] UserModel
  - [x] PostModel
  - [x] CommentModel
  - [x] ReactionType enum
- [x] Xây dựng services:
  - [ ] AuthService
  - [x] RealtimeDatabaseService
  - [x] StorageService
- [x] Xây dựng repositories:
  - [x] PostRepository
  - [x] CommentRepository
  - [x] ReactionRepository
- [x] Tạo AuthProvider (quản lý auth state)
- [x] Tạo AudioPlayerProvider (quản lý audio player global)

---

## V. XÁC THỰC NGƯỜI DÙNG
- [x] Màn hình Splash (kiểm tra auth state)
- [x] Màn hình Đăng ký:
  - [x] Validate email, password
  - [x] Tạo tài khoản Firebase Auth
  - [x] Lưu user vào Realtime Database
- [x] Màn hình Đăng nhập
- [x] Đăng xuất

---

## VI. GIAO DIỆN & ĐIỀU HƯỚNG
- [x] Setup Theme, Color, Font
- [x] Dark Theme Implementation:
  - [x] ColorScheme với dark brightness
  - [x] Scaffold background color (0xFF0F172A)
  - [x] Card theme với dark surface (0xFF1E293B)
  - [x] Text theme với Google Fonts (Inter)
  - [x] AppBar theme (transparent, white icons)
  - [x] System UI overlay style (dark theme)
- [x] BottomNavigationBar:
  - [x] Feed
  - [x] Create Post
  - [x] Profile
- [x] Routing giữa các màn hình
- [x] Mini Player widget (hiển thị bài đang phát)
- [x] Widget dùng chung:
  - [x] Loading (LoadingWidget)
  - [x] Empty state (EmptyStateWidget)
  - [x] Error state (ErrorStateWidget)
  - [x] Network banner (NetworkBanner)

---

## VII. FEED (DANH SÁCH BÀI NHẠC)
- [x] Stream dữ liệu posts realtime
- [x] Sắp xếp theo createdAt
- [x] Hiển thị PostCard:
  - [x] Avatar + tên người đăng
  - [x] Tiêu đề + mô tả
  - [x] Ảnh bìa (từ Firebase)
  - [x] Nút Play/Pause để nghe nhạc
  - [x] Navigate đến PostDetailScreen
- [x] **Redesign Music Post Card (Facebook-like):**
  - [x] Tạo widget `lib/widgets/music_post_card.dart`
  - [x] Header với CircleAvatar, authorName, genre + timeAgo, more_horiz icon
  - [x] Content với title (18px bold, maxLines 2), caption (gray, maxLines 2)
  - [x] Cover image 16:9 với play/pause overlay, pill text "Đang phát" / "Nhấn để nghe"
  - [x] Stats hiển thị reactionTotal và commentCount (❤️ 12 💬 4)
  - [x] Action buttons: Reaction, Comment, Share
  - [x] Floating reaction button ở góc trên bên phải (tap to like, long press để chọn cảm xúc)
  - [x] Dark theme styling
- [x] Empty state ("Chưa có bài đăng")
- [x] Mini Player ở bottom (hiển thị khi có bài đang phát)
- [x] Refresh feed (PullToRefresh)

---

## VIII. TẠO BÀI ĐĂNG (UPLOAD NHẠC)
- [x] Màn hình Create Post
- [x] Nhập tiêu đề
- [x] Nhập caption
- [x] Chọn thể loại
- [x] Chọn file nhạc (file_picker)
- [x] Chọn ảnh bìa (image_picker, optional)
- [x] Upload nhạc lên Firebase Storage
- [x] Upload ảnh bìa (nếu có)
- [x] Lưu metadata vào Realtime Database
- [x] Hiển thị progress upload
- [x] Xử lý lỗi upload
- [x] Disable nút Post khi đang upload

---

## IX. CHI TIẾT BÀI ĐĂNG
- [x] Hiển thị thông tin bài đăng:
  - [x] Avatar tác giả
  - [x] Tên tác giả
  - [x] Title
  - [x] Caption
  - [x] Genre
  - [x] Ảnh cover (nếu có)
  - [x] Thời gian tạo (format đơn giản)
- [x] Audio Player:
  - [x] Play / Pause
  - [x] Hiển thị trạng thái đang phát / dừng
  - [x] Dừng khi rời màn hình (dispose)
  - [x] **Upgrade Music Player Bar:**
    - [x] SeekBar widget với Slider để tua nhạc
    - [x] Hiển thị current time / total duration (mm:ss format)
    - [x] Play/Pause button
    - [x] Smooth seeking (update UI locally on onChanged, seek on onChangeEnd)
    - [x] 10-second forward/backward seek buttons
    - [x] Tích hợp vào MiniPlayer (compact mode)
    - [x] Tích hợp vào PostDetailScreen (full mode)
    - [x] AudioPlayerProvider streams: position, duration, bufferedPosition, playing
    - [x] TimeFormat utility (mm:ss)
- [x] Reaction:
  - [x] Hiển thị reactionSummary (tổng số reactions)
  - [x] Hiển thị reaction hiện tại của user
  - [x] Chọn reaction (bottom sheet với 6 loại)
  - [x] Lưu vào postReactions/{postId}/{uid}
  - [x] Update reactionSummary (transaction)
  - [x] Mỗi user chỉ 1 reaction / post
  - [x] Có thể đổi reaction (like → love)
  - [x] Fix reaction picker overflow (wrapped buttons in Flexible, reduced padding)
  - [x] Dark theme styling cho reaction picker
  - [x] Floating reaction button ở góc trên card (dark theme, border, improved styling)
- [x] Comment:
  - [x] Hiển thị danh sách comment realtime
  - [x] Comment item hiển thị: Avatar, Author name, Content, CreatedAt
  - [x] Thêm comment mới
  - [x] Update commentCount (transaction)

---

## X. PROFILE
- [x] Hiển thị thông tin user (placeholder)
- [x] Danh sách bài đăng của user (stream realtime theo uid)
- [x] Xóa bài đăng:
  - [x] Xóa node posts
  - [x] Xóa comments liên quan
  - [x] Xóa reactions liên quan
  - [x] Xóa file audio & cover trong Storage
- [x] UI xóa post trong ProfileScreen (nút Delete + dialog confirm)
- [x] UI xóa post trong PostDetailScreen (nếu user là owner)
- [x] **Thiết kế lại Profile UI theo layout Facebook:**
  - [x] ProfileHeader với avatar, displayName, email, stats (Bài nhạc, Reactions), nút Logout
  - [x] My Posts section với title "Bài nhạc của tôi"
  - [x] MyPostCard widget hiển thị bài đăng dạng Facebook-like (Title, Caption, Cover 16:9, Stats, Delete button)
  - [x] Empty state khi chưa có bài đăng
  - [x] Cập nhật ProfileViewModel để load posts và tính tổng reactions
- [x] **Edit Profile Functionality:**
  - [x] Edit Profile Screen với form fields (displayName, avatar, birthday, phone, bio, address)
  - [x] Avatar upload với image_picker
  - [x] Birthday picker với Vietnamese locale (showDatePicker)
  - [x] Location services (geolocator + geocoding) để lấy địa chỉ hiện tại
  - [x] Update user profile trong Realtime Database
  - [x] Upload avatar lên Firebase Storage
  - [x] Fix "User not found" error (ensureUserExists)
  - [x] Fix MaterialLocalizations error (flutter_localizations)
- [x] **View Other Users' Profiles:**
  - [x] UserProfileScreen để xem profile của user khác
  - [x] Navigate từ author info trong PostDetailScreen
  - [x] Hiển thị posts của user đó
  - [x] Conditional delete button (chỉ owner mới thấy)

---

## XI. TRẢI NGHIỆM NGƯỜI DÙNG (UX)
- [x] Hiển thị loading khi xử lý
- [x] Disable nút khi đang upload
- [x] Format thời gian (x phút trước) - đã implement trong PostDetailScreen
- [x] Xử lý mất mạng (NetworkBanner hiển thị khi mất kết nối)
- [x] Không crash khi thao tác nhanh (debounce cho reaction)

---

## XII. KIỂM THỬ
- [x] Test đăng ký / đăng nhập
- [x] Test upload nhạc
- [ ] Test feed realtime (2 thiết bị)
- [ ] Test reaction (đúng số lượng)
- [ ] Test comment realtime
- [ ] Test security rules
- [x] Test xóa bài đăng (DB + Storage + related data)

---
---

## XV. KẾT BẠN (FRIENDS) + CHAT + SHARE MUSIC
### 1) Thiết kế dữ liệu (Realtime Database)
- [x] Schema:
  - [x] friendRequests/{toUid}/{fromUid}:
    - [x] fromUid, fromName, fromAvatarUrl, createdAt
  - [x] friends/{uid}/{friendUid}:
    - [x] friendUid, displayName, avatarUrl, createdAt
  - [x] chats/{chatId}:
    - [x] members:{uid:true}, lastMessage, lastMessageAt
  - [x] messages/{chatId}/{messageId}:
    - [x] senderUid, type:"text"|"music", text?, postId?, createdAt
  - [x] Helper: buildChatId(uidA, uidB) - sắp xếp và join bằng "_"

### 2) Models
- [x] FriendRequestModel
- [x] FriendModel
- [x] ChatModel
- [x] MessageModel
- [x] Cập nhật PostModel: thêm audioSource, originalPostId

### 3) Repositories
- [x] FriendsRepository:
  - [x] sendFriendRequest, streamFriendRequests
  - [x] acceptFriendRequest, rejectFriendRequest
  - [x] streamFriends, areFriends
- [x] ChatRepository:
  - [x] streamChats, getOrCreateChat
  - [x] streamMessages, sendTextMessage, sendMusicMessage

### 4) Tính năng UI/UX
- [x] FriendsScreen:
  - [x] Tab "Tìm kiếm": search user, button "Kết bạn"
  - [x] Tab "Lời mời": list requests, Accept/Reject
  - [x] Tab "Bạn bè": list friends, tap để mở chat
- [x] ChatListScreen:
  - [x] Stream chats của current user
  - [x] Hiển thị avatar/name của người kia + lastMessage + time
- [x] ChatRoomScreen:
  - [x] Stream messages realtime
  - [x] Input text + nút Send
  - [x] Nút "Music" mở MusicPickerSheet
  - [x] Tap message music -> mở PostDetailScreen
- [x] MusicPickerSheet widget (dùng chung):
  - [x] Search posts
  - [x] List posts với title/author/cover
  - [x] Preview play/pause từng item
  - [x] Select để gửi/chọn

### 5) Create Post - Library Mode
- [x] Toggle mode: Upload / Thư viện
- [x] Library mode:
  - [x] Button "Chọn nhạc" mở MusicPickerSheet
  - [x] Preview post đã chọn
  - [x] Submit: không upload audio, lấy audioUrl/audioPath từ post gốc
  - [x] Lưu với audioSource="library", originalPostId
  - [x] Cover: user có thể upload riêng (optional)

### 6) Navigation
- [x] HomeScreen: thêm tab "Friends" vào BottomNavigationBar
- [x] FriendsScreen -> ChatRoomScreen
- [x] ChatRoomScreen -> PostDetailScreen (từ message music)

### 7) Files đã tạo/cập nhật
- ✅ `lib/models/friend_request_model.dart` (NEW)
- ✅ `lib/models/friend_model.dart` (NEW)
- ✅ `lib/models/chat_model.dart` (NEW)
- ✅ `lib/models/message_model.dart` (NEW)
- ✅ `lib/models/post_model.dart` (UPDATE) - thêm audioSource, originalPostId
- ✅ `lib/repositories/friends_repository.dart` (NEW)
- ✅ `lib/repositories/chat_repository.dart` (NEW)
- ✅ `lib/repositories/user_repository.dart` (UPDATE) - thêm getUser method
- ✅ `lib/services/realtime_db_service.dart` (UPDATE) - thêm refs cho friends/chats/messages
- ✅ `lib/widgets/music_picker_sheet.dart` (NEW)
- ✅ `lib/screens/friends/friends_screen.dart` (NEW)
- ✅ `lib/screens/chat/chat_list_screen.dart` (NEW)
- ✅ `lib/screens/chat/chat_room_screen.dart` (NEW)
- ✅ `lib/screens/create_post/create_post_screen.dart` (UPDATE) - library mode
- ✅ `lib/screens/home/home_screen.dart` (UPDATE) - thêm tab Friends

### 3) Rules (Realtime DB)
- [ ] friendRequests:
  - [ ] Người nhận (toUid) mới được read
  - [ ] Người gửi chỉ được tạo request của mình
  - [ ] Accept/Reject chỉ do toUid thực hiện
- [ ] friends:
  - [ ] uid chỉ được đọc/ghi node của mình

---

## XVI. NHẮN TIN (CHAT) + GỬI NHẠC TRONG CHAT
### 1) Thiết kế dữ liệu (Realtime Database)
- [x] Schema:
  - [x] chats/{chatId}:
    - [x] members: {uid1:true, uid2:true}
    - [x] lastMessage
    - [x] lastMessageAt
  - [x] messages/{chatId}/{messageId}:
    - [x] senderUid
    - [x] type: "text" | "music"
    - [x] text (nullable)
    - [x] postId (nullable)  // gửi nhạc bằng cách share bài post
    - [x] createdAt

### 2) UI/UX
- [x] ChatListScreen:
  - [x] Danh sách cuộc trò chuyện theo lastMessageAt
- [x] ChatRoomScreen:
  - [x] Danh sách tin nhắn realtime
  - [x] Input gửi text
  - [x] Nút "Gửi nhạc":
    - [x] Mở MusicPickerBottomSheet (chọn nhạc đã upload trong hệ thống)
    - [x] Có ô search
    - [x] Có nút nghe thử (preview)
    - [x] Chọn xong → gửi message type=music (postId)
  - [x] Tap message music → mở PostDetailScreen

### 3) Rules (Realtime DB)
- [ ] chats:
  - [ ] Chỉ member mới được read/write
- [ ] messages:
  - [ ] Chỉ member mới được read/write
  - [ ] senderUid phải == auth.uid

---

## XVII. MUSIC PICKER (CHỌN NHẠC TỪ HỆ THỐNG) + SỬA CREATE POST
### 1) Mục tiêu
- [x] Create Post có 2 lựa chọn audio:
  - [x] (A) Upload file mới (file_picker)  ✅ vẫn giữ
  - [x] (B) Chọn nhạc có sẵn từ hệ thống (nhạc user khác đã up)
- [x] Khi chọn nhạc có sẵn:
  - [x] Có search theo title/author/genre (basic)
  - [x] Có preview (nghe thử) trước khi chọn
  - [x] Khi "Post" sẽ lưu post mới tham chiếu audioUrl/audioPath có sẵn (không upload lại)

### 2) Thay đổi dữ liệu Post
- [x] posts/{postId} thêm field:
  - [x] audioSource: "upload" | "library"
  - [x] originalPostId (nullable) // nếu lấy nhạc từ post khác

### 3) UI CreatePostScreen
- [x] Thêm Toggle/Segment:
  - [x] "Upload file" | "Chọn từ thư viện"
- [x] Nếu "Upload file":
  - [x] Giữ flow cũ (pick audio → upload storage)
- [x] Nếu "Chọn từ thư viện":
  - [x] Nút "Chọn nhạc" mở MusicPicker
  - [x] Hiển thị track đã chọn (title/author) + nút nghe thử
  - [x] Khi đăng bài:
    - [x] Không upload audio
    - [x] Chỉ upload cover (nếu user chọn ảnh bìa)
    - [x] Lưu post với audioUrl/audioPath lấy từ bài gốc

### 4) Tìm kiếm nhạc (basic)
- [x] MusicPickerSheet (dùng chung cho chat + create post)
  - [x] TextField search
  - [x] ListView posts (stream realtime)
  - [x] Tap item → chọn
  - [x] Nút play preview từng item

---

## XVIII. KIỂM THỬ (BỔ SUNG)
- [ ] Test kết bạn:
  - [ ] A gửi request → B thấy request
  - [ ] B accept → cả A và B có trong friends
- [ ] Test chat:
  - [ ] 2 máy nhắn realtime
  - [ ] lastMessage cập nhật đúng
- [ ] Test gửi nhạc trong chat:
  - [ ] chọn nhạc + preview + gửi message music
  - [ ] bấm message music → mở PostDetail
- [ ] Test Create Post (2 mode):
  - [ ] Upload file mới OK
  - [ ] Chọn từ thư viện tạo post mới OK (không upload audio lại)
