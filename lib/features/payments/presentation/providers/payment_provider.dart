import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/paymob_repository.dart';
import '../../data/repositories/stripe_repository.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    paymob: PaymobRepository(
      apiKey: AppConfig.paymobApiKey,
      integrationId: AppConfig.paymobIntegrationId,
      iframeId: AppConfig.paymobIframeId,
    ),
    stripe: StripeRepository(secretKey: AppConfig.stripeSecretKey),
  );
});

class PaymentNotifier extends StateNotifier<AsyncValue<PaymentInitResult?>> {
  final PaymentRepository _repo;
  PaymentNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<PaymentInitResult?> initPaymob({
    required String orderId,
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.initPaymobPayment(
        orderId: orderId,
        amount: amount,
        customerName: name,
        customerPhone: phone,
        customerEmail: email,
      );
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<PaymentInitResult?> initStripe({
    required String orderId,
    required double amount,
    required String email,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.initStripePayment(
        orderId: orderId,
        amount: amount,
        customerEmail: email,
      );
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> confirm({
    required String transactionId,
    required String gatewayTransactionId,
  }) async {
    try {
      return await _repo.confirmPayment(
        transactionId: transactionId,
        gatewayTransactionId: gatewayTransactionId,
      );
    } catch (_) {
      return false;
    }
  }
}

final paymentProvider =
StateNotifierProvider<PaymentNotifier, AsyncValue<PaymentInitResult?>>(
      (ref) => PaymentNotifier(ref.watch(paymentRepositoryProvider)),
);

final transactionProvider =
FutureProvider.family<PaymentTransaction, String>((ref, id) {
  return ref.watch(paymentRepositoryProvider).getTransaction(id);
});