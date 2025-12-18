# FLOW – ĐĂNG BÀI NHẠC (UPLOAD + SAVE)
## Sequence / Steps để Cursor AI code chuẩn

---

## A) Input người dùng
- Title (required)
- Caption (optional)
- Genre (required)
- Audio file (required)
- Cover image (optional)

---

## B) Tạo ID & chuẩn bị dữ liệu
- [ ] postId = uuid.v4()
- [ ] now = ServerValue.timestamp
- [ ] uid = FirebaseAuth.currentUser.uid
- [ ] authorName/avatar lấy từ users/{uid}

---

## C) Upload Storage
1) Upload audio
- [ ] audioPath = `audio/{uid}/{postId}.{ext}`
- [ ] PutFile(audioFile) → lấy `audioUrl = getDownloadURL()`

2) Upload cover (nếu có)
- [ ] coverPath = `covers/{uid}/{postId}.jpg`
- [ ] PutFile(coverFile) → lấy `coverUrl = getDownloadURL()`

---

## D) Ghi Realtime Database
Write `posts/{postId}`:
- uid, authorName, authorAvatarUrl
- title, caption, genre
- audioUrl, audioPath
- coverUrl, coverPath
- createdAt = ServerValue.timestamp
- commentCount = 0
- reactionSummary = { like:0, love:0, haha:0, wow:0, sad:0, angry:0 }

---

## E) Error handling
- Nếu upload audio fail → show error, không ghi post
- Nếu upload cover fail → cho phép:
  - [ ] retry cover
  - hoặc [ ] skip cover và vẫn đăng post
- Nếu ghi DB fail → rollback:
  - [ ] xóa audio/cover đã upload (Storage delete by path)

---

## F) DONE criteria
- Feed hiển thị bài mới ngay (stream)
- PostDetail mở được, phát nhạc được
