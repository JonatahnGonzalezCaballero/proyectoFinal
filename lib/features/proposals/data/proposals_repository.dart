import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/categoria.dart';
import '../domain/propuesta.dart';

class ProposalsRepository {
  ProposalsRepository(this._client);
  final SupabaseClient _client;

  static const _selectConLookups =
      '*, categorias(nombre), propuesta_archivos(id, url)';

  Future<List<Categoria>> listarCategorias() async {
    final data = await _client
        .from('categorias')
        .select('id, nombre')
        .eq('activo', true)
        .order('nombre');
    return data.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<List<Propuesta>> listarMisPropuestas() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('propuestas')
        .select(_selectConLookups)
        .eq('usuario_id', userId)
        .order('fecha_creacion', ascending: false);
    return data.map((m) => Propuesta.fromMap(m)).toList();
  }

  Future<List<Propuesta>> listarPropuestasComunidad() async {
    final data = await _client
        .from('propuestas')
        .select(_selectConLookups)
        .eq('estado', 'aprobada')
        .order('fecha_creacion', ascending: false);
    return data.map((m) => Propuesta.fromMap(m)).toList();
  }

  Future<List<Propuesta>> listarPendientesRevision() async {
    final data = await _client
        .from('propuestas')
        .select(_selectConLookups)
        .inFilter('estado', ['pendiente', 'en_revision'])
        .order('fecha_creacion');
    return data.map((m) => Propuesta.fromMap(m)).toList();
  }

  Future<Propuesta> obtenerDetalle(String id) async {
    final data = await _client
        .from('propuestas')
        .select(_selectConLookups)
        .eq('id', id)
        .single();
    return Propuesta.fromMap(data);
  }

  Future<String> crearPropuesta({
    required String categoriaId,
    required String titulo,
    required String descripcion,
    String? ubicacion,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('propuestas')
        .insert({
          'usuario_id': userId,
          'categoria_id': categoriaId,
          'titulo': titulo,
          'descripcion': descripcion,
          'ubicacion': ubicacion,
        })
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> actualizarPropuesta({
    required String id,
    required String categoriaId,
    required String titulo,
    required String descripcion,
    String? ubicacion,
  }) async {
    await _client.from('propuestas').update({
      'categoria_id': categoriaId,
      'titulo': titulo,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
    }).eq('id', id);
  }

  Future<void> subirImagen({
    required String propuestaId,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final ruta = '$userId/$propuestaId/$nombreArchivo';

    await _client.storage.from('propuestas').uploadBinary(
          ruta,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await _client.from('propuesta_archivos').insert({
      'propuesta_id': propuestaId,
      'url': ruta,
      'tipo': 'imagen',
    });
  }

  Future<void> marcarEnRevision(String id) async {
    await _client.from('propuestas').update({'estado': 'en_revision'}).eq('id', id);
  }

  Future<void> aprobar({required String id, String? observaciones}) async {
    await _client.rpc('aprobar_propuesta', params: {
      'p_propuesta_id': id,
      'p_observaciones': observaciones,
    });
  }

  Future<void> rechazar({required String id, required String observaciones}) async {
    await _client.rpc('rechazar_propuesta', params: {
      'p_propuesta_id': id,
      'p_observaciones': observaciones,
    });
  }
}