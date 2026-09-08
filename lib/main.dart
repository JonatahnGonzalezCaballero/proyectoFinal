import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/firebase_options_manual.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/notifications/application/notifications_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
  await Firebase.initializeApp(options: firebaseOptionsActuales);

  runApp(const ProviderScope(child: ComunidadBgaApp()));
}

class ComunidadBgaApp extends ConsumerWidget {
  const ComunidadBgaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.value?.event == AuthChangeEvent.signedIn) {
        ref.read(pushRepositoryProvider).registrarDispositivo();
      }
    });

    return MaterialApp.router(
      title: 'Comunidad BGA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}