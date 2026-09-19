import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/erp_integration.dart';
import '../providers/erp_provider.dart';

class IntegrationCard extends ConsumerWidget {
  final ErpIntegration integration;
  const IntegrationCard({super.key, required this.integration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _providerIcon(),
        title: Text(integration.displayName),
        subtitle: Row(
          children: [
            _statusChip(),
            const SizedBox(width: 8),
            if (integration.lastSyncAt != null)
              Text(
                'آخر مزامنة: ${Formatters.relativeTime(integration.lastSyncAt!)}',
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('المزود', integration.provider.name),
                _infoRow('API URL', integration.apiUrl ?? 'غير مُعرّف'),
                _infoRow('فاصل المزامنة',
                    '${integration.syncIntervalMinutes} دقيقة'),
                _infoRow('الحالة', integration.isActive ? 'نشط' : 'متوقف'),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(erpRepositoryProvider)
                              .triggerSync(integration.id);
                          ref.invalidate(syncLogsProvider(integration.id));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم بدء المزامنة')),
                            );
                          }
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('مزامنة الآن'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showLogs(context, ref),
                      child: const Text('السجل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerIcon() {
    switch (integration.provider) {
      case ErpProvider.odoo:
        return const Icon(Icons.business, color: Colors.purple);
      case ErpProvider.sap:
        return const Icon(Icons.business_center, color: Colors.blue);
      case ErpProvider.zoho:
        return const Icon(Icons.cloud, color: Colors.orange);
      default:
        return const Icon(Icons.api, color: AppColors.accentGold);
    }
  }

  Widget _statusChip() {
    if (!integration.isActive) {
      return const Chip(
        label: Text('متوقف', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.grey,
      );
    }
    switch (integration.lastSyncStatus) {
      case 'success':
        return const Chip(
          label: Text('متزامن', style: TextStyle(fontSize: 10)),
          backgroundColor: Colors.green,
        );
      case 'failed':
        return const Chip(
          label: Text('فشل', style: TextStyle(fontSize: 10)),
          backgroundColor: Colors.red,
        );
      case 'partial':
        return const Chip(
          label: Text('جزئي', style: TextStyle(fontSize: 10)),
          backgroundColor: Colors.orange,
        );
      default:
        return const Chip(
          label: Text('بانتظار المزامنة', style: TextStyle(fontSize: 10)),
        );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogs(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Consumer(
          builder: (context, ref, _) {
            final logsAsync =
            ref.watch(syncLogsProvider(integration.id));
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'سجل المزامنة',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: logsAsync.when(
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('خطأ: $e')),
                    data: (logs) {
                      if (logs.isEmpty) {
                        return const Center(child: Text('لا يوجد سجل'));
                      }
                      return ListView.builder(
                        controller: controller,
                        itemCount: logs.length,
                        itemBuilder: (_, i) {
                          final l = logs[i];
                          return ListTile(
                            leading: Icon(
                              l.status == SyncStatus.completed
                                  ? Icons.check_circle
                                  : l.status == SyncStatus.running
                                  ? Icons.sync
                                  : Icons.error,
                              color: l.status == SyncStatus.completed
                                  ? Colors.green
                                  : l.status == SyncStatus.running
                                  ? Colors.blue
                                  : Colors.red,
                            ),
                            title: Text(
                              '${l.syncType} - ${l.recordsSucceeded}/${l.recordsProcessed}',
                            ),
                            subtitle: Text(
                              Formatters.dateTime(l.startedAt),
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: l.recordsFailed > 0
                                ? Text(
                              '${l.recordsFailed} فشل',
                              style:
                              const TextStyle(color: Colors.red),
                            )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}