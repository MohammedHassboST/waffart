import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/supabase_client.dart';
import '../../domain/repositories/payment_repository.dart';

class StripeRepository {
  final String secretKey;
  static const String _baseUrl = 'https://api.stripe.com/v1';

  StripeRepository({required this.secretKey});

  Future<PaymentInitResult> createPaymentIntent({
    required String orderId,
    required String customerId,
    required double amount,
    required String customerEmail,
  }) async {
    // حفظ المعاملة في DB
    final txRow = await SupabaseClientProvider.client
        .from('payment_transactions')
        .insert({
      'order_id': orderId,
      'customer_id': customerId,
      'gateway': 'stripe',
      'amount': amount,
      'currency': 'EGP',
      'status': 'pending',
    })
        .select()
        .single();

    final transactionId = txRow['id'] as String;

    try {
      // استدعاء Stripe
      final res = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).round().toString(),
          'currency': 'egp',
          'receipt_email': customerEmail,
          'metadata[order_id]': orderId,
          'metadata[transaction_id]': transactionId,
          'automatic_payment_methods[enabled]': 'true',
        },
      );

      if (res.statusCode != 200) {
        throw Exception('Stripe failed: ${res.body}');
      }

      final data = jsonDecode(res.body);
      final clientSecret = data['client_secret'] as String;
      final paymentIntentId = data['id'] as String;

      await SupabaseClientProvider.client
          .from('payment_transactions')
          .update({'gateway_order_id': paymentIntentId})
          .eq('id', transactionId);

      return PaymentInitResult(
        transactionId: transactionId,
        clientSecret: clientSecret,
      );
    } catch (e) {
      await SupabaseClientProvider.client
          .from('payment_transactions')
          .update({
        'status': 'failed',
        'failure_reason': e.toString(),
      })
          .eq('id', transactionId);
      rethrow;
    }
  }
}