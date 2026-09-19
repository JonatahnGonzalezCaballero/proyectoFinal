import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_providers.dart';
import '../application/proposals_providers.dart';
import '../../../shared/widgets/estado_pill.dart';
import '../../../shared/widgets/imagen_con_zoom.dart';

class ProposalDetailPage extends ConsumerWidget {
  const ProposalDetailPage({super.key, required this.propuestaId});
  final String propuestaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detallePropuestaProvider(propuestaId));
    final perfilAsync = ref.watch(perfilActualProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de propuesta')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar la propuesta: $e')),
        data: (p) {
          final esDueno = perfilAsync.value?.id == p.usuarioId;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.titulo, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                EstadoPill(estado: p.estado, etiqueta: p.estadoLegible),
                const SizedBox(height: 4),
                Text('Publicado por ${p.autorNombre}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Text('Categoría: ${p.categoriaNombre}'),
                if (p.ubicacion != null && p.ubicacion!.isNotEmpty) Text('Ubicación: ${p.ubicacion}'),
                const SizedBox(height: 16),
                Text(p.descripcion),
                if (p.observaciones != null && p.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Observaciones del revisor:', style: Theme.of(context).textTheme.titleSmall),
                  Text(p.observaciones!),
                ],
                if (p.archivos.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Imágenes', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.archivos.map((a) => _ImagenPropuesta(path: a.url)).toList(),
                  ),
                ],
                if (esDueno && p.esEditable) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/proposals/${p.id}/edit', extra: p),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar propuesta'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImagenPropuesta extends ConsumerWidget {
  const _ImagenPropuesta({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(urlFirmadaProvider(path));
    return urlAsync.when(
      loading: () => const SizedBox(width: 120, height: 120, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(width: 120, height: 120, child: Icon(Icons.broken_image)),
      data: (url) => ImagenConZoom(imageProvider: NetworkImage(url), width: 120, height: 120),
    );
  }
}