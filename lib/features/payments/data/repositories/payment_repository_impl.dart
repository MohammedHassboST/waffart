import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_transaction_model.dart';
import 'paymob_repository.dart';
import 'stripe_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymobRepository _paymob;
  final StripeRepository _stripe;
  final _client = SupabaseClientProvider.client;

  PaymentRepositoryImpl({
    required PaymobRepository paymob,
    required StripeRepository stripe,
  })  : _paymob = paymob,
        _stripe = stripe;

  @override
  Future<PaymentInitResult> initPaymobPayment({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  }) async {
    final userId = _client.auth.currentUser!.id;
    return _paymob.initPayment(
      orderId: orderId,
      customerId: userId,
      amount: amount,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );
  }

  @override
  Future<PaymentInitResult> initStripePayment({
    required String orderId,
    required double amount,
    required String customerEmail,
  }) async {
    final userId = _client.auth.currentUser!.id;
    return _stripe.createPaymentIntent(
      orderId: orderId,
      customerId: userId,
      amount: amount,
      customerEmail: customerEmail,
    );
  }

  @override
  Future<PaymentTransaction> getTransaction(String transactionId) async {
    final res = await _client
        .from('payment_transactions')
        .select()
        .eq('id', transactionId)
        .single();
    return PaymentTransactionModel.fromJson(res);
  }

  @override
  Future<bool> confirmPayment({
    required String transactionId,
    required String gatewayTransactionId,
  }) async {
    final res = await _client.rpc('confirm_payment', params: {
      'p_transaction_id': transactionId,
      'p_gateway_transaction_id': gatewayTransactionId,
    });
    return (res as Map<String, dynamic>)['success'] == true;
  }
}