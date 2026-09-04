import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/metrics_providers.dart';

class AdminMetricsPage extends ConsumerWidget {
  const AdminMetricsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(metricasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(metricasProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (m) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 2 : 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _TarjetaMetrica('Usuarios registrados', '${m.usuariosRegistrados}'),
                  _TarjetaMetrica('Propuestas registradas', '${m.propuestasRegistradas}'),
                  _TarjetaMetrica('Propuestas aprobadas', '${m.propuestasAprobadas}'),
                  _TarjetaMetrica('Propuestas rechazadas', '${m.propuestasRechazadas}'),
                  _TarjetaMetrica('Votaciones activas', '${m.votacionesActivas}'),
                  _TarjetaMetrica('Votaciones finalizadas', '${m.votacionesFinalizadas}'),
                  _TarjetaMetrica('Total de votos', '${m.totalVotos}'),
                  _TarjetaMetrica('Proyectos activos', '${m.proyectosActivos}'),
                  _TarjetaMetrica('Proyectos finalizados', '${m.proyectosFinalizados}'),
                  _TarjetaMetrica('Participación', '${m.nivelParticipacion}%'),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: m.reporteTexto));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Reporte copiado al portapapeles.')));
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaMetrica extends StatelessWidget {
  const _TarjetaMetrica(this.titulo, this.valor);
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(valor, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}