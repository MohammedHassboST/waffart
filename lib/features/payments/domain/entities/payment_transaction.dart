enum PaymentGateway { paymob, stripe, cod, wallet }

enum PaymentStatus {
  pending, processing, succeeded, failed, refunded, cancelled;

  static PaymentStatus fromString(String s) =>
      PaymentStatus.values.firstWhere((e) => e.name == s, orElse: () => pending);
}

class PaymentTransaction {
  final String id;
  final String orderId;
  final String customerId;
  final PaymentGateway gateway;
  final String? gatewayTransactionId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? failureReason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.gateway,
    this.gatewayTransactionId,
    required this.amount,
    required this.currency,
    required this.status,
    this.failureReason,
    this.metadata = const {},
    required this.createdAt,
  });
}