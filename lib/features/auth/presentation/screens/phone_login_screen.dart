import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/mock_otp_service.dart';
import '../providers/auth_provider.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  Timer? _uiTimer;
  Duration _validityRemaining = Duration.zero;
  String? _generatedCode;

  @override
  void initState() {
    super.initState();
    _startUiTicker();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startUiTicker() {
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_otpSent) return;
      final service = MockOtpService.instance;
      setState(() {
        _validityRemaining = service.validityRemaining;
        _generatedCode = service.currentCode;
      });
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showSnack('أدخل رقم هاتف صحيح (10 أرقام على الأقل)');
      return;
    }

    FocusScope.of(context).unfocus();
    final code = MockOtpService.instance.generate(phone);

    if (!mounted) return;
    setState(() {
      _otpSent = true;
      _generatedCode = code;
      _validityRemaining = MockOtpService.instance.validityRemaining;
    });

    // ✅ auto-fill الـ OTP عشان التجربة
    _otpController.text = code;
  }

  Future<void> _verify() async {
    final input = _otpController.text.trim();
    if (input.length != 6) {
      _showSnack('أدخل 6 أرقام');
      return;
    }

    final result = MockOtpService.instance.verify(input);

    switch (result) {
    // ═══════════════════════════════════════════════════
    // ✅ نجاح — سجّل دخول (الراوتر هيتنقل تلقائيًا)
    // ═══════════════════════════════════════════════════
      case MockOtpResult.success:
      // 🧹 امسح الرمز
        MockOtpService.instance.clear();

        // 🎭 اقرأ الدور المختار
        final role = ref.read(selectedRoleProvider);

        // 🔐 سجّل دخول
        await ref.read(authControllerProvider.notifier).signIn(
          AppUser(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            phone: _phoneController.text.trim(),
            fullName: 'مستخدم ${role.labelAr}',
            role: role.key,
          ),
        );

        // 🚀 الراوتر هيتنقل تلقائيًا (refreshListenable + redirect)
        // مفيش حاجة لـ context.go هنا
        break;

    // ═══════════════════════════════════════════════════
    // ❌ انتهت الصلاحية
    // ═══════════════════════════════════════════════════
      case MockOtpResult.expired:
        _showSnack('انتهت صلاحية الرمز. اطلب رمزًا جديدًا.');
        break;

    // ═══════════════════════════════════════════════════
    // ❌ مفيش رمز نشط
    // ═══════════════════════════════════════════════════
      case MockOtpResult.noCode:
        _showSnack('لم يتم إرسال رمز بعد. اضغط "إرسال رمز التحقق".');
        break;

    // ═══════════════════════════════════════════════════
    // ❌ الرمز غلط
    // ═══════════════════════════════════════════════════
      case MockOtpResult.wrongCode:
        _showSnack('رمز التحقق غير صحيح');
        break;
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(selectedRoleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════════════════
            // 🎭 اختيار الدور
            // ═══════════════════════════════════════════════
            const Text(
              'اختر نوع الحساب',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: UserRole.values.map((role) {
                final selected = selectedRole == role;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(role.labelAr),
                      selected: selected,
                      onSelected: _otpSent
                          ? null
                          : (_) => ref
                          .read(selectedRoleProvider.notifier)
                          .state = role,
                      avatar: Icon(
                        role == UserRole.customer
                            ? Icons.person
                            : role == UserRole.vendor
                            ? Icons.store
                            : Icons.admin_panel_settings,
                        size: 18,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════
            // 📱 رقم الهاتف
            // ═══════════════════════════════════════════════
            TextField(
              controller: _phoneController,
              enabled: !_otpSent,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (!_otpSent)
              ElevatedButton.icon(
                onPressed: _sendOtp,
                icon: const Icon(Icons.send),
                label: const Text('إرسال رمز التحقق'),
              ),

            if (_otpSent) ...[
              const SizedBox(height: 8),

              // ═══════════════════════════════════════════════
              // 🧪 عرض الرمز
              // ═══════════════════════════════════════════════
              if (_generatedCode != null && _validityRemaining > Duration.zero)
                Card(
                  color: Colors.amber.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          '🧪 رمز التحقق (وضع التطوير)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _generatedCode!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'صالح لمدة: ${_validityRemaining.inMinutes}:${(_validityRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Card(
                  color: Colors.redAccent,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '❌ انتهت صلاحية الرمز — اطلب رمزًا جديدًا',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ═══════════════════════════════════════════════
              // 🔢 حقل إدخال الرمز
              // ═══════════════════════════════════════════════
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'أدخل الرمز',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _verify,
                icon: const Icon(Icons.login),
                label: const Text('تحقق وسجّل الدخول'),
              ),
              TextButton(
                onPressed: _sendOtp,
                child: const Text('إعادة إرسال الرمز'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}