import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  static Future<void> initialize() async {
    // ✅ نقرأ بأسماء المفاتيح (مش القيم)
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'] ??
        dotenv.env['SUPABASE_PUBLISHABLE_KEY']; // fallback للاسم الجديد

    debugPrint('🔍 URL: ${url ?? "EMPTY"}');
    debugPrint('🔍 Key length: ${key?.length ?? 0}');

    if (url == null || url.isEmpty) {
      throw Exception(
        '❌ SUPABASE_URL فاضي! تأكد إن ملف .env فيه سطر SUPABASE_URL=...',
      );
    }
    if (key == null || key.isEmpty) {
      throw Exception(
        '❌ SUPABASE_ANON_KEY فاضي! تأكد إن ملف .env فيه سطر SUPABASE_ANON_KEY=...',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: key,
    );

    debugPrint('✅ Supabase initialized');
  }

  static SupabaseClient get client => Supabase.instance.client;
}