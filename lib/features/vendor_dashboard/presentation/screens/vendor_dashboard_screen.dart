import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/vendor_orders_provider.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم المورد'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الطلبات', icon: Icon(Icons.receipt_long)),
              Tab(text: 'المنتجات', icon: Icon(Icons.inventory_2)),
              Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _VendorOrdersTab(),
            _VendorProductsTab(),
            _VendorStatsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddProductSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('منتج جديد'),
        ),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('نموذج إضافة المنتج - قيد التنفيذ')),
    );
  }
}

class _VendorOrdersTab extends ConsumerWidget {
  const _VendorOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(child: Text('لا توجد طلبات'));
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                title: Text('طلب ${o['vendor_order_number']}'),
                subtitle: Text(
                  '${Formatters.currency((o['subtotal'] as num).toDouble())} - ${o['status']}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عنوان التوصيل: ${o['orders']['delivery_address']}',
                        ),
                        const Divider(),
                        ...(o['sub_order_items'] as List).map(
                              (it) => ListTile(
                            dense: true,
                            title: Text(it['product_name']),
                            trailing: Text(
                              '${it['quantity']} × ${it['unit_price']}',
                            ),
                          ),
                        ),
                        const Divider(),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (o['status'] == 'pending') ...[
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(updateSubOrderStatusProvider)(
                                  o['id'],
                                  'accepted',
                                ),
                                child: const Text('قبول'),
                              ),
                              OutlinedButton(
                                onPressed: () => ref
                                    .read(updateSubOrderStatusProvider)(
                                  o['id'],
                                  'rejected',
                                  rejectionReason: 'نفذت الكمية',
                                ),
                                child: const Text('رفض'),
                              ),
                            ],
                            if (o['status'] == 'accepted')
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(updateSubOrderStatusProvider)(
                                  o['id'],
                                  'processing',
                                ),
                                child: const Text('بدء التجهيز'),
                              ),
                            if (o['status'] == 'processing')
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(updateSubOrderStatusProvider)(
                                  o['id'],
                                  'shipped',
                                ),
                                child: const Text('تم الشحن'),
                              ),
                            if (o['status'] == 'shipped')
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(updateSubOrderStatusProvider)(
                                  o['id'],
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
          },
        );
      },
    );
  }
}

class _VendorProductsTab extends ConsumerWidget {
  const _VendorProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('لا توجد منتجات'));
        }
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, i) {
            final p = products[i];
            return ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text(p['name'] ?? ''),
              subtitle: Text(
                '${p['base_price']} - مخزون: ${p['stock_quantity']}',
              ),
              trailing: Chip(
                label: Text(p['is_active'] == true ? 'نشط' : 'متوقف'),
                backgroundColor: p['is_active'] == true
                    ? Colors.green[100]
                    : Colors.grey[300],
              ),
            );
          },
        );
      },
    );
  }
}

class _VendorStatsTab extends ConsumerWidget {
  const _VendorStatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final productsAsync = ref.watch(vendorProductsProvider);

    // ✅ value بدل valueOrNull
    final orders = ordersAsync.value ?? const [];
    final products = productsAsync.value ?? const [];

    final totalOrders = orders.length;
    final totalProducts = products.length;
    final totalSales = orders.fold<double>(
      0,
          (s, o) => s + (o['subtotal'] as num).toDouble(),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatCard(
            icon: Icons.receipt,
            title: 'إجمالي الطلبات',
            value: '$totalOrders',
            color: Colors.blue,
          ),
          _StatCard(
            icon: Icons.inventory,
            title: 'إجمالي المنتجات',
            value: '$totalProducts',
            color: Colors.orange,
          ),
          _StatCard(
            icon: Icons.attach_money,
            title: 'إجمالي المبيعات',
            value: Formatters.currency(totalSales),
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2), // ✅ withValues
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}