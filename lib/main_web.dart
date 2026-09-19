import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/supabase_client.dart';
import 'res/assets_res.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: AssetsRes.ENV);
  await SupabaseClientProvider.initialize();
  runApp(const ProviderScope(child: WaffartWebApp()));
}

class WaffartWebApp extends StatelessWidget {
  const WaffartWebApp({super.key});

  @override
  Widget build(BuildContext context) => const WaffartApp();
}