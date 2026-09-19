class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'رقم الهاتف مطلوب';
    final regex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!regex.hasMatch(value)) return 'رقم الهاتف غير صحيح';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'البريد الإلكتروني غير صحيح';
    return null;
  }

  static String? required(String? value, [String field = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) return '$field مطلوب';
    return null;
  }
}