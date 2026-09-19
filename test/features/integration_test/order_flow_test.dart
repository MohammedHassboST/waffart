import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waffart/app.dart';
import 'package:waffart/core/network/supabase_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('تدفق الطلب الكامل', () {
    testWidgets('تسجيل → تصفح → إضافة للسلة → طلب',
            (tester) async {
          // 1. تهيئة Supabase
          await SupabaseClientProvider.initialize();

          // 2. تشغيل التطبيق
          await tester.pumpWidget(
            const ProviderScope(child: WaffartApp()),
          );
          await tester.pumpAndSettle();

          // 3. تسجيل الدخول (باستخدام OTP test mode)
          await tester.enterText(
            find.byType(TextField).first,
            '+201234567890',
          );
          await tester.tap(find.text('إرسال رمز التحقق'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // 4. إدخال OTP (يجب استخدام test OTP)
          await tester.enterText(find.byType(TextField).last, '123456');
          await tester.tap(find.text('تحقق'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // 5. التحقق من الوصول للفيد
          expect(find.text('أقوى عروض الجملة'), findsOneWidget);

          // 6. إضافة عرض للسلة (اختر أول عرض)
          final firstCard = find.byType(Card).first;
          await tester.tap(firstCard);
          await tester.pumpAndSettle();
          await tester.tap(find.text('أضف إلى السلة'));
          await tester.pumpAndSettle();

          // 7. فتح السلة
          await tester.tap(find.byIcon(Icons.shopping_cart));
          await tester.pumpAndSettle();
          expect(find.text('السلة'), findsOneWidget);

          // 8. إتمام الطلب
          await tester.tap(find.text('إتمام الطلب'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(TextField).first,
            'القاهرة، مصر',
          );
          await tester.tap(find.text('تأكيد الطلب'));
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // 9. التحقق من النجاح
          expect(find.text('تم تأكيد طلبك بنجاح!'), findsOneWidget);
        });
  });
}