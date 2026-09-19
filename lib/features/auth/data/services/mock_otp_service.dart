import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class MockOtpService {
  MockOtpService._();
  static final MockOtpService instance = MockOtpService._();

  // ═══════════════════════════════════════════════════════
  // ⚙️ الإعدادات (زودنا الصلاحية عشان التجربة)
  // ═══════════════════════════════════════════════════════

  static const Duration validityDuration = Duration(minutes: 5); // ✅ 5 دقائق
  static const Duration displayDuration = Duration(minutes: 5);  // ✅ الرمز يفضل ظاهر
  static const int codeLength = 6;

  String? _currentCode;
  String? _currentPhone;
  DateTime? _generatedAt;
  Timer? _expiryTimer;

  String? get currentCode => _currentCode;
  String? get currentPhone => _currentPhone;
  bool get hasActiveCode => _currentCode != null && !isExpired;

  bool get isExpired {
    if (_generatedAt == null) return true;
    return DateTime.now().difference(_generatedAt!) > validityDuration;
  }

  Duration get displayRemaining {
    if (_generatedAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_generatedAt!);
    final left = displayDuration - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  Duration get validityRemaining {
    if (_generatedAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_generatedAt!);
    final left = validityDuration - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  String generate(String phone) {
    final rng = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < codeLength; i++) {
      buffer.write(rng.nextInt(10));
    }

    _currentCode = buffer.toString();
    _currentPhone = phone;
    _generatedAt = DateTime.now();

    debugPrint('🧪 MOCK OTP for $phone → $_currentCode '
        '(valid ${validityDuration.inMinutes} min)');

    _expiryTimer?.cancel();
    _expiryTimer = Timer(validityDuration, () {
      debugPrint('🧪 MOCK OTP expired');
      _currentCode = null;
      _currentPhone = null;
      _generatedAt = null;
    });

    return _currentCode!;
  }

  MockOtpResult verify(String input) {
    if (_currentCode == null || _generatedAt == null) {
      return MockOtpResult.noCode;
    }
    if (isExpired) return MockOtpResult.expired;
    if (input.trim() != _currentCode) return MockOtpResult.wrongCode;
    return MockOtpResult.success;
  }

  void clear() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _currentCode = null;
    _currentPhone = null;
    _generatedAt = null;
    debugPrint('🧪 MOCK OTP cleared');
  }
}

enum MockOtpResult { success, expired, noCode, wrongCode }