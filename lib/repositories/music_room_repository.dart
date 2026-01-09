import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/music_room_model.dart';

class MusicRoomRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Generate unique 4-digit room ID
  Future<String> _generateUniqueRoomId() async {
    final random = Random();
    int attempts = 0;
    const maxAttempts = 100;

    while (attempts < maxAttempts) {
      // Generate 4-digit number (1000-9999)
      final roomId = (1000 + random.nextInt(9000)).toString();
      
      // Check if exists
      final snapshot = await _db.child('musicRooms').child(roomId).get();
      if (!snapshot.exists) {
        return roomId;
      }
      
      attempts++;
    }

    throw Exception('Could not generate unique room ID after $maxAttempts attempts');
  }

  /// Create a new music room
  Future<String> createRoom({
    required String hostUid,
    required String hostName,
    String? hostAvatarUrl,
  }) async {
    final roomId = await _generateUniqueRoomId();
    final now = DateTime.now().millisecondsSinceEpoch;

    final roomData = {
      'roomId': roomId,
      'hostUid': hostUid,
      'hostName': hostName,
      'hostAvatarUrl': hostAvatarUrl,
      'musicId': null,
      'musicTitle': null,
      'audioUrl': null,
      'isPlaying': false,
      'currentPositionMs': 0,
      'createdAt': now,
      'updatedAt': now,
      'members': {
        hostUid: {
          'displayName': hostName,
          'avatarUrl': hostAvatarUrl,
          'joinedAt': now,
        }
      },
    };

    await _db.child('musicRooms').child(roomId).set(roomData);
    return roomId;
  }

  /// Join an existing room
  Future<void> joinRoom({
    required String roomId,
    required String uid,
    required String displayName,
    String? avatarUrl,
  }) async {
    final snapshot = await _db.child('musicRooms').child(roomId).get();
    
    if (!snapshot.exists) {
      throw Exception('Room $roomId not found');
    }

    final memberData = {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'joinedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _db.child('musicRooms').child(roomId).child('members').child(uid).set(memberData);
    await _db.child('musicRooms').child(roomId).child('updatedAt').set(DateTime.now().millisecondsSinceEpoch);
  }

  /// Leave a room
  Future<void> leaveRoom({
    required String roomId,
    required String uid,
  }) async {
    await _db.child('musicRooms').child(roomId).child('members').child(uid).remove();
    
    // Check if room is empty
    final snapshot = await _db.child('musicRooms').child(roomId).child('members').get();
    if (!snapshot.exists || (snapshot.value as Map).isEmpty) {
      // Delete room if no members
      await _db.child('musicRooms').child(roomId).remove();
    } else {
      await _db.child('musicRooms').child(roomId).child('updatedAt').set(DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Update room music
  Future<void> updateMusic({
    required String roomId,
    required String musicId,
    required String musicTitle,
    required String audioUrl,
  }) async {
    await FirebaseDatabase.instance
        .ref('musicRooms/$roomId')
        .update({
      'musicId': musicId,
      'musicTitle': musicTitle,
      'audioUrl': audioUrl,
      'isPlaying': true, // Auto-play when music selected
      'currentPositionMs': 0, // Reset position
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Update playback state (play/pause + position)
  Future<void> updatePlaybackState({
    required String roomId,
    required bool isPlaying,
    int? currentPositionMs,
  }) async {
    final updates = <String, dynamic>{
      'isPlaying': isPlaying,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (currentPositionMs != null) {
      updates['currentPositionMs'] = currentPositionMs;
    }

    await FirebaseDatabase.instance
        .ref('musicRooms/$roomId')
        .update(updates);
  }

  /// Stream room data
  Stream<MusicRoom?> streamRoom(String roomId) {
    return _db.child('musicRooms').child(roomId).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return MusicRoom.fromJson(data);
    });
  }

  /// Get room by ID
  Future<MusicRoom?> getRoom(String roomId) async {
    final snapshot = await _db.child('musicRooms').child(roomId).get();
    if (!snapshot.exists) return null;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return MusicRoom.fromJson(data);
  }

  /// Stream all active rooms (optional - for discovery)
  Stream<List<MusicRoom>> streamAllRooms() {
    return _db.child('musicRooms').onValue.map((event) {
      if (!event.snapshot.exists) return <MusicRoom>[];
      
      final rooms = <MusicRoom>[];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      
      data.forEach((key, value) {
        final roomData = Map<String, dynamic>.from(value as Map);
        rooms.add(MusicRoom.fromJson(roomData));
      });
      
      return rooms;
    });
  }
}
