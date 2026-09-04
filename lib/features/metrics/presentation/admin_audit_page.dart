import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/metrics_providers.dart';

class AdminAuditPage extends ConsumerWidget {
  const AdminAuditPage({super.key});

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditoriaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Auditoría')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (registros) {
          if (registros.isEmpty) return const Center(child: Text('No hay registros de auditoría todavía.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: registros.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = registros[index];
              return ListTile(
                title: Text('${r.accion} · ${r.entidad}'),
                subtitle: Text('${r.usuarioNombre} — ${_fmt(r.fecha)}'),
              );
            },
          );
        },
      ),
    );
  }
}