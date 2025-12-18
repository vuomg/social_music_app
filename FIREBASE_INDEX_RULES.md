# Firebase Realtime Database Index Rules

Để tối ưu hiệu suất và loại bỏ warning, thêm các index sau vào Firebase Realtime Database Rules:

## Cách thêm index:

1. Vào Firebase Console → Realtime Database → Rules
2. Thêm phần `indexes` vào file `database.rules.json`:

```json
{
  "rules": {
    // ... existing rules ...
  },
  "indexes": {
    "posts": {
      ".indexOn": ["uid", "createdAt"]
    },
    "musics": {
      ".indexOn": ["uid", "createdAt"]
    },
    "comments": {
      ".indexOn": ["postId", "createdAt"]
    },
    "chats": {
      ".indexOn": ["lastMessageAt"]
    },
    "messages": {
      ".indexOn": ["createdAt"]
    },
    "friendRequests": {
      ".indexOn": ["createdAt"]
    },
    "friends": {
      ".indexOn": ["createdAt"]
    }
  }
}
```

## Hoặc thêm trực tiếp trong Firebase Console:

1. Vào Firebase Console → Realtime Database → Indexes tab
2. Thêm các index sau:

- **posts**: `uid`, `createdAt`
- **musics**: `uid`, `createdAt`
- **comments**: `postId`, `createdAt`
- **chats**: `lastMessageAt`
- **messages**: `createdAt`
- **friendRequests**: `createdAt`
- **friends**: `createdAt`

## Lưu ý:

- Index giúp tăng tốc độ query khi dùng `orderByChild()` và `equalTo()`
- Không ảnh hưởng đến security rules
- Có thể mất vài phút để Firebase tạo index

