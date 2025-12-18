import '../models/reaction_type.dart';
import '../services/realtime_db_service.dart';
import 'package:firebase_database/firebase_database.dart';

class ReactionRepository {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();

  Stream<String?> streamMyReaction(String postId, String uid) {
    final reactionRef = _dbService.reactionsRef(postId).child(uid);
    
    return reactionRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return null;
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data['type'] as String?;
    });
  }

  Future<void> setReaction({
    required String postId,
    required String uid,
    required String? newType, // null means remove
  }) async {
    final reactionRef = _dbService.reactionsRef(postId).child(uid);
    final summaryRef = _dbService.postsRef().child(postId).child('reactionSummary');
    
    // Read current reaction
    final currentSnapshot = await reactionRef.get();
    String? oldType;
    if (currentSnapshot.exists && currentSnapshot.value != null) {
      final data = currentSnapshot.value as Map<dynamic, dynamic>;
      oldType = data['type'] as String?;
    }

    // Case 1: Remove reaction
    if (newType == null) {
      if (oldType != null) {
        // Delete reaction
        await reactionRef.remove();
        
        // Decrease oldType count
        await summaryRef.runTransaction((currentData) {
          if (currentData == null) {
            return Transaction.abort();
          }
          
          final data = Map<String, dynamic>.from(currentData as Map);
          final currentCount = (data[oldType] as num?)?.toInt() ?? 0;
          data[oldType!] = (currentCount - 1).clamp(0, double.infinity).toInt();
          
          return Transaction.success(data);
        });
      }
      return;
    }

    // Case 2: New reaction (oldType == null)
    if (oldType == null) {
      // Set reaction
      await reactionRef.set({
        'type': newType,
        'updatedAt': ServerValue.timestamp,
      });
      
      // Increase newType count
      await summaryRef.runTransaction((currentData) {
        if (currentData == null) {
          // Initialize if missing
          return Transaction.success({
            'like': newType == 'like' ? 1 : 0,
            'love': newType == 'love' ? 1 : 0,
            'haha': newType == 'haha' ? 1 : 0,
            'wow': newType == 'wow' ? 1 : 0,
            'sad': newType == 'sad' ? 1 : 0,
            'angry': newType == 'angry' ? 1 : 0,
          });
        }
        
        final data = Map<String, dynamic>.from(currentData as Map);
        final currentCount = (data[newType] as num?)?.toInt() ?? 0;
        data[newType] = currentCount + 1;
        
        // Ensure all keys exist
        for (final type in ReactionType.all) {
          if (!data.containsKey(type)) {
            data[type] = 0;
          }
        }
        
        return Transaction.success(data);
      });
      return;
    }

    // Case 3: Change reaction (oldType != null && oldType != newType)
    if (oldType != newType) {
      // Update reaction
      await reactionRef.update({
        'type': newType,
        'updatedAt': ServerValue.timestamp,
      });
      
      // Update both counts
      await summaryRef.runTransaction((currentData) {
        if (currentData == null) {
          // Initialize if missing
          final data = <String, int>{};
          for (final type in ReactionType.all) {
            data[type] = 0;
          }
          data[oldType!] = 0;
          data[newType] = 1;
          return Transaction.success(data);
        }
        
        final data = Map<String, dynamic>.from(currentData as Map);
        
        // Decrease oldType
        final oldCount = (data[oldType] as num?)?.toInt() ?? 0;
        data[oldType!] = (oldCount - 1).clamp(0, double.infinity).toInt();
        
        // Increase newType
        final newCount = (data[newType] as num?)?.toInt() ?? 0;
        data[newType] = newCount + 1;
        
        // Ensure all keys exist
        for (final type in ReactionType.all) {
          if (!data.containsKey(type)) {
            data[type] = 0;
          }
        }
        
        return Transaction.success(data);
      });
    }
  }
}
