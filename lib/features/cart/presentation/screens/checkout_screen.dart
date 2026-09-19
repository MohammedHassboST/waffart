import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان التوصيل')),
      );
      return;
    }
    final res = await ref.read(checkoutProvider.notifier).confirm(
      deliveryAddress: _address.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    if (res != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تم تأكيد طلبك بنجاح!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('رقم الطلب: ${res.orderNumber}'),
              Text('الإجمالي: ${Formatters.currency(res.totalAmount)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartTotalProvider);
    final state = ref.watch(checkoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('عنوان التوصيل',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'المدينة، الشارع، رقم المبنى'),
          ),
          const SizedBox(height: 16),
          const Text('ملاحظات (اختياري)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.payments_outlined, color: AppColors.success),
              title: Text('الدفع عند الاستلام'),
              subtitle: Text('كاش (COD)'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                Formatters.currency(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state.isLoading ? null : _submit,
            child: state.isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('تأكيد الطلب'),
          ),
        ],
      ),
    );
  }
}