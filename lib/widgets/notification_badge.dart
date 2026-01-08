import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// Widget Notification Badge với StreamBuilder - Realtime updates
/// Hiển thị số lượng notifications chưa đọc
class NotificationBadge extends StatelessWidget {
  final String userId;
  final Widget child;
  final Color badgeColor;
  final Color textColor;

  const NotificationBadge({
    super.key,
    required this.userId,
    required this.child,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
  });

  // Reference tới notifications của user
  DatabaseReference get _notificationsRef =>
      FirebaseDatabase.instance.ref('notifications/$userId');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      // Lắng nghe thay đổi realtime
      stream: _notificationsRef.orderByChild('isRead').equalTo(false).onValue,
      builder: (context, snapshot) {
        // Đếm số notifications chưa đọc
        int unreadCount = 0;

        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          unreadCount = data.length;
        }

        // Hiển thị badge
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            // Chỉ hiển thị badge khi có notifications
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    // Hiển thị 99+ nếu quá nhiều
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Widget đơn giản hơn - chỉ hiện dot (không số)
class NotificationDot extends StatelessWidget {
  final String userId;
  final Widget child;
  final Color dotColor;

  const NotificationDot({
    super.key,
    required this.userId,
    required this.child,
    this.dotColor = Colors.red,
  });

  DatabaseReference get _notificationsRef =>
      FirebaseDatabase.instance.ref('notifications/$userId');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _notificationsRef.orderByChild('isRead').equalTo(false).onValue,
      builder: (context, snapshot) {
        bool hasUnread = false;

        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          hasUnread = true;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
