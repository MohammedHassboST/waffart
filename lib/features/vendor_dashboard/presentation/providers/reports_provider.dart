import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waffart/features/vendor_dashboard/presentation/providers/vendor_orders_provider.dart';
import '../../../../core/network/supabase_client.dart';

final vendorStatsProvider =
FutureProvider<Map<String, dynamic>?>((ref) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  if (vendor == null) return null;
  final res = await SupabaseClientProvider.client
      .from('vendor_stats')
      .select()
      .eq('vendor_id', vendor['id'])
      .maybeSingle();
  return res;
});

final topProductsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  if (vendor == null) return [];
  final res = await SupabaseClientProvider.client
      .from('vendor_top_products')
      .select()
      .eq('vendor_id', vendor['id'])
      .limit(10);
  return List<Map<String, dynamic>>.from(res);
});

final offerPerformanceProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  if (vendor == null) return [];
  final res = await SupabaseClientProvider.client
      .from('vendor_offer_performance')
      .select()
      .eq('vendor_id', vendor['id'])
      .order('total_revenue', ascending: false)
      .limit(20);
  return List<Map<String, dynamic>>.from(res);
});