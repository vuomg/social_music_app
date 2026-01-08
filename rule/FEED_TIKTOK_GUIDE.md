# Hướng Dẫn Sử Dụng Feed Mới (TikTok-Style)

## 🎯 Tính năng mới

Feed Screen giờ hoạt động giống TikTok:
- **Vuốt dọc** (lên/xuống) để chuyển bài
- **Mỗi bài chiếm toàn màn hình**
- **Tự động phát nhạc** khi scroll đến bài mới
- **Tự động dừng** nhạc bài cũ

## 📝 Cách sử dụng

### 1. Xem Feed
- Mở app → Tab "Feed" (icon Home)
- Bài đầu tiên sẽ **tự động phát nhạc** sau 0.5 giây

### 2. Chuyển bài
- **Vuốt lên**: Sang bài tiếp theo
- **Vuốt xuống**: Về bài trước đó
- Nhạc sẽ tự động đổi theo bài hiện tại

### 3. Xem chi tiết
- **Tap vào bài**: Mở màn hình chi tiết (PostDetailScreen)
- Nhạc tiếp tục phát trong PostDetail

### 4. Thoát Feed
- Chuyển sang tab khác → Nhạc tự động dừng

## 🏗️ Cấu trúc Code (cho Sinh viên)

### File mới:
```
lib/screens/feed/widgets/feed_item.dart
```
**Chức năng**: Hiển thị 1 bài post full screen
- Ảnh bìa làm background
- Gradient overlay (cho chữ dễ đọc)
- Thông tin bài (tên, nghệ sĩ, stats)
- Icon "đang phát nhạc"

### File đã sửa:
```
lib/screens/feed/feed_screen.dart
```
**Thay đổi chính**:
- `StatelessWidget` → `StatefulWidget`
- `ListView` → `PageView` (vertical)
- Thêm `PageController`
- Thêm logic autoplay

## 🔧 Kỹ thuật sử dụng (Cơ bản)

### 1. PageView.builder
```dart
PageView.builder(
  scrollDirection: Axis.vertical,  // Scroll dọc
  controller: _pageController,      // Quản lý trang
  onPageChanged: _onPageChanged,    // Callback khi đổi trang
  itemCount: posts.length,
  itemBuilder: (context, index) => FeedItem(...),
)
```

### 2. PageController
```dart
late PageController _pageController;

@override
void initState() {
  _pageController = PageController(initialPage: 0);
}

@override
void dispose() {
  _pageController.dispose();  // Quan trọng!
}
```

### 3. Autoplay Logic
```dart
void _onPageChanged(int page, List<PostModel> posts) {
  // 1. Dừng bài cũ
  audioProvider.stop();
  
  // 2. Chờ 300ms (mượt hơn)
  Future.delayed(Duration(milliseconds: 300), () {
    // 3. Phát bài mới
    audioProvider.playPost(posts[page]);
  });
}
```

### 4. Auto-play bài đầu tiên
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!_hasPlayedFirstPost && posts.isNotEmpty) {
    _hasPlayedFirstPost = true;
    Future.delayed(Duration(milliseconds: 500), () {
      audioProvider.playPost(posts[0]);
    });
  }
});
```

## ⚠️ Lưu ý

### Khi dispose:
- **Phải dispose PageController**: Tránh memory leak
- **Phải stop audio**: Tránh nhạc chạy nền

### Khi sử dụng Provider:
- Dùng `listen: false` trong callbacks (initState, dispose, etc.)
- Dùng `Consumer` trong build method

### Khi làm việc với async:
- Luôn check `mounted` trước khi gọi setState
- Dùng `Future.delayed` để tránh setState sớm quá

## 🧪 Test thủ công

### Checklist:
- [ ] Bài đầu tiên tự động phát
- [ ] Vuốt lên → Chuyển bài + nhạc đổi
- [ ] Vuốt xuống → Về bài cũ + nhạc đổi
- [ ] Tap bài → Mở PostDetail
- [ ] Chuyển tab → Nhạc dừng
- [ ] Không có lỗi console
- [ ] Không crash khi danh sách rỗng

## 📚 Tài liệu tham khảo

- [PageView - Flutter Docs](https://api.flutter.dev/flutter/widgets/PageView-class.html)
- [PageController - Flutter Docs](https://api.flutter.dev/flutter/widgets/PageController-class.html)
- [just_audio Package](https://pub.dev/packages/just_audio)

---

**Tác giả**: Social Music App Team  
**Ngày tạo**: 2026-01-08  
**Version**: 1.0
