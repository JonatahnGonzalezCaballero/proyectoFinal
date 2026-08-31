import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../data/proposals_repository.dart';
import '../domain/categoria.dart';
import '../domain/propuesta.dart';

final proposalsRepositoryProvider = Provider<ProposalsRepository>((ref) {
  return ProposalsRepository(ref.watch(supabaseClientProvider));
});

final categoriasProvider = FutureProvider<List<Categoria>>((ref) {
  return ref.watch(proposalsRepositoryProvider).listarCategorias();
});

final misPropuestasProvider = FutureProvider.autoDispose<List<Propuesta>>((ref) {
  return ref.watch(proposalsRepositoryProvider).listarMisPropuestas();
});

final propuestasComunidadProvider = FutureProvider.autoDispose<List<Propuesta>>((ref) {
  return ref.watch(proposalsRepositoryProvider).listarPropuestasComunidad();
});

final propuestasPendientesProvider = FutureProvider.autoDispose<List<Propuesta>>((ref) {
  return ref.watch(proposalsRepositoryProvider).listarPendientesRevision();
});

final detallePropuestaProvider =
    FutureProvider.autoDispose.family<Propuesta, String>((ref, id) {
  return ref.watch(proposalsRepositoryProvider).obtenerDetalle(id);
});

final urlFirmadaProvider =
    FutureProvider.autoDispose.family<String, String>((ref, path) {
  final client = ref.watch(supabaseClientProvider);
  return client.storage.from('propuestas').createSignedUrl(path, 3600);
});