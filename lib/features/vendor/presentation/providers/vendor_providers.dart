import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';

// ═══════════════════════════════════════════════════════
// 🏪 المورد الحالي
// ═══════════════════════════════════════════════════════

final currentVendorProvider =
FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = SupabaseClientProvider.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  // ✅ الصحيح: profile_id (وليس user_id)
  final res = await client
      .from('vendors')
      .select()
      .eq('profile_id', userId)
      .maybeSingle();
  return res;
});

// ═══════════════════════════════════════════════════════
// 📦 منتجات المورد
// ═══════════════════════════════════════════════════════

final vendorProductsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  if (vendor == null) return [];

  final res = await SupabaseClientProvider.client
      .from('products')
      .select('*, categories(name_ar)')
      .eq('vendor_id', vendor['id'])
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

// ═══════════════════════════════════════════════════════
// 📋 طلبات المورد (sub_orders)
// ═══════════════════════════════════════════════════════

final vendorOrdersProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  if (vendor == null) return [];

  final res = await SupabaseClientProvider.client
      .from('sub_orders')
      .select('''
        *,
        orders(order_number, delivery_address, created_at),
        sub_order_items(product_name, quantity, unit_price)
      ''')
      .eq('vendor_id', vendor['id'])
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

// ═══════════════════════════════════════════════════════
// 🎯 إحصائيات سريعة (للوحة الرئيسية)
// ═══════════════════════════════════════════════════════

final vendorQuickStatsProvider =
FutureProvider<Map<String, dynamic>>((ref) async {
  final orders = await ref.watch(vendorOrdersProvider.future);
  final products = await ref.watch(vendorProductsProvider.future);

  final pendingOrders = orders
      .where((o) => o['status'] == 'pending')
      .length;

  final totalSales = orders
      .where((o) => ['delivered', 'shipped'].contains(o['status']))
      .fold<double>(
    0,
        (s, o) => s + ((o['subtotal'] as num?)?.toDouble() ?? 0),
  );

  return {
    'total_products': products.length,
    'pending_orders': pendingOrders,
    'total_orders': orders.length,
    'total_sales': totalSales,
  };
});

// ═══════════════════════════════════════════════════════
// 🔧 Actions
// ═══════════════════════════════════════════════════════

final updateSubOrderStatusProvider = Provider((ref) =>
    (String subOrderId, String status, {String? rejectionReason}) async {
  await SupabaseClientProvider.client.from('sub_orders').update({
    'status': status,
    if (rejectionReason != null) 'rejection_reason': rejectionReason,
  }).eq('id', subOrderId);

  ref.invalidate(vendorOrdersProvider);
  ref.invalidate(vendorQuickStatsProvider);
});