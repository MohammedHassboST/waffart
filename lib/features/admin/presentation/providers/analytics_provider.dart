import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';

final dailyOverviewProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('admin_daily_overview')
      .select();
  return List<Map<String, dynamic>>.from(res);
});

final vendorLeaderboardProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('admin_vendor_leaderboard')
      .select();
  return List<Map<String, dynamic>>.from(res);
});

final categoryPerformanceProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('admin_category_performance')
      .select();
  return List<Map<String, dynamic>>.from(res);
});

final offerConversionProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('admin_offer_conversion')
      .select()
      .limit(20);
  return List<Map<String, dynamic>>.from(res);
});

final retentionProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('admin_customer_retention')
      .select();
  return List<Map<String, dynamic>>.from(res);
});

// مؤشرات KPI
final kpiSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = SupabaseClientProvider.client;

  final results = await Future.wait([
    client.from('orders').select('id').count(),
    client.from('profiles').select('id').eq('role', 'customer').count(),
    client.from('vendors').select('id').eq('is_approved', true).count(),
    client
        .from('orders')
        .select('total_amount')
        .gte('created_at',
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String()),
  ] as Iterable<Future<dynamic>>);

  final totalOrders = results[0].count;
  final totalCustomers = results[1].count;
  final activeVendors = results[2].count;
  final last30DaysOrders = results[3].data as List;
  final last30DaysRevenue = last30DaysOrders.fold<double>(
    0,
        (s, o) => s + ((o['total_amount'] as num?)?.toDouble() ?? 0),
  );

  return {
    'total_orders': totalOrders,
    'total_customers': totalCustomers,
    'active_vendors': activeVendors,
    'last_30_days_revenue': last30DaysRevenue,
    'last_30_days_orders': last30DaysOrders.length,
  };
});