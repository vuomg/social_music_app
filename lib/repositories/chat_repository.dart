import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/realtime_db_service.dart';
import 'friends_repository.dart';

class ChatRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();

  /// Stream danh sách chat của user
  Stream<List<ChatModel>> streamChats(String uid) {
    return _dbService
        .chatsRef()
        .orderByChild('lastMessageAt')
        .onValue
        .asBroadcastStream()
        .map((event) {
      if (event.snapshot.value == null) {
        return <ChatModel>[];
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<ChatModel> chats = [];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            final chat = ChatModel.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            );
            // Chỉ lấy chat mà user là member
            if (chat.members[uid] == true) {
              chats.add(chat);
            }
          } catch (e) {
            // Skip invalid chats
          }
        }
      });

      chats.sort((a, b) {
        final aTime = a.lastMessageAt ?? 0;
        final bTime = b.lastMessageAt ?? 0;
        return bTime.compareTo(aTime);
      });

      return chats;
    });
  }

  /// Tạo hoặc lấy chat giữa 2 user
  Future<String> getOrCreateChat(String uidA, String uidB) async {
    final chatId = FriendsRepository.buildChatId(uidA, uidB);
    final chatRef = _dbService.chatsRef().child(chatId);

    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'members': {
          uidA: true,
          uidB: true,
        },
        'lastMessage': null,
        'lastMessageAt': null,
      });
    }

    return chatId;
  }

  /// Stream messages của chat
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _dbService
        .messagesRef(chatId)
        .orderByChild('createdAt')
        .onValue
        .asBroadcastStream()
        .map((event) {
      if (event.snapshot.value == null) {
        return <MessageModel>[];
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<MessageModel> messages = [];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            messages.add(MessageModel.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            ));
          } catch (e) {
            // Skip invalid messages
          }
        }
      });

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  /// Gửi text message
  Future<void> sendTextMessage(String chatId, String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messageRef = _dbService.messagesRef(chatId).push();
    await messageRef.set({
      'senderUid': currentUser.uid,
      'type': 'text',
      'text': text,
      'createdAt': ServerValue.timestamp,
    });

    // Update lastMessage
    await _dbService.chatsRef().child(chatId).update({
      'lastMessage': text,
      'lastMessageAt': ServerValue.timestamp,
    });
  }

  /// Gửi music message
  Future<void> sendMusicMessage(String chatId, String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messageRef = _dbService.messagesRef(chatId).push();
    await messageRef.set({
      'senderUid': currentUser.uid,
      'type': 'music',
      'postId': postId,
      'createdAt': ServerValue.timestamp,
    });

    // Update lastMessage
    await _dbService.chatsRef().child(chatId).update({
      'lastMessage': '🎵 Đã gửi một bài nhạc',
      'lastMessageAt': ServerValue.timestamp,
    });
  }
}

