import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';
import '../../../orders/domain/entities/order_response.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../domain/entities/cart_item.dart';

// 🏭 Repository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(SupabaseClientProvider.client);
});

// 🛒 Cart state
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void add(CartItem item) {
    final idx = state.indexWhere(
          (e) => e.productId == item.productId && e.offerId == item.offerId,
    );
    if (idx >= 0) {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(
        quantity: updated[idx].quantity + item.quantity,
      );
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void updateQty(String id, int qty) {
    if (qty <= 0) {
      remove(id);
      return;
    }
    state = state
        .map((e) => e.id == id ? e.copyWith(quantity: qty) : e)
        .toList();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() => state = [];
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
      (ref) => CartNotifier(),
);

// 📊 Derived
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (s, i) => s + i.totalPrice);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity);
});

// 💳 Checkout
// ✅ صحيح
class CheckoutNotifier extends StateNotifier<AsyncValue<OrderResponse?>> {
  final OrderRepository _repo;
  final Ref _ref;

  CheckoutNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<OrderResponse?> confirm({
    required String deliveryAddress,
    String? notes,
  }) async {
    // ─────────────────────────────────────────────────
    // 1. استخرج AppUser من AsyncValue
    // ─────────────────────────────────────────────────
    final userAsync = _ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;

    if (user == null) {
      state = AsyncValue.error(
        'الرجاء تسجيل الدخول أولاً',
        StackTrace.current,
      );
      return null;
    }

    final items = _ref.read(cartProvider);
    if (items.isEmpty) {
      state = AsyncValue.error(
        'السلة فارغة',
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncValue.loading();

    try {
      final res = await _repo.confirmOrder(
        customerId: user.id,              // ✅ AppUser.id
        items: items,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );

      _ref.read(cartProvider.notifier).clear();
      state = AsyncValue.data(res);
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final checkoutProvider =
StateNotifierProvider<CheckoutNotifier, AsyncValue<OrderResponse?>>(
      (ref) => CheckoutNotifier(ref.watch(orderRepositoryProvider), ref),
);