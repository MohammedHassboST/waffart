import '../../domain/entities/payment_transaction.dart';

class PaymentTransactionModel extends PaymentTransaction {
  const PaymentTransactionModel({
    required super.id,
    required super.orderId,
    required super.customerId,
    required super.gateway,
    super.gatewayTransactionId,
    required super.amount,
    required super.currency,
    required super.status,
    super.failureReason,
    super.metadata,
    required super.createdAt,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      customerId: json['customer_id'] as String,
      gateway: PaymentGateway.values.firstWhere(
            (e) => e.name == json['gateway'],
        orElse: () => PaymentGateway.cod,
      ),
      gatewayTransactionId: json['gateway_transaction_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      failureReason: json['failure_reason'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}