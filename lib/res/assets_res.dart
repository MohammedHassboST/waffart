/// 📦 مرجع الأصول والملفات
///
/// ⚠️ ملاحظة مهمة:
/// أي ثابت هنا يجب أن يكون ملفه موجوداً فعلاً داخل المجلد المذكور
/// وأن يكون المجلد معلناً في `pubspec.yaml` تحت `flutter: assets:`.
///
/// المجلدات المعلنة حالياً:
/// - assets/.env*
/// - assets/images/
/// - assets/icons/
class AssetsRes {
  AssetsRes._();

  // ═══════════════════════════════════════════════════════
  // 🌍 ملفات البيئة (معلنة في pubspec.yaml)
  // ═══════════════════════════════════════════════════════

  static const String ENV = 'assets/.env';
  static const String ENV_DEVELOPMENT = 'assets/.env.development';
  static const String ENV_STAGING = 'assets/.env.staging';
  static const String ENV_PRODUCTION = 'assets/.env.production';

// static const String LOGO = 'assets/images/logo.png';
// static const String PLACEHOLDER = 'assets/images/placeholder.png';
// static const String EMPTY_STATE = 'assets/images/empty_state.png';
// static const String ERROR_STATE = 'assets/images/error_state.png';

// ═══════════════════════════════════════════════════════
// 🎨 أيقونات
//
// ⚠️ أضف هذه الملفات فعلياً في assets/icons/ ثم أزل التعليق
// ═══════════════════════════════════════════════════════

// static const String ICON_HOME = 'assets/icons/home.svg';
// static const String ICON_PROFILE = 'assets/icons/profile.svg';
// static const String ICON_CART = 'assets/icons/cart.svg';
// static const String ICON_ORDERS = 'assets/icons/orders.svg';
// static const String ICON_SETTINGS = 'assets/icons/settings.svg';
}