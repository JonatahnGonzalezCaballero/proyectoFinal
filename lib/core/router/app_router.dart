import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/administration/presentation/admin_page.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../shared/providers/supabase_provider.dart';

/// Adapta un Stream a Listenable para que go_router reevalúe redirect()
/// cada vez que cambia el estado de sesión de Supabase.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

const _rutasPublicas = {'/', '/login', '/register', '/forgot-password', '/reset-password'};

final routerProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(client.auth.onAuthStateChange),
    redirect: (context, state) async {
      final estaAutenticado = client.auth.currentSession != null;
      final destino = state.matchedLocation;
      final esRutaPublica = _rutasPublicas.contains(destino);

      if (!estaAutenticado) {
        return esRutaPublica ? null : '/login';
      }

      if (destino == '/login' || destino == '/register' || destino == '/') {
        return '/home';
      }

      if (destino.startsWith('/admin')) {
        final perfil = await ref.read(perfilActualProvider.future);
        if (perfil == null || !perfil.esAdministrador) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
    ],
  );
});