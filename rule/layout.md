# APP LAYOUT – FLUTTER MUSIC SOCIAL
## (File này dùng cho Cursor AI / thiết kế layout & code)

---

## 1. Tổng quan layout ứng dụng

- Kiểu app: **Mobile App**
- Điều hướng chính: **Bottom Navigation Bar**
- Số tab chính: **3 tab**
  1. Feed (Trang chủ)
  2. Create Post (Đăng nhạc)
  3. Profile (Cá nhân)

---

## 2. Cấu trúc màn hình (Screen Hierarchy)

```text
SplashScreen
 └── AuthWrapper
      ├── LoginScreen
      └── RegisterScreen
 └── HomeScreen
      ├── FeedScreen
      │    └── PostDetailScreen
      │         └── CommentSection
      ├── CreatePostScreen
      └── ProfileScreen
           └── MyPostDetailScreen
````

---

## 3. Layout chi tiết từng màn hình

---

### 3.1 Splash Screen

**Mục đích**: kiểm tra trạng thái đăng nhập

```text
Scaffold
 └── Center
      └── CircularProgressIndicator
```

---

### 3.2 Login / Register Screen

**Mục đích**: xác thực người dùng

```text
Scaffold
 └── SafeArea
      └── SingleChildScrollView
           └── Column
                ├── AppLogo
                ├── TextField (Email)
                ├── TextField (Password)
                ├── Button (Login / Register)
                └── TextButton (Switch Login/Register)
```

---

### 3.3 Home Screen (Bottom Navigation)

**Mục đích**: điều hướng chính

```text
Scaffold
 ├── IndexedStack
 │    ├── FeedScreen
 │    ├── CreatePostScreen
 │    └── ProfileScreen
 └── BottomNavigationBar
      ├── Feed
      ├── Create
      └── Profile
```

---

### 3.4 Feed Screen (Trang chủ)

**Mục đích**: hiển thị danh sách bài nhạc

```text
Scaffold
 ├── AppBar (title: Music Social)
 └── StreamBuilder
      └── ListView.builder
           └── PostCard
```

#### PostCard layout

```text
Card
 └── Column
      ├── Row
      │    ├── CircleAvatar (author)
      │    └── Text (author name)
      ├── Text (title)
      ├── Text (caption)
      ├── Image.network (cover)
      ├── ReactionSummaryRow
      └── ActionRow
           ├── LikeButton
           ├── CommentButton
           └── ShareButton (optional)
```

---

### 3.5 Create Post Screen

**Mục đích**: đăng bài nhạc

```text
Scaffold
 ├── AppBar (title: Create Post)
 └── Form
      └── SingleChildScrollView
           └── Column
                ├── TextField (Title)
                ├── TextField (Caption)
                ├── DropdownButton (Genre)
                ├── Button (Pick Audio)
                ├── Button (Pick Cover Image)
                ├── LinearProgressIndicator (upload)
                └── Button (Post)
```

---

### 3.6 Post Detail Screen

**Mục đích**: nghe nhạc + tương tác

```text
Scaffold
 ├── AppBar
 └── Column
      ├── PostHeader
      ├── Image.network (cover)
      ├── AudioPlayerWidget
      ├── ReactionBar
      ├── Divider
      └── Expanded
           └── CommentSection
```

#### Audio Player Widget

```text
Container
 └── Column
      ├── Slider (seek bar)
      ├── Row
      │    ├── IconButton (Play/Pause)
      │    ├── Text (current time)
      │    └── Text (duration)
```

---

### 3.7 Comment Section

```text
Column
 ├── Expanded
 │    └── ListView.builder
 │         └── CommentTile
 └── Row
      ├── TextField (input comment)
      └── IconButton (send)
```

---

### 3.8 Profile Screen

**Mục đích**: thông tin cá nhân

```text
Scaffold
 ├── AppBar (Profile)
 └── Column
      ├── CircleAvatar
      ├── Text (display name)
      ├── Button (Logout)
      └── Expanded
           └── ListView.builder
                └── PostCard (my posts)
```

---

## 4. Widget tái sử dụng (Reusable Widgets)

* PostCard
* ReactionBar
* ReactionPickerBottomSheet
* CommentTile
* AudioPlayerWidget
* LoadingWidget
* EmptyStateWidget

---

## 5. Responsive & UX rules

* Dùng `SafeArea` cho mọi màn hình
* Dùng `SingleChildScrollView` cho form
* Dùng `Expanded` cho danh sách
* Không hardcode height
* Disable button khi loading
* Hiển thị loading & empty state rõ ràng

---

## 6. Điều hướng (Navigation rules)

* Splash → Login nếu chưa auth
* Splash → Home nếu đã auth
* Feed → PostDetail (Navigator.push)
* Profile → PostDetail (Navigator.push)
* Logout → Login (Navigator.pushAndRemoveUntil)

---

## 7. DONE CRITERIA (Layout)

* [ ] Không overflow UI
* [ ] Không lỗi render khi list dài
* [ ] Điều hướng mượt
* [ ] Layout rõ ràng, dễ demo

```
