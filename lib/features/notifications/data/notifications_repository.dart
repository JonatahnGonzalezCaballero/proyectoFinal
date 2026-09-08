import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notificacion.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Notificacion>> listar() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('notificaciones')
        .select()
        .eq('usuario_id', userId)
        .order('fecha', ascending: false);
    return data.map((m) => Notificacion.fromMap(m)).toList();
  }

  Future<int> contarNoLeidas() async {
    final userId = _client.auth.currentUser!.id;
    final data =
        await _client.from('notificaciones').select('id').eq('usuario_id', userId).eq('leida', false);
    return data.length;
  }

  Future<void> marcarLeida(String id) async {
    await _client.from('notificaciones').update({'leida': true}).eq('id', id);
  }

  Future<void> marcarTodasLeidas() async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('notificaciones').update({'leida': true}).eq('usuario_id', userId).eq('leida', false);
  }

  Future<bool> obtenerPreferenciaExterna() async {
    final userId = _client.auth.currentUser!.id;
    final data =
        await _client.from('usuarios').select('notificaciones_externas_activas').eq('id', userId).single();
    return data['notificaciones_externas_activas'] as bool? ?? true;
  }

  Future<void> actualizarPreferenciaExterna(bool activas) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('usuarios').update({'notificaciones_externas_activas': activas}).eq('id', userId);
  }
}