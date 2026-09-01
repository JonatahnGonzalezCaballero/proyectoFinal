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
import '../../features/proposals/domain/propuesta.dart';
import '../../features/proposals/presentation/admin_proposal_review_page.dart';
import '../../features/proposals/presentation/proposal_detail_page.dart';
import '../../features/proposals/presentation/proposal_form_page.dart';
import '../../features/proposals/presentation/proposals_list_page.dart';
import '../../features/voting/presentation/admin_voting_create_page.dart';
import '../../features/voting/presentation/admin_votings_list_page.dart';
import '../../features/voting/presentation/voting_detail_page.dart';
import '../../features/voting/presentation/votings_list_page.dart';



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
      GoRoute(path: '/proposals', builder: (context, state) => const ProposalsListPage()),
      GoRoute(path: '/proposals/create', builder: (context, state) => const ProposalFormPage()),
      GoRoute(path: '/proposals/:id',builder: (context, state) => ProposalDetailPage(propuestaId: state.pathParameters['id']!),),
      GoRoute(path: '/proposals/:id/edit',builder: (context, state) => ProposalFormPage(propuestaExistente: state.extra as Propuesta),),
      GoRoute(path: '/admin/proposals', builder: (context, state) => const AdminProposalReviewPage()),
      GoRoute(path: '/votings', builder: (context, state) => const VotingsListPage()),
      GoRoute(path: '/votings/:id', builder: (context, state) => VotingDetailPage(votacionId: state.pathParameters['id']!),),
      GoRoute(path: '/admin/votings', builder: (context, state) => const AdminVotingsListPage()),
      GoRoute(path: '/admin/votings/create', builder: (context, state) => const AdminVotingCreatePage()),
    ],
  );
});