import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/friend_request_model.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../services/realtime_db_service.dart';
import '../repositories/user_repository.dart';

class FriendsRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final UserRepository _userRepository = UserRepository();

  /// Build chatId từ 2 uid (sắp xếp rồi join bằng "_")
  static String buildChatId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Gửi friend request
  Future<void> sendFriendRequest(String toUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userModel = await _userRepository.getUser(currentUser.uid);
    if (userModel == null) return;

    final requestRef = _dbService.friendRequestsRef(toUid).child(currentUser.uid);
    await requestRef.set({
      'fromUid': currentUser.uid,
      'fromName': userModel.displayName,
      'fromAvatarUrl': userModel.avatarUrl,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Stream friend requests đến user
  Stream<List<FriendRequestModel>> streamFriendRequests(String uid) {
    return _dbService
        .friendRequestsRef(uid)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <FriendRequestModel>[];
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<FriendRequestModel> requests = [];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            requests.add(FriendRequestModel.fromJson(
              Map<String, dynamic>.from(value),
            ));
          } catch (e) {
            // Skip invalid requests
          }
        }
      });

      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    }).asBroadcastStream();
  }

  /// Chấp nhận friend request
  Future<void> acceptFriendRequest(String fromUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userModel = await _userRepository.getUser(currentUser.uid);
    final friendModel = await _userRepository.getUser(fromUid);

    if (userModel == null || friendModel == null) return;

    // Xóa request
    await _dbService.friendRequestsRef(currentUser.uid).child(fromUid).remove();

    // Thêm vào friends của cả 2 bên
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _dbService.friendsRef(currentUser.uid).child(fromUid).set({
      'friendUid': fromUid,
      'displayName': friendModel.displayName,
      'avatarUrl': friendModel.avatarUrl,
      'createdAt': timestamp,
    });

    await _dbService.friendsRef(fromUid).child(currentUser.uid).set({
      'friendUid': currentUser.uid,
      'displayName': userModel.displayName,
      'avatarUrl': userModel.avatarUrl,
      'createdAt': timestamp,
    });
  }

  /// Từ chối friend request
  Future<void> rejectFriendRequest(String fromUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _dbService.friendRequestsRef(currentUser.uid).child(fromUid).remove();
  }

  /// Stream danh sách bạn bè
  Stream<List<FriendModel>> streamFriends(String uid) {
    return _dbService
        .friendsRef(uid)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <FriendModel>[];
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<FriendModel> friends = [];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            friends.add(FriendModel.fromJson(
              Map<String, dynamic>.from(value),
            ));
          } catch (e) {
            // Skip invalid friends
          }
        }
      });

      friends.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return friends;
    }).asBroadcastStream();
  }

  /// Kiểm tra 2 user có phải bạn bè không
  Future<bool> areFriends(String uidA, String uidB) async {
    final snapshot = await _dbService.friendsRef(uidA).child(uidB).get();
    return snapshot.exists;
  }
}

