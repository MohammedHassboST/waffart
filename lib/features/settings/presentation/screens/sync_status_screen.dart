import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/cache/hive_cache_service.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../../../core/theme/app_colors.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(offlineQueueProvider);
    final status = ref.watch(networkStatusProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('حالة المزامنة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // حالة الشبكة
          Card(
            child: ListTile(
              leading: Icon(
                status == NetworkStatus.online
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: status == NetworkStatus.online
                    ? Colors.green
                    : Colors.red,
                size: 32,
              ),
              title: Text(
                status == NetworkStatus.online ? 'متصل' : 'غير متصل',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                status == NetworkStatus.online
                    ? 'جميع البيانات محدثة'
                    : 'يتم حفظ التغييرات محلياً',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // حجم الكاش
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage, color: AppColors.accentGold),
              title: const Text('حجم البيانات المخزنة محلياً'),
              subtitle: Text(
                  '${HiveCacheService.getCacheSizeMB().toStringAsFixed(2)} MB'),
              trailing: TextButton(
                onPressed: () async {
                  await HiveCacheService.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم مسح البيانات المحلية')),
                    );
                  }
                },
                child: const Text('مسح'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // قائمة الانتظار
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'العمليات المعلقة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (queue.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('لا توجد عمليات معلقة'),
                ),
              ),
            )
          else
            ...queue.map((action) => Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(action.type),
                subtitle: Text(
                    '${action.createdAt.hour}:${action.createdAt.minute.toString().padLeft(2, '0')} • محاولات: ${action.retries}'),
                trailing: const Icon(Icons.schedule),
              ),
            )),
        ],
      ),
    );
  }
}