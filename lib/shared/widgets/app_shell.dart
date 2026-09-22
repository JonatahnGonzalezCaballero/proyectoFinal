import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/application/auth_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.state, required this.child});
  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho < Breakpoints.tabletMax) {
      return child;
    }

    final perfilAsync = ref.watch(perfilActualProvider);

    return Scaffold(
      body: Row(
        children: [
          _BarraLateral(ubicacionActual: state.matchedLocation, esAdmin: perfilAsync.value?.esAdministrador ?? false),
          const VerticalDivider(width: 1, color: AppColors.niebla),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BarraLateral extends StatelessWidget {
  const _BarraLateral({required this.ubicacionActual, required this.esAdmin});
  final String ubicacionActual;
  final bool esAdmin;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Inicio', '/home'),
      (Icons.construction_outlined, 'Proyectos', '/projects'),
      (Icons.lightbulb_outline, 'Propuestas', '/proposals'),
      (Icons.how_to_vote_outlined, 'Votaciones', '/votings'),
      (Icons.notifications_outlined, 'Notificaciones', '/notifications'),
      (Icons.person_outline, 'Mi Perfil', '/profile'),
    ];

    return Container(
      width: 240,
      color: AppColors.nieve,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo_nombre_arreglado.png',width: 98,height: 68,fit: BoxFit.contain,),
              ],
            ),
          ),
          const SizedBox(height: 32),
          for (final item in items)
            _ItemNav(icono: item.$1, etiqueta: item.$2, ruta: item.$3, activo: ubicacionActual.startsWith(item.$3)),
          if (esAdmin) ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider()),
            _ItemNav(icono: Icons.admin_panel_settings_outlined, etiqueta: 'Administración', ruta: '/admin', activo: ubicacionActual.startsWith('/admin'), usarPush: true),          ],
        ],
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({
    required this.icono,
    required this.etiqueta,
    required this.ruta,
    required this.activo,
    this.usarPush = false,
  });
  final IconData icono;
  final String etiqueta;
  final String ruta;
  final bool activo;
  final bool usarPush;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: activo ? AppColors.periwinkle : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => usarPush ? context.push(ruta) : context.go(ruta),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icono, size: 20, color: activo ? AppColors.violeta : AppColors.pizarra),
                const SizedBox(width: 12),
                Text(etiqueta, style: TextStyle(color: activo ? AppColors.violeta : AppColors.pizarra, fontWeight: activo ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}