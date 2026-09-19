import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/supabase_client.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymobRepository {
  static const String _baseUrl = 'https://accept.paymob.com/api';
  final String apiKey;
  final String integrationId;
  final String iframeId;

  PaymobRepository({
    required this.apiKey,
    required this.integrationId,
    required this.iframeId,
  });

  /// 1. الحصول على Auth Token
  Future<String> _authToken() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'api_key': apiKey}),
    );
    if (res.statusCode != 201) {
      throw Exception('Paymob auth failed: ${res.body}');
    }
    return jsonDecode(res.body)['token'] as String;
  }

  /// 2. إنشاء Order في Paymob
  Future<String> _createOrder(String authToken, double amountCents) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ecommerce/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': authToken,
        'delivery_needed': 'false',
        'amount_cents': (amountCents * 100).round(),
        'currency': 'EGP',
        'items': [],
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Paymob order creation failed: ${res.body}');
    }
    return jsonDecode(res.body)['id'].toString();
  }

  /// 3. الحصول على Payment Key
  Future<String> _paymentKey({
    required String authToken,
    required String paymobOrderId,
    required double amountCents,
    required Map<String, dynamic> billingData,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/acceptance/payment_keys'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': authToken,
        'amount_cents': (amountCents * 100).round(),
        'expiration': 3600,
        'order_id': paymobOrderId,
        'billing_data': billingData,
        'currency': 'EGP',
        'integration_id': int.parse(integrationId),
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Paymob payment key failed: ${res.body}');
    }
    return jsonDecode(res.body)['token'] as String;
  }

  /// العملية الكاملة: init payment
  Future<PaymentInitResult> initPayment({
    required String orderId,
    required String customerId,
    required double amount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  }) async {
    // حفظ المعاملة في DB أولاً
    final txRow = await SupabaseClientProvider.client
        .from('payment_transactions')
        .insert({
      'order_id': orderId,
      'customer_id': customerId,
      'gateway': 'paymob',
      'amount': amount,
      'currency': 'EGP',
      'status': 'pending',
    })
        .select()
        .single();

    final transactionId = txRow['id'] as String;

    try {
      // 1. Auth
      final authToken = await _authToken();
      // 2. Order
      final paymobOrderId = await _createOrder(authToken, amount);
      // 3. Payment Key
      final names = customerName.split(' ');
      final firstName = names.isNotEmpty ? names.first : 'Customer';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'User';

      final paymentKey = await _paymentKey(
        authToken: authToken,
        paymobOrderId: paymobOrderId,
        amountCents: amount,
        billingData: {
          'apartment': 'NA',
          'email': customerEmail,
          'floor': 'NA',
          'first_name': firstName,
          'street': 'NA',
          'building': 'NA',
          'phone_number': customerPhone,
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'NA',
          'country': 'EG',
          'last_name': lastName,
          'state': 'NA',
        },
      );

      // تحديث المعاملة بـ gateway_order_id
      await SupabaseClientProvider.client
          .from('payment_transactions')
          .update({'gateway_order_id': paymobOrderId})
          .eq('id', transactionId);

      return PaymentInitResult(
        transactionId: transactionId,
        iframeUrl:
        'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentKey',
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