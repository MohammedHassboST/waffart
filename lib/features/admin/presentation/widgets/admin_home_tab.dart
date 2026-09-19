import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/admin_providers.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final kpiAsync = ref.watch(kpiSummaryProvider);
    final pendingAsync = ref.watch(pendingVendorsProvider);
    final recentOrdersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kpiSummaryProvider);
          ref.invalidate(pendingVendorsProvider);
          ref.invalidate(allOrdersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ترحيب
            Card(
              color: AppColors.primaryNavy,
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

            // KPI Grid (بيانات حقيقية)
            kpiAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('خطأ: $e'),
                ),
              ),
              data: (kpi) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _AdminStatCard(
                    icon: Icons.people,
                    title: 'العملاء',
                    value: '${kpi['total_customers'] ?? 0}',
                    color: Colors.blue,
                  ),
                  _AdminStatCard(
                    icon: Icons.store,
                    title: 'الموردون',
                    value: '${kpi['active_vendors'] ?? 0}',
                    color: Colors.orange,
                  ),
                  _AdminStatCard(
                    icon: Icons.receipt_long,
                    title: 'الطلبات',
                    value: '${kpi['total_orders'] ?? 0}',
                    color: Colors.green,
                  ),
                  _AdminStatCard(
                    icon: Icons.attach_money,
                    title: 'إيرادات 30 يوم',
                    value: Formatters.currency(
                      (kpi['last_30_days_revenue'] as num?)?.toDouble() ?? 0,
                    ),
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // النشاط الأخير (طلبات + موردين)
            const Text(
              'النشاط الأخير',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // موردون بانتظار الموافقة
            pendingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (vendors) {
                if (vendors.isEmpty) return const SizedBox.shrink();
                return Card(
                  color: Colors.orange.withValues(alpha: 0.1),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.pending_actions, color: Colors.white),
                    ),
                    title: Text('${vendors.length} مورد بانتظار الموافقة'),
                    subtitle: const Text('اذهب لتبويب الموردين للموافقة'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // آخر 5 طلبات
            recentOrdersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (orders) {
                final recent = orders.take(5).toList();
                if (recent.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد طلبات بعد'),
                    ),
                  );
                }
                return Column(
                  children: recent.map((o) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.15),
                          child: const Icon(Icons.shopping_bag, color: Colors.blue),
                        ),
                        title: Text('طلب #${o['order_number']}'),
                        subtitle: Text(
                          o['profiles']?['full_name'] ?? 'عميل',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          Formatters.currency(
                            (o['total_amount'] as num?)?.toDouble() ?? 0,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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