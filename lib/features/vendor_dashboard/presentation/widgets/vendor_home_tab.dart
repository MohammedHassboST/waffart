import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/vendor_providers.dart';

class VendorHomeTab extends ConsumerWidget {
  const VendorHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final statsAsync = ref.watch(vendorQuickStatsProvider);
    final recentOrdersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المورد'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vendorQuickStatsProvider);
          ref.invalidate(vendorOrdersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─────────────────────────────────────────
            // 👋 ترحيب
            // ─────────────────────────────────────────
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

            // ─────────────────────────────────────────
            // 📊 إحصائيات حقيقية
            // ─────────────────────────────────────────
            statsAsync.when(
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
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    icon: Icons.inventory_2,
                    title: 'المنتجات',
                    value: '${stats['total_products'] ?? 0}',
                    color: Colors.blue,
                  ),
                  _StatCard(
                    icon: Icons.receipt_long,
                    title: 'طلبات جديدة',
                    value: '${stats['pending_orders'] ?? 0}',
                    color: Colors.orange,
                  ),
                  _StatCard(
                    icon: Icons.attach_money,
                    title: 'المبيعات',
                    value: Formatters.currency(
                      (stats['total_sales'] as num?)?.toDouble() ?? 0,
                    ),
                    color: Colors.green,
                  ),
                  _StatCard(
                    icon: Icons.shopping_cart,
                    title: 'إجمالي الطلبات',
                    value: '${stats['total_orders'] ?? 0}',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─────────────────────────────────────────
            // 🕐 آخر الطلبات (حقيقية)
            // ─────────────────────────────────────────
            const Text(
              'آخر الطلبات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            recentOrdersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد طلبات بعد'),
                    ),
                  );
                }
                final recent = orders.take(3).toList();
                return Column(
                  children: recent.map((o) {
                    final status = o['status'] as String? ?? 'pending';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          AppColors.accentGold.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.shopping_bag,
                            color: AppColors.accentGold,
                          ),
                        ),
                        title: Text(
                          'طلب ${o['vendor_order_number'] ?? '#'}',
                        ),
                        subtitle: Text(
                          Formatters.currency(
                            (o['subtotal'] as num?)?.toDouble() ?? 0,
                          ),
                        ),
                        trailing: _StatusChip(status: status),
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

// ═══════════════════════════════════════════════════════
// 🎨 Widgets مساعدة
// ═══════════════════════════════════════════════════════

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
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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