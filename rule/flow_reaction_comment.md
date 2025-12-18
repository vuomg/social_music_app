# FLOW – REACTION + COMMENT (Realtime Database Transactions)
## Mục tiêu: không lệch số reactionSummary/commentCount + realtime ổn định

---

## 0) Paths liên quan
- My reaction: `postReactions/{postId}/{uid}`
- Summary counts:
  - `posts/{postId}/reactionSummary/like`
  - `posts/{postId}/reactionSummary/love`
  - ...
- Comments:
  - `comments/{postId}/{commentId}`
- Comment count: `posts/{postId}/commentCount`

---

## 1) Reaction – Set / Change / Remove

### A) Read trạng thái hiện tại
- Đọc `postReactions/{postId}/{uid}` -> oldType (nullable)

### B) Case 1: user chưa có reaction (oldType == null)
1) write:
- set `postReactions/{postId}/{uid}` = { type: newType, updatedAt: ServerValue.timestamp }

2) transaction:
- `posts/{postId}/reactionSummary/{newType}` += 1

### C) Case 2: user đổi reaction (oldType != null && oldType != newType)
1) update:
- update `postReactions/{postId}/{uid}/type` = newType
- update `postReactions/{postId}/{uid}/updatedAt` = ServerValue.timestamp

2) transaction (2 nhánh):
- `posts/{postId}/reactionSummary/{oldType}` -= 1 (min 0)
- `posts/{postId}/reactionSummary/{newType}` += 1

> Implementation gợi ý: dùng `runTransaction()` trên node `posts/{postId}/reactionSummary`
- đọc Map hiện tại
- cập nhật 2 keys
- clamp về >= 0
- commit

### D) Case 3: remove reaction (optional)
1) delete:
- remove `postReactions/{postId}/{uid}`

2) transaction:
- `posts/{postId}/reactionSummary/{oldType}` -= 1 (min 0)

---

## 2) Comment – Add / Delete

### A) Add Comment
1) tạo id:
- commentId = uuid.v4()

2) write:
- set `comments/{postId}/{commentId}`:
  - uid = auth.uid
  - authorName/avatarUrl (from users/{uid})
  - content = input
  - createdAt = ServerValue.timestamp
  - updatedAt = null

3) transaction:
- `posts/{postId}/commentCount` += 1

### B) Delete Comment (optional)
1) read comment để kiểm tra owner (client-side):
- uid must match auth.uid (server rules cũng đã chặn)

2) delete:
- remove `comments/{postId}/{commentId}`

3) transaction:
- `posts/{postId}/commentCount` -= 1 (min 0)

---

## 3) UI Rules
- Reaction:
  - Feed/PostDetail hiển thị summary + myReaction
  - Tapping reaction -> BottomSheet chọn type
  - Disable spam: debounce 300–500ms khi user chọn liên tục
- Comments:
  - Stream comments realtime
  - Send button disabled khi content rỗng hoặc đang gửi
  - Auto scroll xuống comment mới (optional)

---

## 4) Edge cases
- Nếu transaction fail: retry 1–2 lần
- Nếu summary key bị thiếu: init về 0 trước khi +/- 
- Nếu offline:
  - cho phép user thao tác (RTDB cache) hoặc show error (tùy MVP)
