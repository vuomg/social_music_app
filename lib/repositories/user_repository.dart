import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/realtime_db_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class UserRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  
  // Cache streams để tránh tạo lại mỗi lần
  final Map<String, Stream<UserModel>> _userStreams = {};
  final StorageService _storageService = StorageService();

  /// Đảm bảo user tồn tại trong database, nếu chưa thì tạo mới
  Future<void> ensureUserExists(String uid, String displayName) async {
    final userRef = _dbService.usersRef().child(uid);
    final snapshot = await userRef.get();
    
    if (!snapshot.exists) {
      // User chưa tồn tại, tạo mới
      final timestamp = ServerValue.timestamp;
      await userRef.set({
        'uid': uid,
        'displayName': displayName,
        'avatarUrl': null,
        'birthday': null,
        'phone': null,
        'bio': null,
        'address': null,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });
    }
  }

  /// Lấy user data một lần (không stream)
  Future<UserModel?> getUser(String uid) async {
    try {
      final snapshot = await _dbService.usersRef().child(uid).get();
      if (!snapshot.exists) {
        return null;
      }
      final data = snapshot.value;
      if (data == null) return null;
      return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      return null;
    }
  }

  /// Stream user data từ Realtime Database
  Stream<UserModel> streamUser(String uid) {
    // Cache stream theo uid để tránh tạo lại
    if (!_userStreams.containsKey(uid)) {
      _userStreams[uid] = _dbService.usersRef().child(uid).onValue.asBroadcastStream().asyncMap((event) async {
        final data = event.snapshot.value;
        if (data == null) {
          // User chưa tồn tại, tự động tạo user mặc định
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            await ensureUserExists(uid, firebaseUser.displayName ?? 'User');
            // Lấy lại data sau khi tạo
            final newSnapshot = await _dbService.usersRef().child(uid).get();
            if (newSnapshot.exists) {
              final newData = newSnapshot.value;
              return UserModel.fromJson(Map<String, dynamic>.from(newData as Map));
            }
          }
          throw Exception('User not found');
        }
        return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
      });
    }
    return _userStreams[uid]!;
  }

  /// Cập nhật profile user
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    File? avatarFile,
    String? birthday,
    String? phone,
    String? bio,
    String? address,
  }) async {
    try {
      final userRef = _dbService.usersRef().child(uid);
      final updates = <String, dynamic>{};

      // Upload avatar nếu có
      if (avatarFile != null) {
        final avatarResult = await _storageService.uploadAvatar(
          uid: uid,
          avatarFile: avatarFile,
        );
        updates['avatarUrl'] = avatarResult['avatarUrl'];
      }

      // Cập nhật các trường khác
      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (birthday != null) {
        updates['birthday'] = birthday;
      }
      if (phone != null) {
        updates['phone'] = phone;
      }
      if (bio != null) {
        updates['bio'] = bio.isEmpty ? null : bio;
      }
      if (address != null) {
        updates['address'] = address.isEmpty ? null : address;
      }

      // Luôn cập nhật updatedAt
      updates['updatedAt'] = ServerValue.timestamp;

      // Cập nhật vào database
      await userRef.update(updates);
    } catch (e) {
      throw Exception('Lỗi cập nhật profile: ${e.toString()}');
    }
  }
  /// Lấy tất cả users (để tìm kiếm)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _dbService.usersRef().get();
      if (!snapshot.exists || snapshot.value == null) return [];
      
      final dynamic data = snapshot.value;
      List<UserModel> users = [];
      
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              users.add(UserModel.fromJson(Map<String, dynamic>.from(value)));
            } catch (e) {
              debugPrint('Lỗi parse user $key: $e');
            }
          }
        });
      } else if (data is List) {
        for (var value in data) {
          if (value is Map) {
            try {
              users.add(UserModel.fromJson(Map<String, dynamic>.from(value)));
            } catch (e) {
              debugPrint('Lỗi parse user list item: $e');
            }
          }
        }
      }
      return users;
    } catch (e) {
      debugPrint('Lỗi getAllUsers: $e');
      return [];
    }
  }
}
