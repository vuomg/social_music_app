import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/friends_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/chat_model.dart';
import '../../models/friend_model.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<String?> _getOtherUserInfo(
    ChatModel chat,
    String currentUid,
  ) async {
    final otherUid = chat.members.keys.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );
    if (otherUid.isEmpty) return null;

    final userRepository = UserRepository();
    final user = await userRepository.getUser(otherUid);
    return user?.displayName;
  }

  Future<String?> _getOtherUserAvatar(
    ChatModel chat,
    String currentUid,
  ) async {
    final otherUid = chat.members.keys.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );
    if (otherUid.isEmpty) return null;

    final userRepository = UserRepository();
    final user = await userRepository.getUser(otherUid);
    return user?.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    final chatRepository = ChatRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatRepository.streamChats(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(child: Text('Chưa có cuộc trò chuyện'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return FutureBuilder<Map<String, String?>>(
                future: Future.wait([
                  _getOtherUserInfo(chat, currentUser.uid),
                  _getOtherUserAvatar(chat, currentUser.uid),
                ]).then((results) => {
                  'name': results[0],
                  'avatar': results[1],
                }),
                builder: (context, userSnapshot) {
                  final otherName = userSnapshot.data?['name'] ?? 'Unknown';
                  final otherAvatar = userSnapshot.data?['avatar'];

                  final otherUid = chat.members.keys.firstWhere(
                    (uid) => uid != currentUser.uid,
                    orElse: () => '',
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: otherAvatar != null
                            ? CachedNetworkImageProvider(otherAvatar)
                            : null,
                        child: otherAvatar == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(otherName),
                      subtitle: Text(
                        chat.lastMessage ?? 'Chưa có tin nhắn',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(chat.lastMessageAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              friendUid: otherUid,
                              friendName: otherName,
                              friendAvatarUrl: otherAvatar,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

