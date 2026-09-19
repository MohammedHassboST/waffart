import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = list[i];
              final isRead = n['is_read'] == true;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  isRead ? Colors.grey[200] : Colors.blue[100],
                  child: Icon(
                    _iconFor(n['type']),
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                ),
                title: Text(
                  n['title'] ?? '',
                  style: TextStyle(
                    fontWeight:
                    isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(n['body'] ?? ''),
                trailing: Text(
                  Formatters.relativeTime(DateTime.parse(n['created_at'])),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                onTap: () =>
                    ref.read(markAsReadProvider)(n['id'] as String),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'new_offer':
        return Icons.local_offer;
      case 'low_stock':
        return Icons.warning_amber;
      case 'order_update':
        return Icons.local_shipping;
      default:
        return Icons.notifications;
    }
  }
}