/// 📦 مرجع الأصول والملفات
class AssetsRes {
  AssetsRes._();

  // ═══════════════════════════════════════════════════════
  // 🌍 ملفات البيئة (موجودة في assets/)
  // ═══════════════════════════════════════════════════════

  static const String ENV = 'assets/.env';
  static const String ENV_DEVELOPMENT = 'assets/.env.development';
  static const String ENV_STAGING = 'assets/.env.staging';
  static const String ENV_PRODUCTION = 'assets/.env.production';

  // ═══════════════════════════════════════════════════════
  // 🖼️ صور
  // ═══════════════════════════════════════════════════════

  static const String LOGO = 'assets/images/logo.png';
  static const String PLACEHOLDER = 'assets/images/placeholder.png';
  static const String EMPTY_STATE = 'assets/images/empty_state.png';
  static const String ERROR_STATE = 'assets/images/error_state.png';

  // ═══════════════════════════════════════════════════════
  // 🎨 أيقونات
  // ═══════════════════════════════════════════════════════

  static const String ICON_HOME = 'assets/icons/home.svg';
  static const String ICON_PROFILE = 'assets/icons/profile.svg';
  static const String ICON_CART = 'assets/icons/cart.svg';
  static const String ICON_ORDERS = 'assets/icons/orders.svg';
  static const String ICON_SETTINGS = 'assets/icons/settings.svg';
}