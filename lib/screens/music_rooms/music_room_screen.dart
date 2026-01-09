import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/music_room_model.dart';
import '../../models/music_model.dart';
import '../../repositories/music_room_repository.dart';
import '../../repositories/music_repository.dart';
import '../../providers/audio_player_provider.dart';

class MusicRoomScreen extends StatefulWidget {
  final String roomId;

  const MusicRoomScreen({super.key, required this.roomId});

  @override
  State<MusicRoomScreen> createState() => _MusicRoomScreenState();
}

class _MusicRoomScreenState extends State<MusicRoomScreen> {
  final MusicRoomRepository _roomRepository = MusicRoomRepository();
  final MusicRepository _musicRepository = MusicRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasJoined = false;
  String? _currentPlayingMusicId;
  StreamSubscription<MusicRoom?>? _roomSubscription;

  @override
  void initState() {
    super.initState();
    _joinRoom();
    _listenToRoomChanges();
  }

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _roomRepository.joinRoom(
        roomId: widget.roomId,
        uid: user.uid,
        displayName: user.displayName ?? 'Unknown',
        avatarUrl: user.photoURL,
      );
      setState(() => _hasJoined = true);
    } catch (e) {
      debugPrint('Error joining room: $e');
    }
  }

  void _listenToRoomChanges() {
    _roomSubscription = _roomRepository.streamRoom(widget.roomId).listen((room) {
      if (room == null || !mounted) return;

      final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

      // Auto-play when music changes
      if (room.musicId != null && room.musicId != _currentPlayingMusicId) {
        _currentPlayingMusicId = room.musicId;
        
        if (room.audioUrl != null) {
          audioProvider.playUrl(
            room.audioUrl!,
            title: room.musicTitle,
            author: 'Room ${widget.roomId}',
            postId: widget.roomId,
          );
        }
      }
      
      // Sync play/pause state
      if (room.musicId == _currentPlayingMusicId) {
        if (room.isPlaying && !audioProvider.isPlaying) {
          // Resume playback
          audioProvider.audioPlayer.play();
        } else if (!room.isPlaying && audioProvider.isPlaying) {
          // Pause playback
          audioProvider.audioPlayer.pause();
        }
      }
    });
  }

  Future<void> _leaveRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _roomRepository.leaveRoom(
        roomId: widget.roomId,
        uid: user.uid,
      );
    } catch (e) {
      debugPrint('Error leaving room: $e');
    }
  }

  Future<void> _selectMusic() async {
    final selectedMusic = await showModalBottomSheet<MusicModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MusicPickerSheet(),
    );

    if (selectedMusic != null) {
      // Update Firebase - the listener will auto-play
      await _roomRepository.updateMusic(
        roomId: widget.roomId,
        musicId: selectedMusic.musicId,
        musicTitle: selectedMusic.title,
        audioUrl: selectedMusic.audioUrl,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseDatabase.instance
          .ref('musicRooms/${widget.roomId}/messages')
          .push()
          .set({
        'uid': user.uid,
        'displayName': user.displayName ?? 'Unknown',
        'message': text,
        'timestamp': ServerValue.timestamp,
      });

      _messageController.clear();
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    // Stop audio FIRST before disposing
    try {
      final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
      // Only stop if current playing is from this room
      if (audioProvider.currentPost?.postId == widget.roomId) {
        audioProvider.stop();
        debugPrint('🔇 Stopped room ${widget.roomId} audio');
      }
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
    
    _roomSubscription?.cancel();
    _leaveRoom();
    _messageController.dispose();
    _scrollController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Phòng ${widget.roomId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note),
            onPressed: _selectMusic,
            tooltip: 'Chọn nhạc',
          ),
        ],
      ),
      body: StreamBuilder<MusicRoom?>(
        stream: _roomRepository.streamRoom(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final room = snapshot.data;
          if (room == null) {
            return const Center(child: Text('Phòng không tồn tại'));
          }

          final isHost = user?.uid == room.hostUid;

          return Column(
            children: [
              // Current Music Card
              if (room.musicTitle != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade700, Colors.purple.shade900],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.music_note, size: 48, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.musicTitle!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  room.isPlaying ? Icons.play_circle : Icons.pause_circle,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  room.isPlaying ? 'Đang phát' : 'Tạm dừng',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isHost)
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, color: Colors.white),
                          onPressed: _selectMusic,
                          tooltip: 'Đổi nhạc',
                        ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.music_off, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có nhạc',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                      if (isHost) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _selectMusic,
                          icon: const Icon(Icons.add),
                          label: const Text('Chọn nhạc'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Members count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      '${room.memberCount} thành viên',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Chat messages
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('musicRooms/${widget.roomId}/messages')
                      .onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return Center(
                        child: Text(
                          'Chưa có tin nhắn\nGửi tin nhắn đầu tiên!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    final messagesMap = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map,
                    );

                    final messages = messagesMap.entries.map((e) {
                      final data = Map<String, dynamic>.from(e.value as Map);
                      return {
                        'id': e.key,
                        ...data,
                      };
                    }).toList();

                    // Sort by timestamp descending (newest first for reverse list)
                    messages.sort((a, b) => (b['timestamp'] as int? ?? 0)
                        .compareTo(a['timestamp'] as int? ?? 0));

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['uid'] == user?.uid;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.purple : Colors.grey[800],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    msg['displayName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (!isMe) const SizedBox(height: 4),
                                Text(
                                  msg['message'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(top: BorderSide(color: Colors.grey[800]!)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatJoinTime(int timestamp) {
    final joinTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(joinTime);

    if (diff.inMinutes < 1) {
      return 'Vừa tham gia';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else {
      return '${diff.inHours} giờ trước';
    }
  }
}

// Music Picker Bottom Sheet
class _MusicPickerSheet extends StatelessWidget {
  final MusicRepository _musicRepository = MusicRepository();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Chọn nhạc',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MusicModel>>(
              stream: _musicRepository.streamAllMusic(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Chưa có nhạc'));
                }

                final musics = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: musics.length,
                  itemBuilder: (context, index) {
                    final music = musics[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                        title: Text(music.title),
                        subtitle: Text(music.ownerName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, music),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
