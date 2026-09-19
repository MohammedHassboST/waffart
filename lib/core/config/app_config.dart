import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl =>
      dotenv.env['https://gkjgwbwmucotqftbhgyn.supabase.co'] ?? '';
  static String get supabasePublishableKey =>
      dotenv.env['sb_publishable_yKElKni4v28LWb3KiW-mrg_efIyVuU0'] ?? '';

  // Paymob
  static String get paymobApiKey => dotenv.env['PAYMOB_API_KEY'] ?? '';
  static String get paymobIntegrationId =>
      dotenv.env['PAYMOB_INTEGRATION_ID'] ?? '';
  static String get paymobIframeId => dotenv.env['PAYMOB_IFRAME_ID'] ?? '';

  // Stripe
  static String get stripeSecretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
}