import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

class VendorProductsTab extends ConsumerWidget {
  const VendorProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧪 بيانات وهمية (هتتبدل بـ Supabase لاحقًا)
    final products = [
      {'name': 'قميص قطني', 'price': 120.0, 'stock': 45, 'active': true},
      {'name': 'حذاء رياضي', 'price': 350.0, 'stock': 12, 'active': true},
      {'name': 'بنطلون جينز', 'price': 200.0, 'stock': 0, 'active': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        centerTitle: true,
      ),
      body: products.isEmpty
          ? const Center(child: Text('لا توجد منتجات'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        itemBuilder: (context, i) {
          final p = products[i];
          final isActive = p['active'] as bool;
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
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              title: Text(p['name'] as String),
              subtitle: Text(
                '${p['price']} ر.س • مخزون: ${p['stock']}',
              ),
              trailing: Chip(
                label: Text(
                  isActive ? 'نشط' : 'متوقف',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor:
                isActive ? Colors.green.shade100 : Colors.grey.shade300,
              ),
            ),
          );
        },
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