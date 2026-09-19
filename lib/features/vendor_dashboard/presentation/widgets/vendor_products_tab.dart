import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/vendor_providers.dart';

class VendorProductsTab extends ConsumerStatefulWidget {
  const VendorProductsTab({super.key});

  @override
  ConsumerState<VendorProductsTab> createState() => _VendorProductsTabState();
}

class _VendorProductsTabState extends ConsumerState<VendorProductsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vendorProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // بحث
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (products) {
                final filtered = _query.isEmpty
                    ? products
                    : products
                    .where((p) => (p['name'] as String? ?? '')
                    .toLowerCase()
                    .contains(_query.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات'));
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(vendorProductsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final isActive = p['is_active'] == true;
                      final stock = p['stock_quantity'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image,
                              color: Colors.grey,
                            ),
                          ),
                          title: Text(p['name'] ?? ''),
                          subtitle: Text(
                            '${Formatters.currency((p['base_price'] as num?)?.toDouble() ?? 0)}'
                                ' • مخزون: $stock',
                          ),
                          trailing: Chip(
                            label: Text(
                              isActive ? 'نشط' : 'متوقف',
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: isActive
                                ? Colors.green.shade100
                                : Colors.grey.shade300,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إضافة منتج — قيد التنفيذ')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
        backgroundColor: AppColors.primaryNavy,
      ),
    );
  }
}