# Social Music App 🎵

Ứng dụng mạng xã hội chia sẻ âm nhạc được xây dựng bằng Flutter và Firebase.

![Flutter](https://img.shields.io/badge/Flutter-3.10.1-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)

## 📱 Giới thiệu

**Social Music App** là một nền tảng mạng xã hội cho phép người dùng:

- 🎵 Upload và chia sẻ nhạc yêu thích
- 💬 Tương tác với bài đăng qua reactions và comments
- 👥 Kết bạn và nhắn tin realtime
- 🎧 Nghe nhạc với player tích hợp
- 📚 Quản lý thư viện nhạc cá nhân

## ✨ Tính năng

### 🔐 Xác thực
- Đăng ký / Đăng nhập với Email & Password
- Quản lý phiên đăng nhập toàn cục

### 🎶 Quản lý nhạc
- Upload file nhạc (MP3, WAV, etc.)
- Upload ảnh bìa tùy chỉnh
- Chỉnh sửa thông tin bài hát (title, genre, cover)
- Xóa nhạc
- Tìm kiếm nhạc theo tên/nghệ sĩ/thể loại

### 📱 Bài đăng xã hội
- Tạo bài đăng chia sẻ nhạc (2 modes: upload mới hoặc chọn từ thư viện)
- Feed realtime với pull-to-refresh
- React với 6 loại cảm xúc (like, love, haha, wow, sad, angry)
- Comment realtime
- Xem chi tiết bài đăng

### 🎧 Trình phát nhạc
- Global audio player
- Mini player hiển thị ở bottom bar
- Full player trong màn hình chi tiết
- Play/Pause/Seek
- Forward/Backward 10 giây
- Hiển thị thời gian (current/total)

### 👥 Bạn bè
- Tìm kiếm người dùng
- Gửi/Nhận lời mời kết bạn
- Danh sách bạn bè
- 3 tabs: Tìm kiếm, Lời mời, Bạn bè

### 💬 Nhắn tin
- Chat 1-1 với bạn bè
- Gửi tin nhắn text
- Chia sẻ nhạc trong chat
- Realtime messaging
- Preview nhạc trước khi gửi

### 👤 Hồ sơ cá nhân
- Xem/Chỉnh sửa profile (avatar, tên, ngày sinh, số điện thoại, bio, địa chỉ)
- Location services (lấy vị trí hiện tại)
- Thống kê (số bài nhạc, tổng reactions)
- Danh sách bài đăng của mình
- Xem profile người khác

### 🎨 UI/UX
- Dark theme với glassmorphism
- Facebook-like post cards
- Loading/Empty/Error states
- Network status banner
- Vietnamese localization

## 🏗️ Kiến trúc

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Realtime Database
  - Cloud Storage
- **State Management**: Provider
- **Audio**: just_audio

### Project Structure
```
lib/
├── app/                 # App configuration & theme
├── models/              # Data models
├── services/            # Firebase service wrappers
├── repositories/        # Business logic layer
├── providers/           # State management
├── screens/             # UI screens
├── widgets/             # Reusable widgets
└── utils/              # Utility functions
```

### Design Pattern
**Layered Architecture + Repository Pattern**

```
UI Layer (Screens/Widgets)
    ↓
Business Logic Layer (Repositories)
    ↓
Data Access Layer (Services)
    ↓
Data Source (Firebase)
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.10.1
- Dart SDK ^3.0
- Firebase account
- IDE (VS Code hoặc Android Studio)

### Installation

1. **Clone repository**
```bash
git clone https://github.com/yourusername/social_music_app.git
cd social_music_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
- Tạo project trên [Firebase Console](https://console.firebase.google.com/)
- Enable Authentication (Email/Password)
- Enable Realtime Database
- Enable Cloud Storage
- Download `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
- Chạy FlutterFire CLI:
```bash
flutterfire configure
```

4. **Apply Firebase Security Rules**
- Đọc hướng dẫn trong `FIREBASE_RULES_SETUP.md`
- Copy rules từ `firebase_realtime_database.rules.json` và `firebase_storage.rules`
- Apply lên Firebase Console

5. **Run app**
```bash
flutter run
```

## 📖 Documentation

Xem thêm tài liệu chi tiết trong folder `rule/`:

- **[TOM_TAT_DU_AN.md](rule/TOM_TAT_DU_AN.md)** - Tổng quan project (đọc đầu tiên) ⭐
- **[PHAN_TICH_PROJECT.md](rule/PHAN_TICH_PROJECT.md)** - Phân tích chi tiết architecture & features
- **[KY_THUAT_VA_PATTERNS.md](rule/KY_THUAT_VA_PATTERNS.md)** - Các kỹ thuật và design patterns sử dụng
- **[HUONG_DAN_PHAT_TRIEN.md](rule/HUONG_DAN_PHAT_TRIEN.md)** - Hướng dẫn phát triển tính năng mới
- **[todolist.md](rule/todolist.md)** - Checklist tính năng
- **[FIREBASE_RULES_SETUP.md](rule/FIREBASE_RULES_SETUP.md)** - Setup Firebase security

## 🗄️ Database Schema

### Realtime Database
```
firebase-db/
├── users/{uid}                    # User profiles
├── musics/{musicId}              # Music library
├── posts/{postId}                # Music posts
├── comments/{postId}/{commentId} # Post comments
├── postReactions/{postId}/{uid}  # Post reactions
├── friends/{uid}/{friendUid}     # Friend connections
├── friendRequests/{toUid}/{fromUid} # Friend requests
├── chats/{chatId}                # Chat metadata
└── messages/{chatId}/{messageId} # Chat messages
```

### Storage
```
storage/
├── audio/{uid}/{musicId}         # Audio files
├── covers/{uid}/{musicId}        # Cover images
└── avatars/{uid}                 # User avatars
```

## 🔐 Security

⚠️ **IMPORTANT**: Firebase Security Rules chưa được apply mặc định!

Trước khi deploy production, **BẮT BUỘC** phải:
1. Đọc `FIREBASE_RULES_SETUP.md`
2. Apply rules vào Firebase Console
3. Test rules với Firebase Emulator

## 🎯 Roadmap

### Phase 1: Foundation ✅
- [x] Authentication
- [x] Music upload & library
- [x] Posts & Feed
- [x] Reactions & Comments
- [x] Audio player
- [x] Friends & Chat

### Phase 2: Enhancement (In Progress)
- [ ] Apply Firebase security rules
- [ ] Playlist management
- [ ] Advanced search & filters
- [ ] Notifications (FCM)
- [ ] User follow system

### Phase 3: Advanced Features
- [ ] Analytics & insights
- [ ] Offline support
- [ ] Advanced audio features (equalizer, queue)
- [ ] Stories (24h auto-delete)
- [ ] Music challenges

### Phase 4: Optimization
- [ ] Performance optimization (pagination, caching)
- [ ] Testing (unit + integration tests)
- [ ] CI/CD pipeline
- [ ] Multi-language support

## 🛠️ Development

### Run in debug mode
```bash
flutter run
```

### Run in release mode
```bash
flutter run --release
```

### Format code
```bash
dart format .
```

### Analyze code
```bash
flutter analyze
```

### Clean build
```bash
flutter clean
flutter pub get
```

## 📦 Dependencies

### Core
- `firebase_core` ^4.3.0
- `firebase_auth` ^6.1.3
- `firebase_database` ^12.1.1
- `firebase_storage` ^13.0.5

### State Management
- `provider` ^6.1.5+1

### Media
- `just_audio` ^0.10.5
- `audio_session` ^0.1.19
- `image_picker` ^1.2.1
- `file_picker` ^10.3.7
- `cached_network_image` ^3.3.1

### UI/UX
- `google_fonts` ^6.1.0
- `intl` ^0.20.2

### Utilities
- `uuid` ^4.5.2
- `geolocator` ^14.0.2
- `geocoding` ^4.0.0
- `connectivity_plus` ^6.1.0

Xem đầy đủ trong `pubspec.yaml`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

[Your Name](https://github.com/yourusername)

## 📞 Contact

- Email: your.email@example.com
- GitHub: [@yourusername](https://github.com/yourusername)

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Firebase](https://firebase.google.com/) - Backend services
- [Provider](https://pub.dev/packages/provider) - State management
- [Just Audio](https://pub.dev/packages/just_audio) - Audio playback
- [Google Fonts](https://pub.dev/packages/google_fonts) - Typography

---

Made with ❤️ using Flutter
