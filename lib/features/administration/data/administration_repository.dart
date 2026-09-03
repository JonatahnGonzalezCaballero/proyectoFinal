import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/categoria_admin.dart';
import '../domain/rol.dart';
import '../domain/usuario_admin.dart';

class AdministrationRepository {
  AdministrationRepository(this._client);
  final SupabaseClient _client;

  Future<List<UsuarioAdmin>> listarUsuarios() async {
    final data =
        await _client.from('usuarios').select('*, roles(nombre)').order('fecha_registro', ascending: false);
    return data.map((m) => UsuarioAdmin.fromMap(m)).toList();
  }

  Future<List<Rol>> listarRoles() async {
    final data = await _client.from('roles').select().order('nombre');
    return data.map((m) => Rol.fromMap(m)).toList();
  }

  Future<void> actualizarUsuario({
    required String usuarioId,
    required String rolId,
    required bool activo,
  }) async {
    await _client.rpc('admin_actualizar_usuario', params: {
      'p_usuario_id': usuarioId,
      'p_rol_id': rolId,
      'p_activo': activo,
    });
  }

  Future<List<CategoriaAdmin>> listarCategorias() async {
    final data = await _client.from('categorias').select().order('nombre');
    return data.map((m) => CategoriaAdmin.fromMap(m)).toList();
  }

  Future<void> crearCategoria({required String nombre, String? descripcion}) async {
    await _client.from('categorias').insert({'nombre': nombre, 'descripcion': descripcion});
  }

  Future<void> actualizarCategoria({
    required String id,
    required String nombre,
    String? descripcion,
    required bool activo,
  }) async {
    await _client
        .from('categorias')
        .update({'nombre': nombre, 'descripcion': descripcion, 'activo': activo})
        .eq('id', id);
  }
}