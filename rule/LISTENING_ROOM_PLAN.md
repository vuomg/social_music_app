# Implementation Plan: Nhóm Chat Nghe Nhạc Realtime

## 📋 1. GOAL & SCOPE

### Mục tiêu
Tạo tính năng **Listening Party** (Phòng nghe nhạc) cho phép nhiều bạn bè cùng nghe 1 bài nhạc đồng thời và chat realtime.

### Những gì CÓ LÀM ✅
- [x] Tạo phòng nghe nhạc (1 host tạo)
- [x] Mời bạn bè vào phòng
- [x] Host chọn bài nhạc và điều khiển (play/pause)
- [x] Các thành viên khác tự động đồng bộ theo host
- [x] Chat realtime trong phòng
- [x] Hiển thị danh sách thành viên
- [x] Rời phòng / Đóng phòng

### Những gì KHÔNG LÀM ❌
- [ ] ~~Đồng bộ chính xác từng millisecond~~ (chỉ sync cơ bản)
- [ ] ~~Stream audio realtime~~ (dùng audioUrl có sẵn từ Firebase)
- [ ] ~~WebRTC / P2P connection~~
- [ ] ~~Video call / Screen share~~
- [ ] ~~Cho phép nhiều người cùng điều khiển~~
- [ ] ~~Quản lý queue nhạc phức tạp~~

---

## 👤 2. USER FLOW

### 2.1. Host tạo phòng
```
[Friends Tab] 
  → Nút "Tạo Phòng Nghe Nhạc" (+)
  → Chọn bạn bè để mời (checkbox list)
  → Nhập tên phòng (optional)
  → [Tạo Phòng]
  → Navigate to ListeningRoomScreen (as host)
```

### 2.2. Friend được mời
```
[Notification / Friend Request-like flow]
  → Nhận thông báo "X mời bạn vào phòng nghe nhạc"
  → [Tham gia] / [Từ chối]
  → Nếu tham gia → Navigate to ListeningRoomScreen (as member)
```

> **Đơn giản hóa cho đồ án sinh viên:**
> - Không làm push notification
> - Thay vào đó: **Tab "Phòng Nghe Nhạc"** hiển thị danh sách phòng đang có
> - User tap vào phòng → tham gia

### 2.3. Trong phòng
```
[ListeningRoomScreen]
  ├── Cover image (full screen background)
  ├── Thông tin bài nhạc (title, artist)
  ├── Play/Pause button (chỉ host có thể điều khiển)
  ├── Danh sách members (avatar nhỏ)
  ├── Chat box (ở bottom)
  └── Nút "Rời phòng" / "Đóng phòng" (nếu là host)
```

**Host actions:**
- Chọn bài nhạc (từ music library)
- Play/Pause
- Thay đổi bài
- Đóng phòng (kick all members)

**Member actions:**
- Nghe nhạc (auto-sync với host)
- Chat
- Rời phòng

### 2.4. Thoát phòng
```
Member: Tap "Rời phòng" → Confirmation → Remove from members → Navigate back
Host: Tap "Đóng phòng" → Confirmation → Delete room → Kick all → All navigate back
```

---

## 🎨 3. SCREEN / UI STRUCTURE

### 3.1. Cập nhật FriendsScreen
**Thay đổi:**
- Thêm **Tab thứ 4: "Phòng Nghe Nhạc"**
- TabController: `length: 3` → `length: 4`

**Tabs:**
1. Bạn bè (hiện có)
2. Lời mời (hiện có)
3. Tìm kiếm (hiện có)
4. **Phòng Nghe Nhạc** (mới) ⭐

**Tab 4 - Phòng Nghe Nhạc:**
```
[FAB: Tạo Phòng Mới]
[ListView: Danh sách phòng đang hoạt động]
  - Tên phòng
  - Host name
  - Số members (3/5)
  - Tap → Join room
```

### 3.2. CreateListeningRoomScreen (mới)
**Đường dẫn:** `lib/screens/listening_room/create_listening_room_screen.dart`

**UI:**
```
[AppBar: "Tạo Phòng Nghe Nhạc"]
[TextField: Tên phòng (optional, default: "{HostName}'s Room")]
[Section: Mời bạn bè]
  [Checkbox List: Danh sách bạn bè]
    ☐ Nguyễn Văn A
    ☐ Trần Thị B
    ☑ Lê Văn C (selected)
[ElevatedButton: Tạo Phòng và Bắt đầu]
```

