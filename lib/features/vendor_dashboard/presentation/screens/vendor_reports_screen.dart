import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/reports_provider.dart';

class VendorReportsScreen extends ConsumerWidget {
  const VendorReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);
    final topAsync = ref.watch(topProductsProvider);
    final offersAsync = ref.watch(offerPerformanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vendorStatsProvider);
          ref.invalidate(topProductsProvider);
          ref.invalidate(offerPerformanceProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // الإحصائيات العامة
            statsAsync.when(
              loading: () => const _LoadingCard(),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) {
                if (s == null) return const SizedBox.shrink();
                return _StatsGrid(stats: s);
              },
            ),
            const SizedBox(height: 16),

            // أكثر الأصناف مبيعاً
            const _SectionHeader(
              title: 'أكثر الأصناف مبيعاً',
              icon: Icons.trending_up,
            ),
            topAsync.when(
              loading: () => const _LoadingCard(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyCard(text: 'لا توجد بيانات بعد');
                }
                return Card(
                  child: Column(
                    children: list.asMap().entries.map((e) {
                      final item = e.value;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: e.key < 3
                              ? AppColors.accentGold.withOpacity(0.2)
                              : Colors.grey[200],
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: e.key < 3
                                  ? AppColors.accentGold
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                        title: Text(item['product_name'] ?? ''),
                        subtitle: Text(
                          '${item['orders_count']} طلب',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item['total_quantity_sold']} وحدة',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.currency(
                                (item['total_revenue'] as num).toDouble(),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // أداء العروض
            const _SectionHeader(
              title: 'أداء العروض',
              icon: Icons.local_offer,
            ),
            offersAsync.when(
              loading: () => const _LoadingCard(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyCard(text: 'لا توجد عروض بعد');
                }
                return Column(
                  children: list.map((o) {
                    final pct = (o['sell_through_pct'] as num?)?.toDouble() ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: pct / 100,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey[300],
                                      color: pct > 70
                                          ? AppColors.success
                                          : pct > 30
                                          ? AppColors.accentGold
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${o['sold_quantity']} / ${o['total_quantity']} وحدة',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  Formatters.currency(
                                    (o['total_revenue'] as num).toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _StatTile(
          icon: Icons.receipt_long,
          label: 'إجمالي الطلبات',
          value: '${stats['total_orders'] ?? 0}',
          color: Colors.blue,
        ),
        _StatTile(
          icon: Icons.hourglass_empty,
          label: 'قيد الانتظار',
          value: '${stats['pending_orders'] ?? 0}',
          color: Colors.orange,
        ),
        _StatTile(
          icon: Icons.check_circle,
          label: 'تم التسليم',
          value: '${stats['delivered_orders'] ?? 0}',
          color: Colors.green,
        ),
        _StatTile(
          icon: Icons.attach_money,
          label: 'الإيرادات',
          value: Formatters.currency(
              (stats['total_revenue'] as num?)?.toDouble() ?? 0),
          color: AppColors.accentGold,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.label,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGold),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Card(
    child: SizedBox(
      height: 100,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(text)),
    ),
  );
}