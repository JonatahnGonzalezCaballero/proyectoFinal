import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/projects_providers.dart';
import '../../../shared/widgets/global_appbar_actions.dart';

class ProjectsListPage extends ConsumerWidget {
  const ProjectsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proyectosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Proyectos'), actions: const [GlobalAppBarActions()]),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (proyectos) {
          if (proyectos.isEmpty) return const Center(child: Text('Aún no hay proyectos en seguimiento.'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(proyectosProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: proyectos.length,
              itemBuilder: (context, index) {
                final p = proyectos[index];
                return Card(
                  child: ListTile(
                    title: Text(p.titulo),
                    subtitle: Text('${p.estadoLegible} · ${p.porcentajeAvance}% completado'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/projects/${p.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}