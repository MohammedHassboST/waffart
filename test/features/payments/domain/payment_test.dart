import 'package:flutter_test/flutter_test.dart';
import 'package:waffart/features/payments/domain/entities/payment_transaction.dart';

void main() {
  group('PaymentStatus', () {
    test('fromString يحول النص الصحيح', () {
      expect(PaymentStatus.fromString('succeeded'), PaymentStatus.succeeded);
      expect(PaymentStatus.fromString('failed'), PaymentStatus.failed);
    });

    test('fromString يعيد pending للحالات غير المعروفة', () {
      expect(PaymentStatus.fromString('unknown'), PaymentStatus.pending);
    });
  });
}