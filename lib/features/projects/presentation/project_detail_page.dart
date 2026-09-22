import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_providers.dart';
import '../application/projects_providers.dart';
import '../../../shared/widgets/estado_pill.dart';
import '../../../shared/widgets/imagen_con_zoom.dart';
import '../../../shared/widgets/global_appbar_actions.dart';
import '../../../shared/widgets/info_row.dart';
import '../../../core/theme/app_theme.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.proyectoId});
  final String proyectoId;

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectoAsync = ref.watch(proyectoProvider(proyectoId));
    final actualizacionesAsync = ref.watch(actualizacionesProyectoProvider(proyectoId));
    final perfilAsync = ref.watch(perfilActualProvider);
    final esAdmin = perfilAsync.value?.esAdministrador ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Proyecto'), actions: const [GlobalAppBarActions()]),
      floatingActionButton: esAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/projects/$proyectoId/update'),
              icon: const Icon(Icons.add),
              label: const Text('Registrar avance'),
            )
          : null,
      body: proyectoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.titulo, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              // Chip(label: Text(p.estadoLegible)),
              EstadoPill(estado: p.estado, etiqueta: p.estadoLegible),
              const SizedBox(height: 8),
              InfoRow(icono: Icons.assignment_outlined, texto: 'A partir de: ${p.propuestaTitulo}'),
              InfoRow(icono: Icons.person_outline, texto: 'Responsable: ${p.responsableNombre}'),
              if (p.fechaInicio != null) InfoRow(icono: Icons.calendar_today_outlined, texto: 'Inicio: ${_fmt(p.fechaInicio!)}'),
              if (p.fechaFinEstimada != null) InfoRow(icono: Icons.event_outlined, texto: 'Fin estimado: ${_fmt(p.fechaFinEstimada!)}'),
              if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(p.descripcion!),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Avance del proyecto', style: Theme.of(context).textTheme.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.menta, borderRadius: BorderRadius.circular(999)),
                    child: Text('${p.porcentajeAvance}%', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C6A00), fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: p.porcentajeAvance / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.guijarro,
                  valueColor: const AlwaysStoppedAnimation(AppColors.violeta),
                ),
              ),
              if (esAdmin) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    if (p.estado == 'planeado')
                      OutlinedButton(
                        onPressed: () => ref
                            .read(projectsRepositoryProvider)
                            .actualizarEstado(proyectoId: p.id, nuevoEstado: 'en_ejecucion')
                            .then((_) => ref.invalidate(proyectoProvider(proyectoId))),
                        child: const Text('Marcar en ejecución'),
                      ),
                    if (p.estado == 'en_ejecucion')
                      OutlinedButton(
                        onPressed: () => ref
                            .read(projectsRepositoryProvider)
                            .actualizarEstado(proyectoId: p.id, nuevoEstado: 'suspendido')
                            .then((_) => ref.invalidate(proyectoProvider(proyectoId))),
                        child: const Text('Suspender'),
                      ),
                    if (p.estado == 'suspendido')
                      OutlinedButton(
                        onPressed: () => ref
                            .read(projectsRepositoryProvider)
                            .actualizarEstado(proyectoId: p.id, nuevoEstado: 'en_ejecucion')
                            .then((_) => ref.invalidate(proyectoProvider(proyectoId))),
                        child: const Text('Reanudar'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text('Historial de avances', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              actualizacionesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('No se pudo cargar el historial: $e'),
                data: (actualizaciones) {
                  if (actualizaciones.isEmpty) return const Text('Aún no se han registrado avances.');
                  return Column(
                    children: actualizaciones
                        .map((a) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_fmt(a.fecha), style: Theme.of(context).textTheme.bodySmall),
                                        if (a.porcentajeAvance != null) Text('${a.porcentajeAvance}%'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(a.descripcion),
                                    Text('Por: ${a.autorNombre}', style: Theme.of(context).textTheme.bodySmall),
                                    if (a.archivos.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: a.archivos.map((ev) => _EvidenciaImagen(path: ev.url)).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenciaImagen extends ConsumerWidget {
  const _EvidenciaImagen({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(urlFirmadaEvidenciaProvider(path));
    return urlAsync.when(
      loading: () => const SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(width: 100, height: 100, child: Icon(Icons.broken_image)),
      data: (url) => ImagenConZoom(imageProvider: NetworkImage(url), width: 100, height: 100),
    );
  }
}

/* class _EvidenciaImagen extends ConsumerWidget {
  const _EvidenciaImagen({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(urlFirmadaEvidenciaProvider(path));
    return urlAsync.when(
      loading: () => const SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(width: 100, height: 100, child: Icon(Icons.broken_image)),
      data: (url) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
      ),
    );
  }
} */