// models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  taskAssigned,
  taskCompleted,
  projectCreated,
  message,
  system
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String senderId;
  final String receiverId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.senderId,
    required this.receiverId,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'senderId': senderId,
      'receiverId': receiverId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'taskAssigned':
        return NotificationType.taskAssigned;
      case 'taskCompleted':
        return NotificationType.taskCompleted;
      case 'projectCreated':
        return NotificationType.projectCreated;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.system;
    }
  }
}