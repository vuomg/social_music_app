# Hướng dẫn sử dụng 3 chức năng mới

## 1. 📁 Cấu trúc files đã tạo

```
lib/
├── models/
│   ├── favorite_model.dart       # Model cho Favorites
│   └── recently_played_model.dart # Model cho Recently Played
├── repositories/
│   ├── favorite_repository.dart   # CRUD cho Favorites
│   └── recently_played_repository.dart # CRUD cho Recently Played
├── providers/
│   └── recently_played_provider.dart # Provider cho Recently Played
├── widgets/
│   ├── favorite_button.dart       # Widget nút yêu thích
│   └── notification_badge.dart    # Widget badge thông báo
└── screens/
    ├── favorites/
    │   └── favorites_screen.dart  # Màn hình danh sách yêu thích
    └── recently_played/
        └── recently_played_screen.dart # Màn hình đã nghe gần đây
```

## 2. ❤️ Favorites (CRUD, List UI)

### Sử dụng FavoriteButton
```dart
import 'package:social_music_app/widgets/favorite_button.dart';

// Trong bất kỳ widget nào
FavoriteButton(
  musicId: 'music_123',  // ID của bài nhạc
  size: 24,              // Kích thước icon (optional)
  activeColor: Colors.red, // Màu khi đã like (optional)
)
```

### Sử dụng FavoriteRepository trực tiếp
```dart
import 'package:social_music_app/repositories/favorite_repository.dart';

final repo = FavoriteRepository();

// Thêm vào yêu thích
await repo.addFavorite(userId, musicId);

// Xóa khỏi yêu thích
await repo.removeFavorite(userId, musicId);

// Kiểm tra đã thích chưa
bool isFav = await repo.isFavorite(userId, musicId);

// Toggle (thêm/xóa)
bool newState = await repo.toggleFavorite(userId, musicId);

// Stream danh sách yêu thích
repo.streamFavorites(userId).listen((List<FavoriteModel> favorites) {
  // Cập nhật UI
});
```

## 3. 🎵 Recently Played (Provider, Database query)

### Sử dụng với Provider
```dart
import 'package:provider/provider.dart';
import 'package:social_music_app/providers/recently_played_provider.dart';

// Trong widget
Consumer<RecentlyPlayedProvider>(
  builder: (context, provider, child) {
    final list = provider.recentlyPlayed;
    // Build UI với list
  },
)

// Thêm bài hát vào recently played
context.read<RecentlyPlayedProvider>().addToRecentlyPlayed(
  userId: userId,
  musicId: musicId,
  musicTitle: 'Tên bài hát',
  coverUrl: 'url_cover',
  ownerName: 'Tên tác giả',
);

// Xóa lịch sử
context.read<RecentlyPlayedProvider>().clearHistory(userId);
```

## 4. 🔔 Notification Badge (StreamBuilder, Realtime)

### Sử dụng NotificationBadge
```dart
import 'package:social_music_app/widgets/notification_badge.dart';

// Badge với số lượng
NotificationBadge(
  userId: userId,
  badgeColor: Colors.red,
  child: Icon(Icons.notifications),
)

// Badge chỉ có chấm đỏ
NotificationDot(
  userId: userId,
  dotColor: Colors.red,
  child: Icon(Icons.notifications),
)
```

## 5. 🗄️ Firebase Database Structure

Thêm các rules sau vào `firebase_realtime_database.rules.json`:

```json
{
  "rules": {
    "favorites": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid"
      }
    },
    "recentlyPlayed": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid"
      }
    },
    "notifications": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid"
      }
    }
  }
}
```

## 6. 📖 Kỹ năng đã học

| Chức năng | Kỹ năng |
|-----------|---------|
| **Favorites** | CRUD operations, StreamBuilder, List UI |
| **Recently Played** | Provider pattern, Database query, Stream |
| **Notification Badge** | StreamBuilder, Realtime updates |

## 7. 🧪 Test thử

1. Mở app và đăng nhập
2. Vào Profile → nhấn "Yêu thích" hoặc "Gần đây"
3. Thử toggle nút ❤️ trên các bài nhạc
4. Kiểm tra badge thông báo realtime

---
Created for fresher level - Code đơn giản, dễ hiểu 🚀
