import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../proposals/domain/propuesta.dart';
import '../data/projects_repository.dart';
import '../domain/actualizacion_proyecto.dart';
import '../domain/proyecto.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(supabaseClientProvider));
});

final proyectosProvider = FutureProvider.autoDispose<List<Proyecto>>((ref) {
  return ref.watch(projectsRepositoryProvider).listarProyectos();
});

final proyectoProvider = FutureProvider.autoDispose.family<Proyecto, String>((ref, id) {
  return ref.watch(projectsRepositoryProvider).obtenerProyecto(id);
});

final actualizacionesProyectoProvider =
    FutureProvider.autoDispose.family<List<ActualizacionProyecto>, String>((ref, proyectoId) {
  return ref.watch(projectsRepositoryProvider).listarActualizaciones(proyectoId);
});

final propuestasConvertiblesProvider = FutureProvider.autoDispose<List<Propuesta>>((ref) {
  return ref.watch(projectsRepositoryProvider).listarPropuestasConvertibles();
});

/// URL firmada para evidencias (bucket privado), igual que con imágenes de propuestas.
final urlFirmadaEvidenciaProvider = FutureProvider.autoDispose.family<String, String>((ref, path) {
  final client = ref.watch(supabaseClientProvider);
  return client.storage.from('evidencias').createSignedUrl(path, 3600);
});