### 3.3. ListeningRoomScreen (mới) ⭐ QUAN TRỌNG
**Đường dẫn:** `lib/screens/listening_room/listening_room_screen.dart`

**Layout:**
```
Stack(
  [Background: Cover image với blur]
  [Positioned - Top: AppBar transparent]
  [Positioned - Center: Music Controls]
    - Song title
    - Artist name
    - Play/Pause button (chỉ host)
    - "Đang đồng bộ..." (cho members)
  [Positioned - TopRight: Member avatars (row)]
  [Positioned - Bottom: Chat section]
    - Chat messages (ListView)
    - Input field + Send button
)
```

**States:**
- `isHost`: true/false (để hiển thị controls)
- `currentSong`: PostModel? (bài đang phát)
- `isPlaying`: bool (trạng thái phát nhạc)
- `members`: List<MemberModel> (danh sách members)
- `chatMessages`: List<MessageModel>

---

## 🗄️ 4. DATA MODEL (Đơn giản)

### 4.1. ListeningRoomModel
**Đường dẫn:** `lib/models/listening_room_model.dart`

```dart
class ListeningRoomModel {
  final String roomId;           // unique ID
  final String hostUid;          // người tạo phòng
  final String roomName;         // "Room của Minh"
  final Map<String, bool> members; // {uid: true, uid2: true}
  final String? currentSongId;   // postId đang phát
  final bool isPlaying;          // true/false
  final int? songStartedAt;      // timestamp khi bắt đầu phát (để sync)
  final int createdAt;           // timestamp tạo phòng
  
  // fromJson / toJson
}
```

**Firebase Database Structure:**
```
listeningRooms/
  {roomId}/
    hostUid: "user123"
    roomName: "Room của Minh"
    members:
      user123: true
      user456: true
    currentSongId: "post_abc"
    isPlaying: true
    songStartedAt: 1734567890000
    createdAt: 1734567800000
```

### 4.2. RoomChatMessageModel (Tái sử dụng MessageModel)
**Không cần model mới**, dùng lại `MessageModel` hiện có.

**Firebase Database Structure:**
```
listeningRoomMessages/
  {roomId}/
    {messageId}/
      senderUid: "user456"
      type: "text"
      text: "Bài này hay quá!"
      createdAt: 1734567850000
```

---

## 🎵 5. REALTIME MUSIC SYNC LOGIC (ĐƠN GIẢN!)

### 5.1. Ai điều khiển?
**Chỉ HOST:**
- Host tap nút "Chọn nhạc" → chọn bài từ music library → update `currentSongId`
- Host tap Play → update `isPlaying: true` + `songStartedAt: serverTimestamp`
- Host tap Pause → update `isPlaying: false`

**Members:**
- Không có nút điều khiển
- Hiển thị "Đang đồng bộ với {hostName}..."

### 5.2. Cách đồng bộ?

#### Phương pháp: **Timestamp-based Sync** (CƠ BẢN)

**Nguyên lý:**
1. Host bấm Play → lưu `songStartedAt = serverTimestamp()`
2. Members listen realtime → nhận `songStartedAt`
3. Members tính: `currentPosition = now() - songStartedAt`
4. Members seek đến `currentPosition` và play

**Code pseudo (trong ListeningRoomScreen):**

```dart
// Host play
void _onHostPlaySong() async {
  await _roomRef.update({
    'isPlaying': true,
    'songStartedAt': ServerValue.timestamp,
  });
  
  // Play local
  await audioProvider.playPost(currentSong);
}

// Member sync (trong StreamBuilder listener)
void _syncWithHost(ListeningRoomModel room) async {
  if (!room.isPlaying) {
    // Dừng nhạc
    audioProvider.stop();
    return;
  }
  
  // Tính position hiện tại
  final now = DateTime.now().millisecondsSinceEpoch;
  final startedAt = room.songStartedAt ?? now;
  final elapsedMs = now - startedAt;
  final position = Duration(milliseconds: elapsedMs);
  
  // Play và seek
  await audioProvider.playPost(currentSong);
  await audioProvider.seek(position);
}
```

### 5.3. Độ chính xác?
**Chấp nhận được:**
- Sai lệch **±1-2 giây** là OK (do network delay)
- Không cần resync liên tục (chỉ sync khi có event: play/pause/change song)
- Nếu member vào muộn → sync vào đúng vị trí hiện tại của bài hát

**KHÔNG cần:**
- Sync mỗi giây
- Compensate network latency
- Buffer management

---

## 💬 6. CHAT REALTIME FLOW

