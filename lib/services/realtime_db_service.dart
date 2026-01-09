import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference usersRef() {
    return _database.ref('users');
  }

  DatabaseReference postsRef() {
    return _database.ref('posts');
  }

  DatabaseReference commentsRef(String postId) {
    return _database.ref('comments/$postId');
  }

  DatabaseReference reactionsRef(String postId) {
    return _database.ref('postReactions/$postId');
  }

  DatabaseReference friendRequestsRef(String toUid) {
    return _database.ref('friendRequests/$toUid');
  }

  DatabaseReference friendsRef(String uid) {
    return _database.ref('friends/$uid');
  }

  DatabaseReference chatsRef() {
    return _database.ref('chats');
  }

  DatabaseReference messagesRef(String chatId) {
    return _database.ref('messages/$chatId');
  }

  DatabaseReference musicsRef() {
    return _database.ref('musics');
  }

  /// Reference đến listening rooms
  DatabaseReference listeningRoomsRef() {
    return _database.ref('listeningRooms');
  }

  /// Reference đến messages của một listening room
  DatabaseReference listeningRoomMessagesRef(String roomId) {
    return _database.ref('listeningRoomMessages/$roomId');
  }
}
