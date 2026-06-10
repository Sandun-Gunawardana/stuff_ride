import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Trip Confirmed',
      'message': 'Your booking for trip #TR001 has been confirmed',
      'time': '2 hours ago',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'title': 'Driver Arrived',
      'message': 'Your driver is arriving in 5 minutes',
      'time': '30 minutes ago',
      'icon': Icons.location_on,
      'color': Colors.blue,
    },
    {
      'title': 'Trip Completed',
      'message': 'Your trip has been completed. Rate your experience',
      'time': '1 hour ago',
      'icon': Icons.done_all,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: notification['color'].withValues(alpha: 0.2),
                child: Icon(notification['icon'], color: notification['color']),
              ),
              title: Text(
                notification['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(notification['message']),
                  const SizedBox(height: 4),
                  Text(
                    notification['time'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
