import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Màn hình thông báo đơn giản
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  DatabaseReference get _notificationsRef =>
      FirebaseDatabase.instance.ref('notifications/$_userId');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo 🔔'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(context),
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _notificationsRef.orderByChild('createdAt').onValue,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Không có thông báo
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có thông báo',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Parse data
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final notifications = data.entries.map((e) {
            final value = e.value as Map<dynamic, dynamic>;
            return {
              'id': e.key.toString(),
              'title': value['title'] ?? 'Thông báo',
              'body': value['body'] ?? '',
              'isRead': value['isRead'] ?? false,
              'createdAt': value['createdAt'] ?? 0,
            };
          }).toList();

          // Sắp xếp mới nhất trước
          notifications.sort((a, b) => 
              (b['createdAt'] as int).compareTo(a['createdAt'] as int));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['isRead'] as bool;

              return Card(
                color: isRead ? null : Colors.blue.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey : Colors.blue,
                    child: Icon(
                      isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    notification['title'] as String,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification['body'] as String),
                  trailing: isRead
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () => _markAsRead(notification['id'] as String),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _markAsRead(String notificationId) {
    _notificationsRef.child(notificationId).update({'isRead': true});
  }

  void _markAllAsRead(BuildContext context) async {
    try {
      final snapshot = await _notificationsRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (var key in data.keys) {
          await _notificationsRef.child(key.toString()).update({'isRead': true});
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi, vui lòng thử lại')),
        );
      }
    }
  }
}
