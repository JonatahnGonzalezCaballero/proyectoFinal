import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/administration/presentation/admin_categories_page.dart';
import '../../features/administration/presentation/admin_dashboard_page.dart';
import '../../features/administration/presentation/admin_users_page.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/presentation/welcome_page.dart';
import '../../features/metrics/presentation/admin_audit_page.dart';
import '../../features/metrics/presentation/admin_metrics_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/projects/presentation/admin_project_create_page.dart';
import '../../features/projects/presentation/admin_project_update_page.dart';
import '../../features/projects/presentation/project_detail_page.dart';
import '../../features/projects/presentation/projects_list_page.dart';
import '../../features/proposals/domain/propuesta.dart';
import '../../features/proposals/presentation/admin_proposal_review_page.dart';
import '../../features/proposals/presentation/proposal_detail_page.dart';
import '../../features/proposals/presentation/proposal_form_page.dart';
import '../../features/proposals/presentation/proposals_list_page.dart';
import '../../features/voting/presentation/admin_voting_create_page.dart';
import '../../features/voting/presentation/admin_votings_list_page.dart';
import '../../features/voting/presentation/voting_detail_page.dart';
import '../../features/voting/presentation/votings_list_page.dart';
import '../../shared/providers/supabase_provider.dart';
import '../../shared/widgets/app_shell.dart';

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
    initialLocation: '/',
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
      GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordPage()),

      // Rutas ciudadanas — envueltas en la barra lateral en pantallas anchas.
      ShellRoute(
        builder: (context, state, child) => AppShell(state: state, child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(path: '/proposals', builder: (context, state) => const ProposalsListPage()),
          GoRoute(path: '/proposals/create', builder: (context, state) => const ProposalFormPage()),
          GoRoute(
            path: '/proposals/:id',
            builder: (context, state) => ProposalDetailPage(propuestaId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/proposals/:id/edit',
            builder: (context, state) => ProposalFormPage(propuestaExistente: state.extra as Propuesta),
          ),
          GoRoute(path: '/votings', builder: (context, state) => const VotingsListPage()),
          GoRoute(
            path: '/votings/:id',
            builder: (context, state) => VotingDetailPage(votacionId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/projects', builder: (context, state) => const ProjectsListPage()),
          GoRoute(
            path: '/projects/:id',
            builder: (context, state) => ProjectDetailPage(proyectoId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ],
      ),

      // Rutas administrativas — sin barra lateral por ahora.
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardPage()),
      GoRoute(path: '/admin/proposals', builder: (context, state) => const AdminProposalReviewPage()),
      GoRoute(path: '/admin/votings', builder: (context, state) => const AdminVotingsListPage()),
      GoRoute(path: '/admin/votings/create', builder: (context, state) => const AdminVotingCreatePage()),
      GoRoute(path: '/admin/projects/create', builder: (context, state) => const AdminProjectCreatePage()),
      GoRoute(
        path: '/admin/projects/:id/update',
        builder: (context, state) => AdminProjectUpdatePage(proyectoId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/users', builder: (context, state) => const AdminUsersPage()),
      GoRoute(path: '/admin/categories', builder: (context, state) => const AdminCategoriesPage()),
      GoRoute(path: '/admin/metrics', builder: (context, state) => const AdminMetricsPage()),
      GoRoute(path: '/admin/audit', builder: (context, state) => const AdminAuditPage()),
    ],
  );
});