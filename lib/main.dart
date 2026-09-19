import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/cache/hive_cache_service.dart';
import 'core/network/supabase_client.dart';
import 'core/notifications/notification_service.dart';
import 'res/assets_res.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🟢 [1/4] Loading ${AssetsRes.ENV}');
    await dotenv.load(fileName: AssetsRes.ENV);
    debugPrint('🟢 [1/4] ✓ Env loaded');

    debugPrint('🟢 [2/4] Initializing Hive');
    await HiveCacheService.init();
    debugPrint('🟢 [2/4] ✓ Hive OK');

    debugPrint('🟢 [3/4] Initializing Supabase');
    await SupabaseClientProvider.initialize();
    debugPrint('🟢 [3/4] ✓ Supabase OK');

    debugPrint('🟢 [4/4] Initializing Firebase & Notifications');
    try {
      await Firebase.initializeApp();
      await NotificationService.initialize();
      debugPrint('🟢 [4/4] ✓ Firebase & Notifications OK');
    } catch (e) {
      debugPrint('⚠️ Firebase/Notifications failed: $e');
      debugPrint('⚠️ Continuing without notifications.');
    }

    debugPrint('🚀 runApp()');
    runApp(const ProviderScope(child: WaffartApp()));
  } catch (e, st) {
    debugPrint('❌❌❌ FATAL ERROR: $e');
    debugPrint('❌❌❌ STACK: $st');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'فشل التهيئة:\n\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}