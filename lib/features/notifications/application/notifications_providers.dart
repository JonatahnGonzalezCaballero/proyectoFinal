import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../data/notifications_repository.dart';
import '../domain/notificacion.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

final notificacionesProvider = FutureProvider.autoDispose<List<Notificacion>>((ref) {
  return ref.watch(notificationsRepositoryProvider).listar();
});

final notificacionesNoLeidasProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).contarNoLeidas();
});