import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<StudentNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getNotifications();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
      // Optionally mark visible ones as read? Or leave valid unread state.
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _markRead(StudentNotification notif) async {
    if (notif.isRead) return;
    await _service.markAsRead(notif.id);
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notif.id);
      if (index != -1) {
        // Create new object with isRead=true
        _notifications[index] = StudentNotification(
          id: notif.id,
          title: notif.title,
          body: notif.body,
          type: notif.type,
          isRead: true,
          createdAt: notif.createdAt,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xabarnomalar"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return _buildNotificationItem(notif);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Xabarlar yo'q",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(StudentNotification notif) {
    // Icon based on type
    IconData icon;
    Color color;
    
    switch (notif.type) {
      case 'grade':
        icon = Icons.grade;
        color = Colors.amber;
        break;
      case 'alert':
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blue;
    }

    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(notif.createdAt);

    return InkWell(
      onTap: () => _markRead(notif),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? Colors.grey.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
          ),
          boxShadow: [
            if (!notif.isRead)
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.body,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
