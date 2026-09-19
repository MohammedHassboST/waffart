import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'paymob';
  bool _showWebView = false;
  String? _iframeUrl;
  String? _transactionId;

  Future<void> _startPayment() async {
    if (_selectedMethod == 'cod') {
      // الدفع عند الاستلام - لا يحتاج بوابة
      Navigator.pop(context, {'success': true, 'method': 'cod'});
      return;
    }

    if (_selectedMethod == 'paymob') {
      final result = await ref.read(paymentProvider.notifier).initPaymob(
        orderId: widget.orderId,
        amount: widget.amount,
        name: widget.customerName,
        phone: widget.customerPhone,
        email: widget.customerEmail,
      );
      if (result != null && result.iframeUrl != null) {
        setState(() {
          _iframeUrl = result.iframeUrl;
          _transactionId = result.transactionId;
          _showWebView = true;
        });
      } else {
        _showError('فشل تهيئة الدفع');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _iframeUrl != null) {
      return _WebViewPayment(
        url: _iframeUrl!,
        onSuccess: (gatewayTxId) async {
          final ok = await ref.read(paymentProvider.notifier).confirm(
            transactionId: _transactionId!,
            gatewayTransactionId: gatewayTxId,
          );
          if (mounted && ok) {
            Navigator.pop(context, {'success': true, 'method': 'paymob'});
          }
        },
        onFailure: (reason) {
          setState(() => _showWebView = false);
          _showError('فشل الدفع: $reason');
        },
      );
    }

    final state = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الدفع')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long,
                    color: AppColors.accentGold, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المبلغ الإجمالي',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        Formatters.currency(widget.amount),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('اختر طريقة الدفع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _PaymentOption(
            value: 'paymob',
            groupValue: _selectedMethod,
            icon: Icons.credit_card,
            title: 'بطاقة / فودافون كاش / محفظة',
            subtitle: 'Paymob - آمن وسريع',
            onChanged: (v) => setState(() => _selectedMethod = v!),
          ),
          _PaymentOption(
            value: 'cod',
            groupValue: _selectedMethod,
            icon: Icons.payments_outlined,
            title: 'الدفع عند الاستلام',
            subtitle: 'كاش (COD)',
            onChanged: (v) => setState(() => _selectedMethod = v!),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: state.isLoading ? null : _startPayment,
            child: state.isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(_selectedMethod == 'cod'
                ? 'تأكيد الطلب'
                : 'الدفع الآن'),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.accentGold : Colors.grey[300]!,
          width: selected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        secondary: Icon(icon,
            color: selected ? AppColors.accentGold : Colors.grey[600]),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _WebViewPayment extends StatefulWidget {
  final String url;
  final void Function(String gatewayTxId) onSuccess;
  final void Function(String reason) onFailure;

  const _WebViewPayment({
    required this.url,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<_WebViewPayment> createState() => _WebViewPaymentState();
}

class _WebViewPaymentState extends State<_WebViewPayment> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الدفع')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onWebViewCreated: (controller) {},
        onLoadStop: (controller, url) {
          final urlStr = url?.toString() ?? '';
          // Paymob يرسل النتيجة على redirect
          if (urlStr.contains('success=true') ||
              urlStr.contains('/success')) {
            final uri = Uri.parse(urlStr);
            final txId = uri.queryParameters['id'] ?? 'paymob_ok';
            widget.onSuccess(txId);
          } else if (urlStr.contains('success=false') ||
              urlStr.contains('/failure')) {
            widget.onFailure('تم رفض الدفع');
          }
        },
      ),
    );
  }
}