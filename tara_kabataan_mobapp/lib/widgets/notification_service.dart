// widgets/notification_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EventNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  EventNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory EventNotification.fromJson(Map<String, dynamic> json) {
    return EventNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationManager extends ChangeNotifier {
  List<EventNotification> _notifications = [];
  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  List<EventNotification> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize and load saved notifications
  Future<void> initialize() async {
    await _loadNotifications();
  }

  // Add a new notification
  void addNotification(String title, String message) {
    print('Adding notification: $title');
    final notification = EventNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    
    _notifications.insert(0, notification); // Add to beginning of list
    _saveNotifications();
    notifyListeners();
  }

  // Mark notification as read
  void markAsRead(String id) {
    print('Marking notification as read: $id');
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    print('Marking all notifications as read');
    bool hasChanges = false;
    
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _saveNotifications();
      notifyListeners();
    }
  }

  // Delete notification
  void deleteNotification(String id) {
    print('Deleting notification: $id');
    _notifications.removeWhere((n) => n.id == id);
    _saveNotifications();
    notifyListeners();
  }

  // Clear all notifications
  void clearAll() {
    print('Clearing all notifications');
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      _saveNotifications();
      notifyListeners();
    }
  }

  // Save notifications to persistent storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(data));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Load notifications from persistent storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('notifications');
      
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _notifications = decoded.map((item) => EventNotification.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }
}