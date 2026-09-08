import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/notifications_providers.dart';

IconData _iconoPara(String? tipo) => switch (tipo) {
      'propuesta_aprobada' => Icons.check_circle_outline,
      'propuesta_rechazada' => Icons.cancel_outlined,
      'votacion_activa' => Icons.how_to_vote_outlined,
      'votacion_finalizada' => Icons.bar_chart_outlined,
      'proyecto_actualizado' => Icons.construction_outlined,
      _ => Icons.notifications_outlined,
    };

String _rutaPara(String? tipo) => switch (tipo) {
      'propuesta_aprobada' || 'propuesta_rechazada' => '/proposals',
      'votacion_activa' || 'votacion_finalizada' => '/votings',
      'proyecto_actualizado' => '/projects',
      _ => '/home',
    };

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificacionesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).marcarTodasLeidas();
              ref.invalidate(notificacionesProvider);
              ref.invalidate(notificacionesNoLeidasProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer(builder: (context, ref, _) {
            final prefAsync = ref.watch(preferenciaNotifExternaProvider);
            return prefAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (activas) => SwitchListTile(
                title: const Text('Recibir notificaciones por correo y celular'),
                subtitle: const Text('Las notificaciones dentro de la app siempre se mantienen activas.'),
                value: activas,
                onChanged: (v) async {
                  await ref.read(notificationsRepositoryProvider).actualizarPreferenciaExterna(v);
                  ref.invalidate(preferenciaNotifExternaProvider);
                },
              ),
            );
          }),
          const Divider(height: 1),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
              data: (notificaciones) {
                if (notificaciones.isEmpty) return const Center(child: Text('No tienes notificaciones.'));
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(notificacionesProvider),
                  child: ListView.separated(
                    itemCount: notificaciones.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = notificaciones[index];
                      return ListTile(
                        leading: Icon(_iconoPara(n.tipo)),
                        title: Text(n.titulo,
                            style: TextStyle(fontWeight: n.leida ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(n.mensaje),
                        trailing: n.leida ? null : const Icon(Icons.circle, size: 10, color: Colors.blue),
                        onTap: () async {
                          if (!n.leida) {
                            await ref.read(notificationsRepositoryProvider).marcarLeida(n.id);
                            ref.invalidate(notificacionesProvider);
                            ref.invalidate(notificacionesNoLeidasProvider);
                          }
                          if (context.mounted) context.push(_rutaPara(n.tipo));
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}