import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';

/// 📦 منتجات المورد الحالي
final vendorProductsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseClientProvider.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) return [];

  final response = await client
      .from('products')
      .select('*')
      .eq('vendor_id', userId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response as List);
});

/// 🏪 بيانات المتجر للمورد الحالي
final vendorStoreProvider =
FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = SupabaseClientProvider.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) return null;

  final response = await client
      .from('vendors')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

  return response;
});