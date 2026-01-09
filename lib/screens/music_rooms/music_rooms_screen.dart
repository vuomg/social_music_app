import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/music_room_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../repositories/music_room_repository.dart';
import 'music_room_screen.dart';

class MusicRoomsScreen extends StatefulWidget {
  const MusicRoomsScreen({super.key});

  @override
  State<MusicRoomsScreen> createState() => _MusicRoomsScreenState();
}

class _MusicRoomsScreenState extends State<MusicRoomsScreen> {
  final MusicRoomRepository _roomRepository = MusicRoomRepository();
  final TextEditingController _roomIdController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final roomId = await _roomRepository.createRoom(
        hostUid: user.uid,
        hostName: user.displayName ?? 'Unknown',
        hostAvatarUrl: user.photoURL,
      );

      if (mounted) {
        // Show room ID dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Phòng đã tạo!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mã phòng của bạn:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple, width: 2),
                  ),
                  child: Text(
                    roomId,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chia sẻ mã này với bạn bè để họ tham gia!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: roomId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã phòng')),
                  );
                },
                child: const Text('Sao chép'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Navigate to room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicRoomScreen(roomId: roomId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã phòng')),
      );
      return;
    }

    if (roomId.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(roomId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã phòng phải là 4 chữ số')),
      );
      return;
    }

    try {
      // Check if room exists
      final room = await _roomRepository.getRoom(roomId);
      if (room == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy phòng')),
          );
        }
        return;
      }

      // Navigate to room
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicRoomScreen(roomId: roomId),
          ),
        );
        
        _roomIdController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng Nhạc'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Icon(
              Icons.music_note_rounded,
              size: 80,
              color: Colors.purple.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Nghe Nhạc Cùng Nhau',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo phòng mới hoặc tham gia phòng bằng mã',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            
            // Create Room Button
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createRoom,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline, size: 28),
              label: Text(
                _isCreating ? 'Đang tạo...' : 'Tạo Phòng Mới',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[700])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'HOẶC',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[700])),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Join Room Section
            Text(
              'Nhập mã phòng (4 chữ số)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _roomIdController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 16,
              ),
              decoration: InputDecoration(
                hintText: '____',
                counterText: '',
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _joinRoom,
              icon: const Icon(Icons.login_rounded),
              label: const Text(
                'Tham Gia Phòng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
