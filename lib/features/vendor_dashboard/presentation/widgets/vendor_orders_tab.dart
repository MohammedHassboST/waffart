import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/vendor_providers.dart';

class VendorOrdersTab extends ConsumerStatefulWidget {
  const VendorOrdersTab({super.key});

  @override
  ConsumerState<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends ConsumerState<VendorOrdersTab> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vendorOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // فلاتر الحالة
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _filterChip('الكل', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('جديد', 'pending'),
                  const SizedBox(width: 8),
                  _filterChip('قيد التجهيز', 'processing'),
                  const SizedBox(width: 8),
                  _filterChip('تم الشحن', 'shipped'),
                  const SizedBox(width: 8),
                  _filterChip('تم التسليم', 'delivered'),
                ],
              ),
            ),
          ),

          Expanded(
            child: async.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (orders) {
                final filtered = _statusFilter == 'all'
                    ? orders
                    : orders
                    .where((o) => o['status'] == _statusFilter)
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات'));
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(vendorOrdersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final o = filtered[i];
                      return _OrderCard(order: o);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = order['status'] as String? ?? 'pending';
    final items = (order['sub_order_items'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          'طلب ${order['vendor_order_number'] ?? '#'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              Formatters.currency(
                (order['subtotal'] as num?)?.toDouble() ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: status),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order['orders'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order['orders']['delivery_address'] ?? '—',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                const Divider(),
                ...items.map((it) => ListTile(
                  dense: true,
                  title: Text(it['product_name'] ?? ''),
                  trailing: Text(
                    '${it['quantity']} × ${Formatters.currency((it['unit_price'] as num).toDouble())}',
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
                const Divider(),
                Wrap(
                  spacing: 8,
                  children: [
                    if (status == 'pending') ...[
                      ElevatedButton(
                        onPressed: () => ref
                            .read(updateSubOrderStatusProvider)(
                          order['id'],
                          'accepted',
                        ),
                        child: const Text('قبول'),
                      ),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(updateSubOrderStatusProvider)(
                          order['id'],
                          'rejected',
                          rejectionReason: 'نفذت الكمية',
                        ),
                        child: const Text('رفض'),
                      ),
                    ],
                    if (status == 'accepted')
                      ElevatedButton(
                        onPressed: () => ref
                            .read(updateSubOrderStatusProvider)(
                          order['id'],
                          'processing',
                        ),
                        child: const Text('بدء التجهيز'),
                      ),
                    if (status == 'processing')
                      ElevatedButton(
                        onPressed: () => ref
                            .read(updateSubOrderStatusProvider)(
                          order['id'],
                          'shipped',
                        ),
                        child: const Text('تم الشحن'),
                      ),
                    if (status == 'shipped')
                      ElevatedButton(
                        onPressed: () => ref
                            .read(updateSubOrderStatusProvider)(
                          order['id'],
                          'delivered',
                        ),
                        child: const Text('تم التسليم'),
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
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = {
      'pending': ('جديد', Colors.orange),
      'accepted': ('مقبول', Colors.blue),
      'processing': ('قيد التجهيز', Colors.indigo),
      'shipped': ('تم الشحن', Colors.purple),
      'delivered': ('تم التسليم', Colors.green),
      'rejected': ('مرفوض', Colors.red),
      'cancelled': ('ملغي', Colors.grey),
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