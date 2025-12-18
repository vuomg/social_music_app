import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, String>> uploadAudio({
    required String uid,
    required String postId,
    required File audioFile,
  }) async {
    try {
      final extension = audioFile.path.split('.').last;
      final audioPath = 'audio/$uid/$postId.$extension';
      final audioRef = _storage.ref(audioPath);

      final uploadTask = audioRef.putFile(audioFile);
      await uploadTask;

      final audioUrl = await audioRef.getDownloadURL();

      return {
        'audioUrl': audioUrl,
        'audioPath': audioPath,
      };
    } catch (e) {
      throw Exception('Lỗi upload audio: ${e.toString()}');
    }
  }

  Future<Map<String, String>> uploadCover({
    required String uid,
    required String postId,
    required File coverFile,
  }) async {
    try {
      final coverPath = 'covers/$uid/$postId.jpg';
      final coverRef = _storage.ref(coverPath);

      final uploadTask = coverRef.putFile(coverFile);
      await uploadTask;

      final coverUrl = await coverRef.getDownloadURL();

      return {
        'coverUrl': coverUrl,
        'coverPath': coverPath,
      };
    } catch (e) {
      throw Exception('Lỗi upload cover: ${e.toString()}');
    }
  }

  Future<Map<String, String>> uploadAvatar({
    required String uid,
    required File avatarFile,
  }) async {
    try {
      final extension = avatarFile.path.split('.').last;
      final avatarPath = 'avatars/$uid/avatar.$extension';
      final avatarRef = _storage.ref(avatarPath);

      final uploadTask = avatarRef.putFile(avatarFile);
      await uploadTask;

      final avatarUrl = await avatarRef.getDownloadURL();

      return {
        'avatarUrl': avatarUrl,
        'avatarPath': avatarPath,
      };
    } catch (e) {
      throw Exception('Lỗi upload avatar: ${e.toString()}');
    }
  }

  Future<void> deleteByPath(String path) async {
    final ref = _storage.ref(path);
    await ref.delete();
  }
}
