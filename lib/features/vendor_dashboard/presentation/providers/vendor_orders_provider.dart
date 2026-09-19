import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';

// المورد الحالي
final currentVendorProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = SupabaseClientProvider.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  final res = await client
      .from('vendors')
      .select()
      .eq('profile_id', userId)
      .maybeSingle();
  return res;
});

// منتجات المورد
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

// طلبات المورد
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

// تحديث حالة طلب
final updateSubOrderStatusProvider = Provider((ref) =>
    (String subOrderId, String status, {String? rejectionReason}) async {
  await SupabaseClientProvider.client.from('sub_orders').update({
    'status': status,
    if (rejectionReason != null) 'rejection_reason': rejectionReason,
  }).eq('id', subOrderId);
  ref.invalidate(vendorOrdersProvider);
});