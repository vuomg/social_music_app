import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/realtime_db_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        final user = userCredential.user!;
        await user.updateDisplayName(displayName);
        
        // Lưu user vào Realtime Database
        final userRef = _dbService.usersRef().child(user.uid);
        final timestamp = ServerValue.timestamp;
        await userRef.set({
          'uid': user.uid,
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Đảm bảo user tồn tại trong Realtime Database
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userRef = _dbService.usersRef().child(user.uid);
        final snapshot = await userRef.get();
        
        if (!snapshot.exists) {
          // User chưa tồn tại trong database, tạo mới
          final timestamp = ServerValue.timestamp;
          await userRef.set({
            'uid': user.uid,
            'displayName': user.displayName ?? 'User',
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
