import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class SendMusicSheet extends StatefulWidget {
  final PostModel post;

  const SendMusicSheet({super.key, required this.post});

  @override
  State<SendMusicSheet> createState() => _SendMusicSheetState();
}

class _SendMusicSheetState extends State<SendMusicSheet> {
  final UserRepository _userRepo = UserRepository();
  List<UserModel> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      // Vì là Fresher level, tôi sẽ lấy tất cả users 
      // Trong thực tế sẽ chỉ lấy danh sách bạn bè (followers/following)
      final users = await _userRepo.getAllUsers();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      
      if (mounted) {
        setState(() {
          _friends = users.where((u) => u.uid != currentUid).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToFriend(UserModel friend) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderName = currentUser.displayName ?? 'Một người bạn';
    
    // Tạo thông báo trong Realtime Database
    final notificationRef = FirebaseDatabase.instance
        .ref('notifications/${friend.uid}')
        .push();

    await notificationRef.set({
      'title': '$senderName đã gửi cho bạn một bài hát',
      'body': 'Đang nghe: ${widget.post.musicTitle}',
      'isRead': false,
      'createdAt': ServerValue.timestamp,
      'type': 'share_music',
      'musicId': widget.post.musicId, // Để bấm vào thông báo có thể mở nhạc
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi cho ${friend.displayName} 📬')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gửi "${widget.post.musicTitle}" cho...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                    ? const Center(child: Text('Không tìm thấy bạn bè nào'))
                    : ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: friend.avatarUrl != null 
                                  ? NetworkImage(friend.avatarUrl!) 
                                  : null,
                              child: friend.avatarUrl == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(friend.displayName),
                            trailing: ElevatorButton(
                              onPressed: () => _sendToFriend(friend),
                              child: const Text('Gửi'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Widget nút phụ trợ kiểu Fresher
class ElevatorButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const ElevatorButton({super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: child,
    );
  }
}
