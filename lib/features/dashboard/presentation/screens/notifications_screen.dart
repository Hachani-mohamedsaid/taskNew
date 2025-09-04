// notifications_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/firebase_service.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel currentUser;
  final FirebaseService firebaseService;

  const NotificationsScreen({
    super.key,
    required this.currentUser,
    required this.firebaseService,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = widget.firebaseService
        .getUserNotifications(widget.currentUser.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(),
            tooltip: 'Marquer tout comme lu',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text('Aucune notification'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(color: Colors.red),
      onDismissed: (direction) => _deleteNotification(notification.id),
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: Text(
          _formatDate(notification.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () => _handleNotificationTap(notification),
        onLongPress: () => _markAsRead(notification.id),
      ),
    );
  }

  Icon _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return const Icon(Icons.assignment, color: Colors.blue);
      case NotificationType.taskCompleted:
        return const Icon(Icons.check_circle, color: Colors.green);
      case NotificationType.projectCreated:
        return const Icon(Icons.folder, color: Colors.orange);
      case NotificationType.message:
        return const Icon(Icons.message, color: Colors.purple);
      case NotificationType.system:
        return const Icon(Icons.notifications, color: Colors.red);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Navigation selon le type de notification
    switch (notification.type) {
      case NotificationType.taskAssigned:
        // Naviguer vers la tâche
        break;
      case NotificationType.projectCreated:
        // Naviguer vers le projet
        break;
      default:
        break;
    }
  }

  void _markAsRead(String notificationId) {
    widget.firebaseService.markAsRead(notificationId);
  }

  void _markAllAsRead() {
    widget.firebaseService.markAllAsRead(widget.currentUser.id);
  }

  void _deleteNotification(String notificationId) {
    // Implémentez la suppression si nécessaire
  }
}