import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../proposals/domain/propuesta.dart';
import '../data/voting_repository.dart';
import '../domain/opcion_votacion.dart';
import '../domain/resultado_opcion.dart';
import '../domain/votacion.dart';

final votingRepositoryProvider = Provider<VotingRepository>((ref) {
  return VotingRepository(ref.watch(supabaseClientProvider));
});

final votacionesProvider = FutureProvider.autoDispose<List<Votacion>>((ref) {
  return ref.watch(votingRepositoryProvider).listarVotaciones();
});

final votacionProvider = FutureProvider.autoDispose.family<Votacion, String>((ref, id) {
  return ref.watch(votingRepositoryProvider).obtenerVotacion(id);
});

final opcionesVotacionProvider =
    FutureProvider.autoDispose.family<List<OpcionVotacion>, String>((ref, votacionId) {
  return ref.watch(votingRepositoryProvider).listarOpciones(votacionId);
});

final yaVotoProvider = FutureProvider.autoDispose.family<bool, String>((ref, votacionId) {
  return ref.watch(votingRepositoryProvider).yaVoto(votacionId);
});

final resultadosVotacionProvider =
    FutureProvider.autoDispose.family<List<ResultadoOpcion>, String>((ref, votacionId) {
  return ref.watch(votingRepositoryProvider).obtenerResultados(votacionId);
});

final propuestasAprobadasParaVotacionProvider = FutureProvider.autoDispose<List<Propuesta>>((ref) {
  return ref.watch(votingRepositoryProvider).listarPropuestasAprobadasParaVotacion();
});