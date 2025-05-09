import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';


class NotificationCenter extends StatelessWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationManager = Provider.of<NotificationManager>(context, listen: true);
    final notifications = notificationManager.notifications;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 300,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5A89),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      if (notificationManager.unreadCount > 0)
                        TextButton(
                          onPressed: () {
                            notificationManager.markAllAsRead();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All notifications marked as read')),
                            );
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(Colors.white),
                            overlayColor: WidgetStateProperty.resolveWith<Color?>(
                              (states) {
                                if (states.contains(WidgetState.hovered)) return Colors.white.withOpacity(0.2);
                                if (states.contains(WidgetState.pressed)) return Colors.white.withOpacity(0.3);
                                return null;
                              },
                            ),
                            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          notificationManager.clearAll();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All notifications cleared')),
                          );
                          Navigator.of(context).pop();
                        },
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) {
                              if (states.contains(WidgetState.hovered)) return Colors.white.withOpacity(0.2);
                              if (states.contains(WidgetState.pressed)) return Colors.white.withOpacity(0.3);
                              return null;
                            },
                          ),
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            notifications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Flexible(
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return NotificationItem(notification: notification);
                        },
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final EventNotification notification;

  const NotificationItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final notificationManager = Provider.of<NotificationManager>(context, listen: false);

return Dismissible(
  key: Key(notification.id),
  direction: notification.isRead
      ? DismissDirection.endToStart // Only allow swipe left to delete
      : DismissDirection.horizontal, // Allow both swipe directions
  background: notification.isRead
      ? const SizedBox() // No "mark as read" UI
      : Container(
          color: Colors.green,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.done, color: Colors.white),
        ),
  secondaryBackground: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    child: const Icon(Icons.delete, color: Colors.white),
  ),
 onDismissed: (direction) {
  if (direction == DismissDirection.startToEnd && !notification.isRead) {
    notificationManager.markAsReadAndMoveToBottom(notification.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification marked as read')),
    );
  } else if (direction == DismissDirection.endToStart) {
    notificationManager.deleteNotification(notification.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }
},
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => notificationManager.markAsRead(notification.id),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : const Color(0xFFFFEEF3),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}