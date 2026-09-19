import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../vendor_dashboard/presentation/providers/vendor_orders_provider.dart';
import '../../../vendor_dashboard/presentation/providers/vendor_provider.dart';
import '../../domain/entities/erp_integration.dart';
import '../providers/erp_provider.dart';

class AddIntegrationDialog extends ConsumerStatefulWidget {
  const AddIntegrationDialog({super.key});

  @override
  ConsumerState<AddIntegrationDialog> createState() =>
      _AddIntegrationDialogState();
}

class _AddIntegrationDialogState extends ConsumerState<AddIntegrationDialog> {
  final _displayName = TextEditingController();
  final _apiUrl = TextEditingController();
  final _apiKey = TextEditingController();
  final _webhookUrl = TextEditingController();
  ErpProvider _provider = ErpProvider.odoo;
  bool _loading = false;

  Future<void> _save() async {
    if (_displayName.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final vendor = await ref.read(currentVendorProvider.future);
      if (vendor == null) throw Exception('لا يوجد مورد');

      await ref.read(erpRepositoryProvider).createIntegration(
        vendorId: vendor['id'],
        provider: _provider,
        displayName: _displayName.text.trim(),
        apiUrl: _apiUrl.text.trim().isEmpty ? null : _apiUrl.text.trim(),
        apiKey: _apiKey.text.trim().isEmpty ? null : _apiKey.text.trim(),
        webhookUrl: _webhookUrl.text.trim().isEmpty
            ? null
            : _webhookUrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _apiUrl.dispose();
    _apiKey.dispose();
    _webhookUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة تكامل ERP'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ErpProvider>(
              value: _provider,
              decoration: const InputDecoration(labelText: 'نوع النظام'),
              items: const [
                DropdownMenuItem(
                    value: ErpProvider.odoo, child: Text('Odoo')),
                DropdownMenuItem(
                    value: ErpProvider.sap, child: Text('SAP')),
                DropdownMenuItem(
                    value: ErpProvider.zoho, child: Text('Zoho Inventory')),
                DropdownMenuItem(
                    value: ErpProvider.customWebhook,
                    child: Text('Webhook مخصص')),
                DropdownMenuItem(
                    value: ErpProvider.csv, child: Text('CSV Import')),
              ],
              onChanged: (v) =>
                  setState(() => _provider = v ?? ErpProvider.odoo),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(labelText: 'الاسم المعروض'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiUrl,
              decoration:
              const InputDecoration(labelText: 'API URL (اختياري)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKey,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _webhookUrl,
              decoration: const InputDecoration(
                labelText: 'Webhook URL (للاستقبال الفوري)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}