### 6.1. Gửi tin nhắn
```dart
Future<void> sendMessage(String roomId, String text) async {
  final messageRef = _dbService.listeningRoomMessagesRef(roomId).push();
  await messageRef.set({
    'senderUid': currentUser.uid,
    'type': 'text',
    'text': text,
    'createdAt': ServerValue.timestamp,
  });
}
```

### 6.2. Nhận tin nhắn (StreamBuilder)
```dart
StreamBuilder<List<MessageModel>>(
  stream: _chatRepo.streamRoomMessages(roomId),
  builder: (context, snapshot) {
    final messages = snapshot.data ?? [];
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderUid == currentUser.uid;
        return ChatBubble(message: msg, isMe: isMe);
      },
    );
  },
)
```

### 6.3. Chat UI
**Giống ChatRoomScreen hiện có:**
- ListView messages (scroll to bottom)
- TextField input + Send button
- Chat bubble (left: other, right: me)

---

## 🔧 7. STATE MANAGEMENT APPROACH

### Sử dụng: **Provider + setState** (CƠ BẢN)

**Provider cần:**
1. **AudioPlayerProvider** (đã có) ✅
   - Phát/dừng nhạc
   - Seek

2. **ListeningRoomProvider** (mới)
   - Store current room data
   - Handle join/leave room
   - Sync music với host

**setState:**
- Trong ListeningRoomScreen để update local UI
- Ví dụ: chat messages, member list

**KHÔNG DÙNG:**
- ❌ Bloc
- ❌ Redux
- ❌ GetX
- ❌ Riverpod (nâng cao)

---

## 📁 8. FILES TO CREATE / MODIFY

### 8.1. Files mới tạo

#### Models:
- ✨ `lib/models/listening_room_model.dart`
  - ListeningRoomModel class (fromJson, toJson)

#### Repositories:
- ✨ `lib/repositories/listening_room_repository.dart`
  - createRoom(hostUid, roomName, invitedUids)
  - streamRooms()
  - streamRoom(roomId)
  - joinRoom(roomId, uid)
  - leaveRoom(roomId, uid)
  - closeRoom(roomId)
  - updateMusicState(roomId, songId, isPlaying, startedAt)
  - sendRoomMessage(roomId, text)
  - streamRoomMessages(roomId)

#### Providers:
- ✨ `lib/providers/listening_room_provider.dart`
  - Manage current room state
  - Auto-sync logic

#### Screens:
- ✨ `lib/screens/listening_room/create_listening_room_screen.dart`
  - Form tạo phòng + mời bạn bè
- ✨ `lib/screens/listening_room/listening_room_screen.dart`
  - Main screen phòng nghe nhạc
- ✨ `lib/screens/listening_room/widgets/member_avatar_list.dart`
  - Hiển thị avatars của members
- ✨ `lib/screens/listening_room/widgets/room_chat_section.dart`
  - Chat UI cho phòng

### 8.2. Files chỉnh sửa

#### Services:
- ✏️ `lib/services/realtime_db_service.dart`
  - Thêm method: `listeningRoomsRef()`, `listeningRoomMessagesRef(roomId)`

#### Screens:
- ✏️ `lib/screens/friends/friends_screen.dart`
  - Thay đổi TabController: `length: 3` → `length: 4`
  - Thêm tab "Phòng Nghe Nhạc"
  - Thêm `_buildListeningRoomsTab()` method

#### App:
- ✏️ `lib/app/app.dart`
  - Thêm ListeningRoomProvider vào MultiProvider

### 8.3. Tổng số files
- **Tạo mới:** 6 files
- **Chỉnh sửa:** 3 files
- **Tổng cộng:** 9 files

---

## ⚠️ 9. EDGE CASES & LIMITATIONS

### 9.1. Mạng chậm
**Hiện tượng:**
- Member nhận event muộn → nhạc không sync

**Giải pháp đơn giản:**
- Hiển thị "Đang kết nối..." khi đang load
- Cho phép member tap "Resync" để tính lại position
- Chấp nhận sai lệch 1-2 giây

**Code:**
```dart
TextButton(
  onPressed: () => _syncWithHost(currentRoom),
  child: Text('⟳ Đồng bộ lại'),
)
```

### 9.2. User vào muộn
**Hiện tượng:**
- User join room khi bài đã phát được 1 phút

**Giải pháp:**
- Tính `elapsedTime = now - songStartedAt`
- Seek đến `elapsedTime` trước khi play
- Member nghe từ giữa bài (OK, giống Spotify)

