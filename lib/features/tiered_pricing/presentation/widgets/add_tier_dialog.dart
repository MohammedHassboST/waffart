import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../providers/tier_provider.dart';

class AddTierDialog extends ConsumerStatefulWidget {
  final String productId;
  const AddTierDialog({super.key, required this.productId});

  @override
  ConsumerState<AddTierDialog> createState() => _AddTierDialogState();
}

class _AddTierDialogState extends ConsumerState<AddTierDialog> {
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _price = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(tierRepositoryProvider).addTier(
        productId: widget.productId,
        minQuantity: int.parse(_min.text),
        maxQuantity: _max.text.isEmpty ? null : int.parse(_max.text),
        pricePerUnit: double.parse(_price.text),
      );
      ref.invalidate(productTiersProvider(widget.productId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة شريحة سعرية'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _min,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الحد الأدنى للكمية'),
              validator: (v) => Validators.required(v, 'الحد الأدنى'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الحد الأقصى (اتركه فارغاً للمفتوح)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السعر للوحدة'),
              validator: (v) => Validators.required(v, 'السعر'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
              height: 16, width: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('حفظ'),
        ),
      ],
    );
  }
}