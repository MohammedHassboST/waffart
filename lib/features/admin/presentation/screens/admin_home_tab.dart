import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 👋 ترحيب
          Card(
            color: Colors.purple.shade700,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحبًا ${user?.fullName ?? "بك"} 👑',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'إدارة كاملة للمنصة',
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
              _AdminStatCard(
                icon: Icons.people,
                title: 'المستخدمون',
                value: '1,245',
                color: Colors.blue,
              ),
              _AdminStatCard(
                icon: Icons.store,
                title: 'الموردون',
                value: '87',
                color: Colors.orange,
              ),
              _AdminStatCard(
                icon: Icons.receipt_long,
                title: 'الطلبات',
                value: '3,456',
                color: Colors.green,
              ),
              _AdminStatCard(
                icon: Icons.attach_money,
                title: 'الإيرادات',
                value: '145K',
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 📈 النشاط الأخير
          const Text(
            'النشاط الأخير',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...[
            ('مورد جديد سجّل', 'منذ 5 دقائق', Icons.store, Colors.orange),
            ('طلب جديد بقيمة 450 ر.س', 'منذ 20 دقيقة', Icons.shopping_bag, Colors.blue),
            ('مستخدم جديد سجّل', 'منذ ساعة', Icons.person_add, Colors.green),
            ('تحديث في سياسات المنصة', 'منذ 3 ساعات', Icons.policy, Colors.purple),
          ].map((e) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: e.$4.withValues(alpha: 0.15),
                  child: Icon(e.$3, color: e.$4),
                ),
                title: Text(e.$1),
                subtitle: Text(e.$2),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _AdminStatCard({
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