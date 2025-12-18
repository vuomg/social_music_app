import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/friends_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/music_repository.dart';
import '../../models/message_model.dart';
import '../../models/post_model.dart';
import '../../models/music_model.dart';
import '../../widgets/music_picker_sheet.dart';
import '../../widgets/chat_music_card.dart';
import '../post_detail/post_detail_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;
  final String? friendAvatarUrl;

  const ChatRoomScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
    this.friendAvatarUrl,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final PostRepository _postRepository = PostRepository();
  final MusicRepository _musicRepository = MusicRepository();
  final TextEditingController _messageController = TextEditingController();
  String? _chatId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatId = await _chatRepository.getOrCreateChat(
        currentUser.uid,
        widget.friendUid,
      );
      setState(() {
        _chatId = chatId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _sendTextMessage() async {
    if (_chatId == null || _messageController.text.trim().isEmpty) {
      return;
    }

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatRepository.sendTextMessage(_chatId!, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
        );
      }
    }
  }

  Future<void> _sendMusicMessage(MusicModel music) async {
    if (_chatId == null) return;

    try {
      // Tìm post đầu tiên dùng music này (hoặc có thể gửi musicId trực tiếp)
      // Để đơn giản, tìm post đầu tiên có musicId này
      final posts = await _postRepository.streamPosts().first;
      final post = posts.firstWhere(
        (p) => p.musicId == music.musicId,
        orElse: () => throw Exception('Không tìm thấy post nào dùng nhạc này'),
      );
      
      await _chatRepository.sendMusicMessage(_chatId!, post.postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi nhạc: $e')),
        );
      }
    }
  }

  void _showMusicPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MusicPickerSheet(
        onSelect: (music) {
          _sendMusicMessage(music);
        },
      ),
    );
  }

  Future<PostModel?> _getPostById(String postId) async {
    try {
      final posts = await _postRepository.streamPosts().first;
      return posts.firstWhere(
        (p) => p.postId == postId,
        orElse: () => throw Exception('Post not found'),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _openPostDetail(String postId) async {
    try {
      final post = await _getPostById(postId);
      if (post != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy bài nhạc: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _chatId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.friendName),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Không thể tải chat')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.friendAvatarUrl != null
                  ? CachedNetworkImageProvider(widget.friendAvatarUrl!)
                  : null,
              child: widget.friendAvatarUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.friendName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatRepository.streamMessages(_chatId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn'),
                  );
                }

                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderUid == currentUser.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: message.type == 'text'
                            ? Text(
                                message.text ?? '',
                                style: const TextStyle(color: Colors.white),
                              )
                            : FutureBuilder<PostModel?>(
                                future: message.postId != null
                                    ? _getPostById(message.postId!)
                                    : Future.value(null),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError ||
                                      snapshot.data == null) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.music_note,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Không tìm thấy bài nhạc',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ChatMusicCard(
                                    post: snapshot.data!,
                                    isMe: isMe,
                                  );
                                },
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.music_note),
                  onPressed: _showMusicPicker,
                  tooltip: 'Gửi nhạc',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendTextMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

