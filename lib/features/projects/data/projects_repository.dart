import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../proposals/domain/propuesta.dart';
import '../domain/actualizacion_proyecto.dart';
import '../domain/proyecto.dart';

class ProjectsRepository {
  ProjectsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Proyecto>> listarProyectos() async {
    final data = await _client
        .from('proyectos')
        .select('*, propuestas(titulo), usuarios(nombre_completo)')
        .order('fecha_creacion', ascending: false);
    return data.map((m) => Proyecto.fromMap(m)).toList();
  }

  Future<Proyecto> obtenerProyecto(String id) async {
    final data = await _client
        .from('proyectos')
        .select('*, propuestas(titulo), usuarios(nombre_completo)')
        .eq('id', id)
        .single();
    return Proyecto.fromMap(data);
  }

  Future<List<ActualizacionProyecto>> listarActualizaciones(String proyectoId) async {
    final data = await _client
        .from('proyecto_actualizaciones')
        .select('*, usuarios(nombre_completo), proyecto_archivos(id, url)')
        .eq('proyecto_id', proyectoId)
        .order('fecha', ascending: false);
    return data.map((m) => ActualizacionProyecto.fromMap(m)).toList();
  }

  Future<List<Propuesta>> listarPropuestasConvertibles() async {
    final data = await _client
        .from('propuestas')
        .select('*, categorias(nombre), propuesta_archivos(id, url)')
        .eq('estado', 'aprobada')
        .order('fecha_creacion', ascending: false);
    return data.map((m) => Propuesta.fromMap(m)).toList();
  }

  Future<String> crearProyectoDesdePropuesta({
    required String propuestaId,
    required String titulo,
    required String descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFinEstimada,
  }) async {
    final id = await _client.rpc('crear_proyecto_desde_propuesta', params: {
      'p_propuesta_id': propuestaId,
      'p_titulo': titulo,
      'p_descripcion': descripcion,
      'p_fecha_inicio': fechaInicio?.toIso8601String().split('T').first,
      'p_fecha_fin_estimada': fechaFinEstimada?.toIso8601String().split('T').first,
    });
    return id as String;
  }

  Future<String> registrarAvance({
    required String proyectoId,
    required String descripcion,
    int? porcentajeAvance,
  }) async {
    final id = await _client.rpc('registrar_avance_proyecto', params: {
      'p_proyecto_id': proyectoId,
      'p_descripcion': descripcion,
      'p_porcentaje_avance': porcentajeAvance,
    });
    return id as String;
  }

  Future<void> subirEvidencia({
    required String proyectoId,
    required String actualizacionId,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final ruta = '$proyectoId/$actualizacionId/$nombreArchivo';

    await _client.storage.from('evidencias').uploadBinary(
          ruta,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await _client.from('proyecto_archivos').insert({
      'actualizacion_id': actualizacionId,
      'url': ruta,
      'tipo': 'imagen',
    });
  }

  Future<void> actualizarEstado({required String proyectoId, required String nuevoEstado}) async {
    await _client.rpc('actualizar_estado_proyecto', params: {
      'p_proyecto_id': proyectoId,
      'p_nuevo_estado': nuevoEstado,
    });
  }
}