### 9.3. Host thoát
**Hiện tượng:**
- Host rời phòng → không có ai điều khiển

**Giải pháp đơn giản:**
- **Option 1 (đề xuất):** Host phải "Đóng phòng" để kick all
- **Option 2:** Auto chọn member khác làm host (phức tạp hơn)

**Cho đồ án sinh viên:**
- Dùng Option 1
- Hiển thị warning: "Bạn là host. Nếu rời phòng sẽ đóng phòng cho tất cả."

### 9.4. Phòng trống
**Hiện tượng:**
- Tất cả members đều rời → phòng còn lại rỗng

**Giải pháp:**
- Check: nếu `members.length == 0` → auto delete room
- Cloud Function (optional) để cleanup rooms cũ (sau 24h không hoạt động)

**Cho đồ án sinh viên:**
- Để đơn giản: Host phải "Đóng phòng" manually
- KHÔNG implement auto-cleanup (để tránh phức tạp)

### 9.5. Bài hát kết thúc
**Hiện tượng:**
- Bài phát xong → im lặng

**Giải pháp:**
- Host phải manually chọn bài tiếp theo
- (Optional) Host setup playlist → auto next song

**Cho đồ án sinh viên:**
- Chỉ làm manual selection (đơn giản hơn)

---

## 🧪 10. VERIFICATION / TESTING PLAN

### 10.1. Test Manual (cho Sinh viên)

#### Test 1: Tạo phòng
**Steps:**
1. Mở app → Friends tab → Tab "Phòng Nghe Nhạc"
2. Tap FAB "Tạo Phòng"
3. Nhập tên phòng: "Test Room"
4. Chọn 2 bạn bè từ checkbox list
5. Tap "Tạo Phòng"

**Expected:**
- ✅ Navigate đến ListeningRoomScreen
- ✅ Hiển thị "Test Room"
- ✅ Hiển thị 3 members (host + 2 friends)
- ✅ Host có nút "Chọn nhạc" và "Đóng phòng"

#### Test 2: Chọn nhạc và phát (Host)
**Steps:**
1. Trong ListeningRoomScreen (as host)
2. Tap "Chọn nhạc" → chọn bài từ music library
3. Tap Play button

**Expected:**
- ✅ Hiển thị cover image + song info
- ✅ Nhạc bắt đầu phát
- ✅ Firebase update: `isPlaying: true`, `songStartedAt: timestamp`

#### Test 3: Join phòng (Member)
**Steps:**
1. Mở app trên device 2 (đăng nhập với friend account)
2. Friends tab → Tab "Phòng Nghe Nhạc"
3. Thấy "Test Room" trong list
4. Tap vào → Join room

**Expected:**
- ✅ Navigate đến ListeningRoomScreen
- ✅ Nhạc tự động phát (từ vị trí hiện tại)
- ✅ KHÔNG có nút điều khiển (chỉ xem)
- ✅ Hiển thị "Đang đồng bộ với {hostName}..."

#### Test 4: Chat realtime
**Steps:**
1. Host gửi message: "Test chat"
2. Member gửi message: "Reply test"

**Expected:**
- ✅ Messages hiển thị realtime trên cả 2 devices
- ✅ Host messages align right, Member messages align left

#### Test 5: Host pause
**Steps:**
1. Host tap Pause button

**Expected:**
- ✅ Nhạc dừng trên host
- ✅ Nhạc dừng trên member sau 1-2 giây (realtime update)

#### Test 6: Rời phòng (Member)
**Steps:**
1. Member tap "Rời phòng"
2. Confirm dialog → Yes

**Expected:**
- ✅ Navigate back to Friends screen
- ✅ Member biến mất khỏi member list (trên host)

#### Test 7: Đóng phòng (Host)
**Steps:**
1. Host tap "Đóng phòng"
2. Confirm dialog → Yes

**Expected:**
- ✅ All members bị kick (navigate back)
- ✅ Room bị xóa khỏi Firebase
- ✅ Host navigate back

### 10.2. Test Checklist

**Functionality:**
- [ ] Tạo phòng thành công
- [ ] Invite friends hiển thị danh sách bạn bè
- [ ] Join phòng từ tab "Phòng Nghe Nhạc"
- [ ] Host chọn bài và phát → Members nghe đồng bộ
- [ ] Host pause → Members dừng
- [ ] Chat realtime hoạt động
- [ ] Rời phòng (member) OK
- [ ] Đóng phòng (host) OK

