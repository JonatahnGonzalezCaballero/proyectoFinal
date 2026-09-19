import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notifications_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilActualProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Participa!!',style: GoogleFonts.lobster(fontSize: 34,),),
        actions: [
          Consumer(builder: (context, ref, _) {
            final noLeidasAsync = ref.watch(notificacionesNoLeidasProvider);
            final count = noLeidasAsync.value ?? 0;
            return IconButton(
              tooltip: 'Notificaciones',
              icon: Badge(label: Text('$count'), isLabelVisible: count > 0, child: const Icon(Icons.notifications_outlined)),
              onPressed: () => context.push('/notifications'),
            );
          }),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión', onPressed: () => ref.read(authRepositoryProvider).cerrarSesion()),
        ],
      ),
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar tu perfil: $e')),
        data: (perfil) {
          if (perfil == null) return const Center(child: Text('No hay sesión activa.'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: perfil.avatarUrl != null ? NetworkImage(perfil.avatarUrl!) : null,
                      child: perfil.avatarUrl == null
                          ? Text(perfil.nombreCompleto.isNotEmpty ? perfil.nombreCompleto[0].toUpperCase() : '?')
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hola, ${perfil.nombrePublico}', style: Theme.of(context).textTheme.titleLarge),
                          Text('¡Bienvenido a tu comunidad!', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _TarjetaAccion(icono: Icons.construction_outlined, etiqueta: 'Proyectos', color: AppColors.menta, onTap: () => context.push('/projects')),
                    _TarjetaAccion(icono: Icons.lightbulb_outline, etiqueta: 'Propuestas', color: AppColors.cielo, onTap: () => context.push('/proposals')),
                    _TarjetaAccion(icono: Icons.how_to_vote_outlined, etiqueta: 'Votaciones', color: AppColors.lavanda, onTap: () => context.push('/votings')),
                    _TarjetaAccion(icono: Icons.person_outline, etiqueta: 'Mi Perfil', color: AppColors.periwinkle, onTap: () => context.push('/profile')),
                    if (perfil.esAdministrador)
                      _TarjetaAccion(icono: Icons.admin_panel_settings_outlined, etiqueta: 'Administración', color: AppColors.agua, onTap: () => context.push('/admin')),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Actividad reciente', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, _) {
                  final notifAsync = ref.watch(notificacionesProvider);
                  return notifAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (lista) {
                      if (lista.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Sin actividad reciente.', style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          ...lista.take(3).map((n) => Card(
                                child: ListTile(
                                  dense: true,
                                  title: Text(n.titulo, style: TextStyle(fontWeight: n.leida ? FontWeight.normal : FontWeight.w600)),
                                  subtitle: Text(n.mensaje, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              )),
                          TextButton(onPressed: () => context.push('/notifications'), child: const Text('Ver todas')),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaAccion extends StatelessWidget {
  const _TarjetaAccion({required this.icono, required this.etiqueta, required this.color, required this.onTap});
  final IconData icono;
  final String etiqueta;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 32, color: AppColors.tinta),
              const SizedBox(height: 8),
              Text(etiqueta, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}