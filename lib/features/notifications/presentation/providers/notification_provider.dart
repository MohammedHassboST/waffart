import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';

final notificationsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseClientProvider.client.auth.currentUser?.id;
  if (userId == null) return [];
  final res = await SupabaseClientProvider.client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
  return List<Map<String, dynamic>>.from(res);
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final userId = SupabaseClientProvider.client.auth.currentUser?.id;
  if (userId == null) return 0;
  final res = await SupabaseClientProvider.client
      .from('notifications')
      .select('id')
      .eq('user_id', userId)
      .eq('is_read', false)
      .count();
  return res.count;
});

final markAsReadProvider = Provider((ref) => (String notificationId) async {
  await SupabaseClientProvider.client
      .from('notifications')
      .update({'is_read': true}).eq('id', notificationId);
  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadCountProvider);
});