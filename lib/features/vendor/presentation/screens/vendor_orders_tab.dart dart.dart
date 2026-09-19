import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

class VendorOrdersTab extends ConsumerWidget {
  const VendorOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = [
      {
        'id': '1024',
        'customer': 'أحمد محمد',
        'total': 450.0,
        'status': 'pending',
      },
      {
        'id': '1023',
        'customer': 'فاطمة علي',
        'total': 320.0,
        'status': 'accepted',
      },
      {
        'id': '1022',
        'customer': 'خالد سعيد',
        'total': 780.0,
        'status': 'shipped',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        centerTitle: true,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('لا توجد طلبات'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final o = orders[i];
          return _OrderCard(order: o);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'طلب #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: order['status'] as String),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order['customer'] as String),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${order['total']} ر.س'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (order['status'] == 'pending') ...[
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('قبول'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('رفض'),
                  ),
                ],
                if (order['status'] == 'accepted')
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('بدء التجهيز'),
                  ),
                if (order['status'] == 'shipped')
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('تأكيد التسليم'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = {
      'pending': ('جديد', Colors.orange),
      'accepted': ('مقبول', Colors.blue),
      'shipped': ('تم الشحن', Colors.purple),
      'delivered': ('تم التسليم', Colors.green),
      'rejected': ('مرفوض', Colors.red),
    }[status] ?? ('غير معروف', Colors.grey);

    return Chip(
      label: Text(
        config.$1,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
      backgroundColor: config.$2,
      labelPadding: EdgeInsets.zero,
    );
  }
}