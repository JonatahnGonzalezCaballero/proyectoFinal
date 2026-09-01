import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/voting_providers.dart';
import '../domain/votacion.dart';

class AdminVotingsListPage extends ConsumerWidget {
  const AdminVotingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(votacionesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de votaciones')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (votaciones) {
          if (votaciones.isEmpty) return const Center(child: Text('No hay votaciones creadas.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: votaciones.length,
            itemBuilder: (context, index) => _TarjetaVotacionAdmin(votacion: votaciones[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/votings/create'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva votación'),
      ),
    );
  }
}

class _TarjetaVotacionAdmin extends ConsumerStatefulWidget {
  const _TarjetaVotacionAdmin({required this.votacion});
  final Votacion votacion;

  @override
  ConsumerState<_TarjetaVotacionAdmin> createState() => _TarjetaVotacionAdminState();
}

class _TarjetaVotacionAdminState extends ConsumerState<_TarjetaVotacionAdmin> {
  bool _procesando = false;

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _procesando = true);
    try {
      await ref.read(votingRepositoryProvider).cambiarEstado(votacionId: widget.votacion.id, nuevoEstado: nuevoEstado);
      ref.invalidate(votacionesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapSupabaseError(e).message)));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.votacion;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(v.estadoLegible),
            const SizedBox(height: 12),
            if (_procesando)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                children: [
                  if (v.estado == 'programada') ...[
                    FilledButton(onPressed: () => _cambiarEstado('activa'), child: const Text('Activar')),
                    OutlinedButton(
                      onPressed: () => _cambiarEstado('cancelada'),
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Cancelar'),
                    ),
                  ],
                  if (v.estado == 'activa')
                    FilledButton(onPressed: () => _cambiarEstado('finalizada'), child: const Text('Finalizar')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}