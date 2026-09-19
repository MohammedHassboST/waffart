import '../entities/payment_transaction.dart';

class PaymentInitResult {
  final String transactionId;
  final String? paymentUrl;
  final String? clientSecret;
  final String? iframeUrl;
  final Map<String, dynamic>? extra;

  const PaymentInitResult({
    required this.transactionId,
    this.paymentUrl,
    this.clientSecret,
    this.iframeUrl,
    this.extra,
  });
}

abstract class PaymentRepository {
  /// إنشاء معاملة دفع جديدة
  Future<PaymentInitResult> initPaymobPayment({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  });

  Future<PaymentInitResult> initStripePayment({
    required String orderId,
    required double amount,
    required String customerEmail,
  });

  /// الاستعلام عن حالة معاملة
  Future<PaymentTransaction> getTransaction(String transactionId);

  /// تأكيد الدفع (يدوي عند العودة من الـ SDK)
  Future<bool> confirmPayment({
    required String transactionId,
    required String gatewayTransactionId,
  });
}