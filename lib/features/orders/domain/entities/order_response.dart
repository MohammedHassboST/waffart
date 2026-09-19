class OrderResponse {
  final String orderId;
  final String orderNumber;
  final double totalAmount;
  final String status;

  const OrderResponse({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) => OrderResponse(
    orderId: json['order_id'] as String,
    orderNumber: json['order_number'] as String,
    totalAmount: (json['total_amount'] as num).toDouble(),
    status: json['status'] as String,
  );
}