**Edge Cases:**
- [ ] Member vào muộn → sync vào đúng vị trí
- [ ] Mạng chậm → hiển thị loading
- [ ] Phòng không có members → có thể delete
- [ ] Bài hát kết thúc → host chọn bài mới

**UI/UX:**
- [ ] Cover image hiển thị đẹp
- [ ] Member avatars hiển thị trong phòng
- [ ] Chat UI dễ dùng
- [ ] Loading states rõ ràng
- [ ] Error messages hữu ích

---

## 📚 11. IMPLEMENTATION ORDER (Đề xuất)

### Phase 1: Foundation (2-3 ngày)
1. Tạo `ListeningRoomModel`
2. Tạo `ListeningRoomRepository` (CRUD cơ bản)
3. Update `realtime_db_service.dart` (add refs)
4. Test repository với Firebase console

### Phase 2: Basic UI (2-3 ngày)
1. Tạo tab "Phòng Nghe Nhạc" trong FriendsScreen
2. Tạo `CreateListeningRoomScreen` (form đơn giản)
3. Tạo `ListeningRoomScreen` (chỉ hiển thị info, chưa có music)
4. Test navigation flow

### Phase 3: Music Sync (2-3 ngày)
1. Tích hợp AudioPlayerProvider
2. Implement host controls (play/pause/select song)
3. Implement member auto-sync logic
4. Test music sync với 2 devices

### Phase 4: Chat (1-2 ngày)
1. Reuse logic từ ChatRoomScreen
2. Tạo RoomChatSection widget
3. Implement send/receive messages
4. Test chat realtime

### Phase 5: Polish & Edge Cases (1-2 ngày)
1. Handle member join/leave
2. Handle host close room
3. Add loading/error states
4. Add confirmations
5. Test all edge cases

**Tổng thời gian:** ~8-13 ngày (tùy kinh nghiệm)

---

## 🎓 12. TIPS CHO SINH VIÊN

### 12.1. Bắt đầu từ đâu?
1. Đọc kỹ plan này (30 phút)
2. Vẽ UI flow trên giấy (15 phút)
3. Tạo model + repository trước (code backend logic)
4. Test với Firebase console (đảm bảo data đúng)
5. Rồi mới làm UI

### 12.2. Debug tips
- Dùng `print()` để log events (join room, sync music, etc.)
- Check Firebase console để xem data realtime
- Test với 2 emulators hoặc 1 emulator + 1 physical device

### 12.3. Nếu bị stuck
**"Music không sync":**
- Check: `songStartedAt` có được update không?
- Check: Member có nhận được event từ Firebase không?
- Print `elapsedTime` để xem tính toán có đúng không

**"Chat không hiển thị":**
- Check: StreamBuilder có connect đúng roomId không?
- Check: Messages có được lưu vào Firebase không?
- Check: fromJson có throw error không?

**"App crash khi join/leave room":**
- Check: dispose AudioPlayer đúng chưa?
- Check: mounted trước khi setState
- Check: null safety (?, !)

### 12.4. Tài liệu tham khảo
- [Firebase Realtime Database - Flutter](https://firebase.google.com/docs/database/flutter/start)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [Provider Package](https://pub.dev/packages/provider)

---

## ✅ 13. SUMMARY

### Điểm mạnh của plan này:
- ✅ **Đơn giản**: Không dùng kỹ thuật phức tạp
- ✅ **Thực tế**: Dựa trên code hiện có (ChatRoom, AudioPlayer)
- ✅ **Dễ hiểu**: Mỗi bước đều giải thích rõ
- ✅ **Khả thi**: Sinh viên năm 2-3 Flutter làm được trong 2 tuần

### Hạn chế (chấp nhận được):
- ⚠️ Sync không chính xác tuyệt đối (±1-2s)
- ⚠️ Không có push notification
- ⚠️ Host rời phòng → đóng phòng (không auto promote)
- ⚠️ Không có playlist/queue

### Kết luận:
Plan này phù hợp cho **đồ án sinh viên**, cân bằng giữa:
- **Tính năng đầy đủ** (tạo phòng, sync nhạc, chat)
- **Kỹ thuật đơn giản** (Firebase + Provider + just_audio)
- **Thời gian hợp lý** (2 tuần)

---

**Người lập plan:** Antigravity AI  
**Ngày tạo:** 2026-01-08  
**Dành cho:** Social Music App - Đồ án Flutter  
**Trạng thái:** Ready to implement ✅
