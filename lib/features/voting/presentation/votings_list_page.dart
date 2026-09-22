import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/voting_providers.dart';
import '../../../shared/widgets/global_appbar_actions.dart';

class VotingsListPage extends ConsumerWidget {
  const VotingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(votacionesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Votaciones'), actions: const [GlobalAppBarActions()]),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (votaciones) {
          if (votaciones.isEmpty) return const Center(child: Text('No hay votaciones registradas.'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(votacionesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: votaciones.length,
              itemBuilder: (context, index) {
                final v = votaciones[index];
                return Card(
                  child: ListTile(
                    title: Text(v.titulo),
                    subtitle: Text(v.estadoLegible),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/votings/${v.id}'),
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