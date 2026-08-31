import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/proposals_providers.dart';
import '../domain/propuesta.dart';

class AdminProposalReviewPage extends ConsumerWidget {
  const AdminProposalReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(propuestasPendientesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revisión de propuestas')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (propuestas) {
          if (propuestas.isEmpty) return const Center(child: Text('No hay propuestas pendientes por revisar.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: propuestas.length,
            itemBuilder: (context, index) => _TarjetaRevision(propuesta: propuestas[index]),
          );
        },
      ),
    );
  }
}

class _TarjetaRevision extends ConsumerStatefulWidget {
  const _TarjetaRevision({required this.propuesta});
  final Propuesta propuesta;

  @override
  ConsumerState<_TarjetaRevision> createState() => _TarjetaRevisionState();
}

class _TarjetaRevisionState extends ConsumerState<_TarjetaRevision> {
  bool _procesando = false;

  Future<void> _accion(Future<void> Function() operacion) async {
    setState(() => _procesando = true);
    try {
      await operacion();
      ref.invalidate(propuestasPendientesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapSupabaseError(e).message)));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _rechazar() async {
    final motivo = await showDialog<String>(context: context, builder: (_) => const _DialogoMotivo());
    if (motivo == null || motivo.trim().isEmpty) return;
    final repo = ref.read(proposalsRepositoryProvider);
    await _accion(() => repo.rechazar(id: widget.propuesta.id, observaciones: motivo.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.propuesta;
    final repo = ref.read(proposalsRepositoryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${p.categoriaNombre} · ${p.estadoLegible}'),
            const SizedBox(height: 8),
            Text(p.descripcion, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            if (_procesando)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                children: [
                  if (p.estado == 'pendiente')
                    OutlinedButton(
                      onPressed: () => _accion(() => repo.marcarEnRevision(p.id)),
                      child: const Text('Marcar en revisión'),
                    ),
                  FilledButton(
                    onPressed: () => _accion(() => repo.aprobar(id: p.id)),
                    child: const Text('Aprobar'),
                  ),
                  OutlinedButton(
                    onPressed: _rechazar,
                    style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text('Rechazar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogoMotivo extends StatefulWidget {
  const _DialogoMotivo();

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motivo del rechazo'),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Explica por qué se rechaza la propuesta'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Rechazar')),
      ],
    );
  }
}