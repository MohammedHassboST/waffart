import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

class AdminVendorsTab extends ConsumerWidget {
  const AdminVendorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = [
      {'name': 'متجر السلام', 'products': 45, 'orders': 120, 'active': true},
      {'name': 'أزياء النور', 'products': 30, 'orders': 85, 'active': true},
      {'name': 'إلكترونيات المستقبل', 'products': 12, 'orders': 40, 'active': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردون'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vendors.length,
        itemBuilder: (context, i) {
          final v = vendors[i];
          final active = v['active'] as bool;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: active
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.15),
                child: Icon(
                  Icons.store,
                  color: active ? Colors.orange : Colors.grey,
                ),
              ),
              title: Text(v['name'] as String),
              subtitle: Text(
                '${v['products']} منتج • ${v['orders']} طلب',
              ),
              trailing: Switch(
                value: active,
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val ? 'تفعيل المورد' : 'إيقاف المورد',
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}