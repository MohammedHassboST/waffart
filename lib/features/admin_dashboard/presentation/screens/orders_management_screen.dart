import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/admin_providers.dart';

class OrdersManagementScreen extends ConsumerWidget {
  const OrdersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allOrdersProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إدارة الطلبات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات'));
                }
                return Card(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('رقم الطلب')),
                        DataColumn(label: Text('العميل')),
                        DataColumn(label: Text('الإجمالي')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('التاريخ')),
                      ],
                      rows: orders.map((o) {
                        return DataRow(cells: [
                          DataCell(Text(o['order_number'] ?? '')),
                          DataCell(Text(
                              o['profiles']?['full_name'] ?? '')),
                          DataCell(Text(Formatters.currency(
                              (o['total_amount'] as num).toDouble()))),
                          DataCell(Chip(
                            label: Text(_statusLabel(o['status'])),
                            backgroundColor: _statusColor(o['status']),
                          )),
                          DataCell(Text(Formatters.dateTime(
                              DateTime.parse(o['created_at'])))),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return s ?? '';
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'pending':
        return Colors.orange[100]!;
      case 'confirmed':
        return Colors.blue[100]!;
      case 'shipped':
        return Colors.purple[100]!;
      case 'delivered':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}