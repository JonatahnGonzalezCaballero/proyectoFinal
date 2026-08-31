import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/proposals_providers.dart';
import '../domain/propuesta.dart';

class ProposalsListPage extends ConsumerStatefulWidget {
  const ProposalsListPage({super.key});

  @override
  ConsumerState<ProposalsListPage> createState() => _ProposalsListPageState();
}

class _ProposalsListPageState extends ConsumerState<ProposalsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propuestas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis propuestas'),
            Tab(text: 'Comunidad'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListaPropuestas(provider: misPropuestasProvider, vacio: 'Aún no has creado propuestas.'),
          _ListaPropuestas(provider: propuestasComunidadProvider, vacio: 'No hay propuestas aprobadas todavía.'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/proposals/create'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva propuesta'),
      ),
    );
  }
}

class _ListaPropuestas extends ConsumerWidget {
  const _ListaPropuestas({required this.provider, required this.vacio});
  final FutureProvider<List<Propuesta>> provider; // antes: AutoDisposeFutureProvider
  final String vacio;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
      data: (propuestas) {
        if (propuestas.isEmpty) return Center(child: Text(vacio));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: propuestas.length,
            itemBuilder: (context, index) {
              final p = propuestas[index];
              return Card(
                child: ListTile(
                  title: Text(p.titulo),
                  subtitle: Text('${p.categoriaNombre} · ${p.estadoLegible}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/proposals/${p.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}