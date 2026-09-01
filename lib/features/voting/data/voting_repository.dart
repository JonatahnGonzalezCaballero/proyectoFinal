import 'package:supabase_flutter/supabase_flutter.dart';

import '../../proposals/domain/propuesta.dart';
import '../domain/opcion_votacion.dart';
import '../domain/resultado_opcion.dart';
import '../domain/votacion.dart';

class VotingRepository {
  VotingRepository(this._client);
  final SupabaseClient _client;

  Future<List<Votacion>> listarVotaciones() async {
    final data = await _client.from('votaciones').select().order('fecha_creacion', ascending: false);
    return data.map((m) => Votacion.fromMap(m)).toList();
  }

  Future<Votacion> obtenerVotacion(String id) async {
    final data = await _client.from('votaciones').select().eq('id', id).single();
    return Votacion.fromMap(data);
  }

  Future<List<OpcionVotacion>> listarOpciones(String votacionId) async {
    final data = await _client
        .from('votacion_opciones')
        .select('id, propuesta_id, orden, propuestas(titulo)')
        .eq('votacion_id', votacionId)
        .order('orden');
    return data.map((m) => OpcionVotacion.fromMap(m)).toList();
  }

  Future<bool> yaVoto(String votacionId) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('voto_registros')
        .select('id')
        .eq('votacion_id', votacionId)
        .eq('usuario_id', userId)
        .maybeSingle();
    return data != null;
  }

  Future<List<ResultadoOpcion>> obtenerResultados(String votacionId) async {
    final data = await _client
        .from('resultados_votacion')
        .select()
        .eq('votacion_id', votacionId)
        .order('total_votos', ascending: false);
    return data.map((m) => ResultadoOpcion.fromMap(m)).toList();
  }

  Future<void> emitirVoto({required String votacionId, required String opcionId}) async {
    await _client.rpc('emitir_voto', params: {
      'p_votacion_id': votacionId,
      'p_opcion_id': opcionId,
    });
  }

  // --- Administración ---

  Future<List<Propuesta>> listarPropuestasAprobadasParaVotacion() async {
    final data = await _client
        .from('propuestas')
        .select('*, categorias(nombre), propuesta_archivos(id, url)')
        .eq('estado', 'aprobada')
        .order('fecha_creacion', ascending: false);
    return data.map((m) => Propuesta.fromMap(m)).toList();
  }

  Future<String> crearVotacion({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<String> propuestaIds,
  }) async {
    final id = await _client.rpc('crear_votacion', params: {
      'p_titulo': titulo,
      'p_descripcion': descripcion,
      'p_fecha_inicio': fechaInicio.toIso8601String(),
      'p_fecha_fin': fechaFin.toIso8601String(),
      'p_propuesta_ids': propuestaIds,
    });
    return id as String;
  }

  Future<void> cambiarEstado({required String votacionId, required String nuevoEstado}) async {
    await _client.rpc('actualizar_estado_votacion', params: {
      'p_votacion_id': votacionId,
      'p_nuevo_estado': nuevoEstado,
    });
  }
}