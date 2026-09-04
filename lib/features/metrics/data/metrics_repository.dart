import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/metricas.dart';
import '../domain/registro_auditoria.dart';

class MetricsRepository {
  MetricsRepository(this._client);
  final SupabaseClient _client;

  Future<Metricas> obtenerMetricas() async {
    final data = await _client.rpc('obtener_metricas');
    return Metricas.fromMap(data as Map<String, dynamic>);
  }

  Future<List<RegistroAuditoria>> listarAuditoria({int limite = 100}) async {
    final data = await _client
        .from('auditoria')
        .select('*, usuarios(nombre_completo)')
        .order('fecha', ascending: false)
        .limit(limite);
    return data.map((m) => RegistroAuditoria.fromMap(m)).toList();
  }
}