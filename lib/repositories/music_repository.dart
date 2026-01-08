import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/music_model.dart';
import '../services/realtime_db_service.dart';
import '../services/storage_service.dart';

class MusicRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final StorageService _storageService = StorageService();
  
  // Cache streams để tránh tạo lại mỗi lần
  Stream<List<MusicModel>>? _allMusicsStream;
  final Map<String, Stream<List<MusicModel>>> _myMusicsStreams = {};

  /// Tạo music mới (upload file + lưu DB)
  Future<MusicModel> createMusic({
    required String uid,
    required String ownerName,
    String? ownerAvatarUrl,
    required String title,
    required String genre,
    required File audioFile,
    File? coverFile,
  }) async {
    final musicId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Upload audio
    final audioResult = await _storageService.uploadAudio(
      uid: uid,
      postId: musicId,
      audioFile: audioFile,
    );

    // Upload cover (nếu có)
    String? coverUrl;
    String? coverPath;
    if (coverFile != null) {
      try {
        final coverResult = await _storageService.uploadCover(
          uid: uid,
          postId: musicId,
          coverFile: coverFile,
        );
        coverUrl = coverResult['coverUrl'];
        coverPath = coverResult['coverPath'];
      } catch (e) {
        // Nếu upload cover fail, vẫn tiếp tục
      }
    }

    // Kiểm tra audioUrl và audioPath
    final audioUrlValue = audioResult['audioUrl'];
    final audioPathValue = audioResult['audioPath'];
    
    if (audioUrlValue == null || audioPathValue == null || 
        audioUrlValue is! String || audioPathValue is! String) {
      throw Exception('Lỗi upload audio: không lấy được URL hoặc Path');
    }

    final audioUrl = audioUrlValue as String;
    final audioPath = audioPathValue as String;

    // Lưu vào DB
    final musicRef = _dbService.musicsRef().child(musicId);
    await musicRef.set({
      'uid': uid,
      'ownerName': ownerName,
      'ownerAvatarUrl': ownerAvatarUrl,
      'title': title,
      'genre': genre,
      'audioUrl': audioUrl,
      'audioPath': audioPath,
      'coverUrl': coverUrl,
      'coverPath': coverPath,
      'createdAt': ServerValue.timestamp,
    });

    return MusicModel(
      musicId: musicId,
      uid: uid,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatarUrl,
      title: title,
      genre: genre,
      audioUrl: audioUrl,
      audioPath: audioPath,
      coverUrl: coverUrl,
      coverPath: coverPath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Stream tất cả musics (sắp xếp theo createdAt desc)
  Stream<List<MusicModel>> streamAllMusics() {
    // Cache stream để tránh tạo lại mỗi lần
    _allMusicsStream ??= _dbService
        .musicsRef()
        .orderByChild('createdAt')
        .onValue
        .asBroadcastStream()
        .map((event) {
      if (event.snapshot.value == null) {
        return <MusicModel>[];
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<MusicModel> musics = [];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            musics.add(MusicModel.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            ));
          } catch (e) {
            // Skip invalid musics
          }
        }
      });

      musics.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return musics;
    });
    
    return _allMusicsStream!;
  }

  /// Stream musics của user
  Stream<List<MusicModel>> streamMyMusics(String uid) {
    // Cache stream theo uid để tránh tạo lại
    if (!_myMusicsStreams.containsKey(uid)) {
      _myMusicsStreams[uid] = _dbService
          .musicsRef()
          .orderByChild('uid')
          .equalTo(uid)
          .onValue
          .asBroadcastStream()
          .map((event) {
        if (event.snapshot.value == null) {
          return <MusicModel>[];
        }

        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        final List<MusicModel> musics = [];

        data.forEach((key, value) {
          if (value is Map) {
            try {
              musics.add(MusicModel.fromJson(
                Map<String, dynamic>.from(value),
                key.toString(),
              ));
            } catch (e) {
              // Skip invalid musics
            }
          }
        });

        musics.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return musics;
      });
    }
    
    return _myMusicsStreams[uid]!;
  }

  /// Search musics (client-side filter)
  Future<List<MusicModel>> searchMusics(String keyword) async {
    try {
      final snapshot = await _dbService.musicsRef().get();
      if (!snapshot.exists || snapshot.value == null) return [];
      
      final lowerKeyword = keyword.toLowerCase();
      final dynamic data = snapshot.value;
      final List<MusicModel> musics = [];

      void processItem(dynamic key, dynamic value) {
        if (value is Map) {
          try {
            final music = MusicModel.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            );
            
            if (music.title.toLowerCase().contains(lowerKeyword) ||
                music.ownerName.toLowerCase().contains(lowerKeyword) ||
                music.genre.toLowerCase().contains(lowerKeyword)) {
              musics.add(music);
            }
          } catch (e) {
            // Skip invalid
          }
        }
      }

      if (data is Map) {
        data.forEach((key, value) => processItem(key, value));
      } else if (data is List) {
        for (int i = 0; i < data.length; i++) {
          processItem(i, data[i]);
        }
      }
      
      return musics;
    } catch (e) {
      debugPrint('Lỗi searchMusics: $e');
      return [];
    }
  }

  /// Cập nhật thông tin music
  Future<void> updateMusic({
    required String musicId,
    required String uid, // Để kiểm tra quyền
    String? title,
    String? genre,
    File? coverFile,
  }) async {
    // Kiểm tra quyền
    final musicRef = _dbService.musicsRef().child(musicId);
    final snapshot = await musicRef.get();
    if (!snapshot.exists) {
      throw Exception('Nhạc không tồn tại');
    }
    
    final musicData = Map<String, dynamic>.from(snapshot.value as Map);
    if (musicData['uid'] != uid) {
      throw Exception('Không có quyền sửa nhạc này');
    }

    final updates = <String, dynamic>{};
    
    // Upload cover mới nếu có
    String? coverUrl;
    String? coverPath;
    if (coverFile != null) {
      try {
        final coverResult = await _storageService.uploadCover(
          uid: uid,
          postId: musicId,
          coverFile: coverFile,
        );
        coverUrl = coverResult['coverUrl'];
        coverPath = coverResult['coverPath'];
        updates['coverUrl'] = coverUrl;
        updates['coverPath'] = coverPath;
      } catch (e) {
        // Nếu upload cover fail, vẫn tiếp tục
      }
    }

    // Cập nhật các trường khác
    if (title != null) {
      updates['title'] = title;
    }
    if (genre != null) {
      updates['genre'] = genre;
    }
    
    // Luôn cập nhật updatedAt
    updates['updatedAt'] = ServerValue.timestamp;

    await musicRef.update(updates);
  }

  /// Xóa music
  Future<void> deleteMusic({
    required String musicId,
    required String uid, // Để kiểm tra quyền
  }) async {
    // Kiểm tra quyền
    final musicRef = _dbService.musicsRef().child(musicId);
    final snapshot = await musicRef.get();
    if (!snapshot.exists) {
      throw Exception('Nhạc không tồn tại');
    }
    
    final musicData = Map<String, dynamic>.from(snapshot.value as Map);
    if (musicData['uid'] != uid) {
      throw Exception('Không có quyền xóa nhạc này');
    }

    // Lấy audioPath và coverPath để xóa files
    final audioPath = musicData['audioPath'] as String?;
    final coverPath = musicData['coverPath'] as String?;

    // Xóa node trong DB
    await musicRef.remove();

    // Xóa files trong Storage
    if (audioPath != null && audioPath.isNotEmpty) {
      try {
        await _storageService.deleteByPath(audioPath);
      } catch (e) {
        // Log error nhưng không throw
        debugPrint('Lỗi xóa audio file: $e');
      }
    }

    if (coverPath != null && coverPath.isNotEmpty) {
      try {
        await _storageService.deleteByPath(coverPath);
      } catch (e) {
        // Log error nhưng không throw
        debugPrint('Lỗi xóa cover file: $e');
      }
    }
  }
}

