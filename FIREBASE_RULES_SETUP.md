# HƯỚNG DẪN ÁP DỤNG FIREBASE RULES

## 📋 Tổng quan

Dự án này có 2 file rules cần được áp dụng vào Firebase Console:
1. **Firebase Storage Rules** (`firebase_storage.rules`)
2. **Realtime Database Rules** (`firebase_realtime_database.rules.json`)

---

## 🔐 1. FIREBASE STORAGE RULES

### Cách áp dụng:
1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Storage** → **Rules** tab
4. Copy toàn bộ nội dung từ file `firebase_storage.rules`
5. Paste vào editor
6. Click **Publish**

### Nội dung rules:
- ✅ Chỉ user đã đăng nhập mới được đọc file
- ✅ Chỉ owner (uid khớp) mới được upload/xóa file
- ✅ Áp dụng cho:
  - `audio/{uid}/{fileName}` - File nhạc
  - `covers/{uid}/{fileName}` - Ảnh bìa
  - `avatars/{uid}/{fileName}` - Avatar user

---

## 🗄️ 2. REALTIME DATABASE RULES

### Cách áp dụng:
1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Realtime Database** → **Rules** tab
4. Copy toàn bộ nội dung từ file `firebase_realtime_database.rules.json`
5. Paste vào editor (bỏ qua dấu ngoặc nhọn ngoài cùng nếu Firebase yêu cầu)
6. Click **Publish**

### Nội dung rules:

#### **users/{uid}**
- ✅ Chỉ user đó mới được đọc/ghi dữ liệu của mình
- ✅ Validate: `displayName` (1-50 ký tự), `avatarUrl` (string hoặc null)

#### **posts/{postId}**
- ✅ Tất cả user đã đăng nhập đều đọc được
- ✅ Chỉ owner mới được tạo/sửa/xóa bài đăng của mình
- ✅ Validate các field:
  - `musicId`: bắt buộc, tham chiếu đến musics/{musicId}
  - `musicTitle`: 1-120 ký tự (snapshot từ music)
  - `musicOwnerName`: 1-50 ký tự (snapshot từ music)
  - `audioUrl`: bắt buộc (snapshot từ music)
  - `authorName`: 1-50 ký tự
  - `reactionSummary`: phải có đủ 6 loại (like, love, haha, wow, sad, angry)

#### **musics/{musicId}**
- ✅ Tất cả user đã đăng nhập đều đọc được
- ✅ Chỉ owner mới được tạo/sửa/xóa nhạc của mình
- ✅ Validate các field:
  - `title`: 1-120 ký tự
  - `genre`: 1-30 ký tự
  - `ownerName`: 1-50 ký tự
  - `audioUrl`, `audioPath`: bắt buộc

#### **postReactions/{postId}/{uid}**
- ✅ Mỗi user chỉ có 1 reaction per post
- ✅ Validate: `type` phải là một trong 6 loại hợp lệ

#### **comments/{postId}/{commentId}**
- ✅ Tất cả user đã đăng nhập đều đọc được
- ✅ Chỉ owner mới được sửa/xóa comment của mình
- ✅ Validate: `content` (1-500 ký tự)

---

## ✅ KIỂM TRA SAU KHI ÁP DỤNG

### Test Storage Rules:
1. Đăng nhập vào app
2. Thử upload audio file → ✅ Phải thành công
3. Đăng xuất, thử upload → ❌ Phải bị từ chối
4. Đăng nhập user khác, thử upload vào path của user khác → ❌ Phải bị từ chối

### Test Realtime Database Rules:
1. Đăng nhập user A
2. Tạo post → ✅ Phải thành công
3. Thử sửa post của user B → ❌ Phải bị từ chối
4. Đọc post của user B → ✅ Phải được phép
5. Tạo comment → ✅ Phải thành công
6. Thử sửa comment của user khác → ❌ Phải bị từ chối

---

## ⚠️ LƯU Ý

1. **Backup rules cũ**: Trước khi publish, hãy copy rules cũ để backup
2. **Test trong development**: Nên test kỹ trước khi publish lên production
3. **Monitor logs**: Sau khi publish, theo dõi Firebase Console → Logs để phát hiện lỗi
4. **Rules có thể mất vài phút để áp dụng**: Đợi 1-2 phút sau khi publish

---

## 🔧 CODE ĐÃ ĐƯỢC CẬP NHẬT

Code Flutter đã được cập nhật để tuân thủ rules:

1. ✅ **AuthProvider**: Thêm `updatedAt` khi tạo user
2. ✅ **CreatePostScreen**: 
   - Validate title length <= 120
   - Validate genre length <= 30
   - Validate authorName length <= 50
   - Đảm bảo đủ các field required

---

## 📝 FILES

- `firebase_storage.rules` - Storage rules
- `firebase_realtime_database.rules.json` - Realtime Database rules
- `rule/firebase_rules_storage.md` - Documentation (Vietnamese)
- `rule/firebase_rules_realtime.md` - Documentation (Vietnamese)
