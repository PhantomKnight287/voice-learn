import 'package:flutter/material.dart';

enum NotificationsType {
  alert,
  warning,
  info,
  success,
}

Map<String, NotificationsType> notificationsTypeMap = {
  "ALERT": NotificationsType.alert,
  "WARNING": NotificationsType.warning,
  "INFO": NotificationsType.info,
  "SUCCESS": NotificationsType.success,
};

class NotificationModel {
  final String id;
  final DateTime createdAt;
  final String title;
  final String description;
  final bool read;
  final String type;

  const NotificationModel({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.read,
    required this.title,
    required this.type,
  });

  factory NotificationModel.fromJSON(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      read: json['read'],
      title: json['title'],
      type: json['type'].toLowerCase(),
    );
  }
  static Map<NotificationsType, Map<String, dynamic>> notificationProperties = {
    NotificationsType.alert: {
      'color': Colors.red,
      'icon': Icons.error,
    },
    NotificationsType.warning: {
      'color': Colors.orange,
      'icon': Icons.warning,
    },
    NotificationsType.info: {
      'color': Colors.blue,
      'icon': Icons.info,
    },
    NotificationsType.success: {
      'color': Colors.green,
      'icon': Icons.check_circle,
    },
  };

  static Map<String, dynamic> getProperties(String type) {
    NotificationsType? notificationType = notificationsTypeMap[type.toUpperCase()];
    if (notificationType != null) {
      return notificationProperties[notificationType] ?? {};
    } else {
      return {
        'color': Colors.grey,
        'icon': Icons.help_outline,
      };
    }
  }
}
