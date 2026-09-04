import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../data/metrics_repository.dart';
import '../domain/metricas.dart';
import '../domain/registro_auditoria.dart';

final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  return MetricsRepository(ref.watch(supabaseClientProvider));
});

final metricasProvider = FutureProvider.autoDispose<Metricas>((ref) {
  return ref.watch(metricsRepositoryProvider).obtenerMetricas();
});

final auditoriaProvider = FutureProvider.autoDispose<List<RegistroAuditoria>>((ref) {
  return ref.watch(metricsRepositoryProvider).listarAuditoria();
});