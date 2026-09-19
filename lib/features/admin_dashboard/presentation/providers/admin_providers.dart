import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';

final pendingVendorsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('vendors')
      .select('*, profiles(full_name, phone)')
      .eq('is_approved', false)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

final allVendorsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('vendors')
      .select('*, profiles(full_name, phone)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

final allOrdersProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await SupabaseClientProvider.client
      .from('orders')
      .select('*, profiles(full_name, phone)')
      .order('created_at', ascending: false)
      .limit(100);
  return List<Map<String, dynamic>>.from(res);
});

final approveVendorProvider = Provider((ref) =>
    (String vendorId, bool approve) async {
  await SupabaseClientProvider.client.from('vendors').update({
    'is_approved': approve,
    'approved_at': approve ? DateTime.now().toIso8601String() : null,
  }).eq('id', vendorId);
  ref.invalidate(pendingVendorsProvider);
  ref.invalidate(allVendorsProvider);
});