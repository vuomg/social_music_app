# 🔧 CẬP NHẬT FIREBASE RULES - QUAN TRỌNG!

## ⚠️ LỖI "Permission denied" khi tạo post

Nếu bạn gặp lỗi **"Firebase Database error: Permission denied"** khi tạo post, đây là do Firebase Rules chưa được cập nhật theo schema mới.

## ✅ GIẢI PHÁP

### Bước 1: Cập nhật Firebase Realtime Database Rules

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Realtime Database** → **Rules** tab
4. Copy toàn bộ nội dung từ file `firebase_realtime_database.rules.json`
5. Paste vào editor
6. Click **Publish**

### Bước 2: Kiểm tra

Sau khi publish, đợi 1-2 phút rồi thử tạo post lại.

## 📋 THAY ĐỔI CHÍNH

### Schema cũ (KHÔNG DÙNG NỮA):
```json
{
  "title": "...",
  "genre": "...",
  "audioPath": "..."
}
```

### Schema mới (HIỆN TẠI):
```json
{
  "musicId": "...",
  "musicTitle": "...",
  "musicOwnerName": "...",
  "audioUrl": "..."
}
```

## 🔍 KIỂM TRA RULES ĐÃ ĐÚNG CHƯA

Rules mới phải có:
- ✅ `posts/{postId}` validate: `musicId`, `musicTitle`, `musicOwnerName`, `audioUrl`
- ✅ `musics/{musicId}` validate: `title`, `genre`, `audioUrl`, `audioPath`
- ✅ Bỏ yêu cầu `title`, `genre`, `audioPath` trong posts

## 📝 FILE CẦN CẬP NHẬT

- `firebase_realtime_database.rules.json` - Đã được cập nhật ✅

