# FIREBASE SCHEMA – Realtime Database + Storage
## Flutter Music Social (Share Music)

---

## 1) Realtime Database Tree

```text
users/
  {uid}/
    displayName: string
    avatarUrl: string | null
    createdAt: number (timestamp)
    updatedAt: number (timestamp)

posts/
  {postId}/
    uid: string
    authorName: string
    authorAvatarUrl: string | null
    title: string
    caption: string
    genre: string
    audioUrl: string
    audioPath: string
    coverUrl: string | null
    coverPath: string | null
    createdAt: number (timestamp)
    updatedAt: number (timestamp)
    commentCount: number
    reactionSummary:
      like: number
      love: number
      haha: number
      wow: number
      sad: number
      angry: number

postReactions/
  {postId}/
    {uid}/
      type: "like" | "love" | "haha" | "wow" | "sad" | "angry"
      updatedAt: number (timestamp)

comments/
  {postId}/
    {commentId}/
      uid: string
      authorName: string
      authorAvatarUrl: string | null
      content: string
      createdAt: number (timestamp)
      updatedAt: number (timestamp)
2) Storage Paths
audio/{uid}/{postId}.{ext}
covers/{uid}/{postId}.jpg
avatars/{uid}/avatar.jpg

3) Field Rules / Notes

createdAt/updatedAt: dùng ServerValue.timestamp (Realtime DB)

postId/commentId: uuid v4

reactionSummary: luôn tồn tại đủ keys (like/love/haha/wow/sad/angry)

commentCount: integer >= 0

Khi xóa post: xóa posts/{postId}, comments/{postId}, postReactions/{postId}, file Storage (audio/cover)


---
