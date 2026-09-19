import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/connectivity_service.dart';
import '../offline_queue.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider).valueOrNull;
    final queue = ref.watch(offlineQueueProvider);

    if (status == NetworkStatus.online && queue.isEmpty) {
      return const SizedBox.shrink();
    }

    final isOffline = status == NetworkStatus.offline;
    final color = isOffline ? Colors.red : Colors.orange;

    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off : Icons.sync,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOffline
                      ? 'وضع عدم الاتصال - يتم حفظ تغييراتك محلياً'
                      : 'جاري مزامنة ${queue.length} عنصر...',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (queue.isNotEmpty && !isOffline)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}