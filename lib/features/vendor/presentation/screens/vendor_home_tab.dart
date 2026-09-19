import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class VendorHomeTab extends ConsumerWidget {
  const VendorHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المورد'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 👋 ترحيب
          Card(
            color: AppColors.primaryNavy,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحبًا ${user?.fullName ?? "بك"} 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'إليك نظرة سريعة على متجرك اليوم',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 📊 إحصائيات
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              _StatCard(
                icon: Icons.inventory_2,
                title: 'المنتجات',
                value: '12',
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.receipt_long,
                title: 'الطلبات الجديدة',
                value: '5',
                color: Colors.orange,
              ),
              _StatCard(
                icon: Icons.attach_money,
                title: 'مبيعات اليوم',
                value: '2,450 ر.س',
                color: Colors.green,
              ),
              _StatCard(
                icon: Icons.star,
                title: 'التقييم',
                value: '4.8',
                color: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 🕐 آخر الطلبات
          const Text(
            'آخر الطلبات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(3, (i) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentGold.withValues(alpha: 0.2),
                  child: const Icon(Icons.shopping_bag,
                      color: AppColors.accentGold),
                ),
                title: Text('طلب #${1024 + i}'),
                subtitle: Text('منذ ${i + 1} ساعة'),
                trailing: Chip(
                  label: Text(
                    i == 0 ? 'جديد' : 'قيد التجهيز',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor:
                  i == 0 ? Colors.orange.shade100 : Colors.blue.shade100,
                ),
              ),
            );
          }),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}