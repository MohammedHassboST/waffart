import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/analytics_provider.dart';

class AdvancedAnalyticsScreen extends ConsumerWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(kpiSummaryProvider);
    final dailyAsync = ref.watch(dailyOverviewProvider);
    final vendorsAsync = ref.watch(vendorLeaderboardProvider);
    final categoriesAsync = ref.watch(categoryPerformanceProvider);
    final offersAsync = ref.watch(offerConversionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليلات المتقدمة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(kpiSummaryProvider);
              ref.invalidate(dailyOverviewProvider);
              ref.invalidate(vendorLeaderboardProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kpiSummaryProvider);
          ref.invalidate(dailyOverviewProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // KPI Cards
            kpiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ: $e'),
              data: (kpi) => _KpiGrid(kpi: kpi),
            ),
            const SizedBox(height: 16),

            // Revenue Chart
            const _SectionTitle('الإيرادات (آخر 30 يوم)'),
            dailyAsync.when(
              loading: () => const _LoadingCard(height: 220),
              error: (e, _) => Text('خطأ: $e'),
              data: (list) {
                if (list.isEmpty) return const _EmptyCard();
                return _RevenueChart(data: list);
              },
            ),
            const SizedBox(height: 16),

            // Vendor Leaderboard
            const _SectionTitle('أداء الموردين'),
            vendorsAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => Text('خطأ: $e'),
              data: (list) => _VendorLeaderboard(vendors: list.take(10).toList()),
            ),
            const SizedBox(height: 16),

            // Category Performance
            const _SectionTitle('أداء التصنيفات'),
            categoriesAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => Text('خطأ: $e'),
              data: (list) => _CategoryChart(data: list),
            ),
            const SizedBox(height: 16),

            // Offer Conversion
            const _SectionTitle('معدل تحويل العروض'),
            offersAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => Text('خطأ: $e'),
              data: (list) => _OfferConversion(data: list.take(10).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> kpi;
  const _KpiGrid({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _KpiTile(
          icon: Icons.receipt_long,
          label: 'إجمالي الطلبات',
          value: '${kpi['total_orders'] ?? 0}',
          color: Colors.blue,
        ),
        _KpiTile(
          icon: Icons.people,
          label: 'العملاء',
          value: '${kpi['total_customers'] ?? 0}',
          color: Colors.purple,
        ),
        _KpiTile(
          icon: Icons.store,
          label: 'الموردين النشطين',
          value: '${kpi['active_vendors'] ?? 0}',
          color: Colors.orange,
        ),
        _KpiTile(
          icon: Icons.attach_money,
          label: 'إيرادات 30 يوم',
          value: Formatters.currency(
            (kpi['last_30_days_revenue'] as num?)?.toDouble() ?? 0,
          ),
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _KpiTile({
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final reversed = data.reversed.toList();
    final spots = reversed.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        (e.value['revenue'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: const FlTitlesData(
                topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 50),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.accentGold,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                  ),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorLeaderboard extends StatelessWidget {
  final List<Map<String, dynamic>> vendors;
  const _VendorLeaderboard({required this.vendors});

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) return const _EmptyCard();
    return Card(
      child: Column(
        children: vendors.asMap().entries.map((e) {
          final v = e.value;
          final rank = e.key + 1;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: rank <= 3
                  ? AppColors.accentGold.withOpacity(0.2)
                  : Colors.grey[200],
              child: Text('$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3
                        ? AppColors.accentGold
                        : Colors.grey[700],
                  )),
            ),
            title: Text(v['store_name'] ?? ''),
            subtitle: Text(
              '${v['total_orders'] ?? 0} طلب • معدل الوفاء ${v['fulfillment_rate'] ?? 0}%',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              Formatters.currency(
                  (v['total_revenue'] as num?)?.toDouble() ?? 0),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CategoryChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyCard();
    final total = data.fold<double>(
        0, (s, e) => s + ((e['revenue'] as num?)?.toDouble() ?? 0));
    if (total == 0) return const _EmptyCard();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: data.map((e) {
                final value = (e['revenue'] as num?)?.toDouble() ?? 0;
                final pct = (value / total) * 100;
                return PieChartSectionData(
                  value: value,
                  title: '${pct.toStringAsFixed(0)}%',
                  color: Colors.primaries[
                  data.indexOf(e) % Colors.primaries.length],
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferConversion extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _OfferConversion({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyCard();
    return Card(
      child: Column(
        children: data.map((o) {
          final pct = (o['conversion_pct'] as num?)?.toDouble() ?? 0;
          return ListTile(
            title: Text(o['title'] ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    color: pct > 70
                        ? AppColors.success
                        : pct > 30
                        ? AppColors.accentGold
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            trailing: Text('${pct.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({this.height = 100});
  @override
  Widget build(BuildContext context) => Card(
      child: SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator())));
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();
  @override
  Widget build(BuildContext context) => const Card(
      child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('لا توجد بيانات'))));
}