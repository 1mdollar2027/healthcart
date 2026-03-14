import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await ApiService.listNotifications();
      if (mounted) setState(() { _notifications = r['items'] ?? []; _unreadCount = r['unread_count'] ?? 0; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'appointment': return Icons.calendar_today_rounded;
      case 'prescription': return Icons.description_rounded;
      case 'lab_result': return Icons.science_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'vital_alert': return Icons.warning_rounded;
      case 'reminder': return Icons.alarm_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) { case 'vital_alert': return HealthCartTheme.error; case 'payment': return HealthCartTheme.success;
      case 'lab_result': return HealthCartTheme.warning; default: return HealthCartTheme.primary; }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        if (_unreadCount > 0) TextButton(onPressed: () async {
          await ApiService.markAllNotificationsRead(); _load();
        }, child: const Text('Mark all read')),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.notifications_off_rounded, size: 56, color: HealthCartTheme.textSecondary),
            SizedBox(height: 12), Text('No notifications yet'),
          ]))
        : RefreshIndicator(onRefresh: _load, child: ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: _notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = _notifications[i];
              final isUnread = n['is_read'] != true;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
                  color: _colorForType(n['notification_type']).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_iconForType(n['notification_type']), color: _colorForType(n['notification_type']), size: 22)),
                title: Text(n['title'] ?? '', style: TextStyle(fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400, fontSize: 14)),
                subtitle: Text(n['body'] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: isUnread ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: HealthCartTheme.secondary, shape: BoxShape.circle)) : null,
                onTap: () async { if (isUnread) { await ApiService.markNotificationRead(n['id']); _load(); } },
              );
            },
          )),
    );
  }
}
