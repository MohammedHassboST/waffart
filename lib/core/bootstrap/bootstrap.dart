import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../cache/hive_cache_service.dart';
import '../network/supabase_client.dart';
import '../notifications/notification_service.dart';
import 'error_app.dart';

/// 🚀 تهيئة موحدة لكل بيئات التشغيل
Future<void> bootstrap({required String envFile}) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ─────────────────────────────────────────────────────
    // [1/4] تحميل متغيرات البيئة
    // ─────────────────────────────────────────────────────
    debugPrint('🟢 [1/4] Loading env: $envFile');
    await dotenv.load(fileName: envFile);
    debugPrint('🟢 [1/4] ✓ Env loaded');

    // ─────────────────────────────────────────────────────
    // [2/4] تهيئة Hive (يعمل على Web عبر IndexedDB)
    // ─────────────────────────────────────────────────────
    debugPrint('🟢 [2/4] Initializing Hive');
    await HiveCacheService.init();
    debugPrint('🟢 [2/4] ✓ Hive OK');

    // ─────────────────────────────────────────────────────
    // [3/4] تهيئة Supabase
    // ─────────────────────────────────────────────────────
    debugPrint('🟢 [3/4] Initializing Supabase');
    await SupabaseClientProvider.initialize();
    debugPrint('🟢 [3/4] ✓ Supabase OK');

    // ─────────────────────────────────────────────────────
    // [4/4] تهيئة Firebase & Notifications
    //      ⚠️ يتم تخطيها على Web لأن Firebase يحتاج إعداداً مختلفاً
    // ─────────────────────────────────────────────────────
    if (!kIsWeb) {
      debugPrint('🟢 [4/4] Initializing Firebase & Notifications');
      try {
        await Firebase.initializeApp();
        await NotificationService.initialize();
        debugPrint('🟢 [4/4] ✓ Firebase & Notifications OK');
      } catch (e) {
        // لا نُفشل التطبيق بالكامل إن فشل Firebase
        debugPrint('⚠️ Firebase/Notifications failed: $e');
        debugPrint('⚠️ Continuing without notifications.');
      }
    } else {
      debugPrint('🟢 [4/4] Skipped (Web platform)');
    }

    // ─────────────────────────────────────────────────────
    // ✅ تشغيل التطبيق
    // ─────────────────────────────────────────────────────
    debugPrint('🚀 runApp()');
    runApp(const ProviderScope(child: WaffartApp()));
  } catch (e, st) {
    debugPrint('❌❌❌ FATAL ERROR: $e');
    debugPrint('❌❌❌ STACK: $st');
    runApp(BootstrapErrorApp(error: e, stackTrace: st));
  }
}