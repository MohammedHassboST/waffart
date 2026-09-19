import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/erp_provider.dart';
import '../widgets/add_integration_dialog.dart';
import '../widgets/integration_card.dart';

class ErpIntegrationScreen extends ConsumerWidget {
  const ErpIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(integrationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تكامل ERP')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة تكامل'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (integrations) {
          if (integrations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_sync, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('لا توجد تكاملات حتى الآن'),
                  const SizedBox(height: 8),
                  const Text(
                    'اربط متجرك بنظام Odoo / SAP / Zoho',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: integrations.length,
            itemBuilder: (_, i) =>
                IntegrationCard(integration: integrations[i]),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AddIntegrationDialog(),
    );
    if (result == true) ref.invalidate(integrationsProvider);
  }
}