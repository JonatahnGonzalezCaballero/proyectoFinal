import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../auth/application/auth_providers.dart';
import '../application/administration_providers.dart';
import '../domain/rol.dart';
import '../domain/usuario_admin.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosAdminProvider);
    final perfilAsync = ref.watch(perfilActualProvider);
    final miId = perfilAsync.value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: usuariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (usuarios) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final u = usuarios[index];
            return _TarjetaUsuario(usuario: u, esUsuarioActual: u.id == miId);
          },
        ),
      ),
    );
  }
}

class _TarjetaUsuario extends ConsumerStatefulWidget {
  const _TarjetaUsuario({required this.usuario, required this.esUsuarioActual});
  final UsuarioAdmin usuario;
  final bool esUsuarioActual;

  @override
  ConsumerState<_TarjetaUsuario> createState() => _TarjetaUsuarioState();
}

class _TarjetaUsuarioState extends ConsumerState<_TarjetaUsuario> {
  bool _procesando = false;

  Future<void> _cambiarRol(List<Rol> roles) async {
    final seleccionado = await showDialog<Rol>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Cambiar rol'),
        children: roles
            .map((r) => SimpleDialogOption(onPressed: () => Navigator.pop(context, r), child: Text(r.nombre)))
            .toList(),
      ),
    );
    if (seleccionado == null) return;
    await _actualizar(rolId: seleccionado.id, activo: widget.usuario.activo);
  }

  Future<void> _alternarActivo() async {
    await _actualizar(rolId: widget.usuario.rolId, activo: !widget.usuario.activo);
  }

  Future<void> _actualizar({required String rolId, required bool activo}) async {
    setState(() => _procesando = true);
    try {
      await ref
          .read(administrationRepositoryProvider)
          .actualizarUsuario(usuarioId: widget.usuario.id, rolId: rolId, activo: activo);
      ref.invalidate(usuariosAdminProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapSupabaseError(e).message)));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final rolesAsync = ref.watch(rolesProvider);

    return Card(
      child: ListTile(
        title: Text(u.nombreCompleto),
        subtitle: Text('${u.correo} · ${u.rolNombre} · ${u.activo ? "Activo" : "Inactivo"}'),
        trailing: widget.esUsuarioActual
            ? const Tooltip(message: 'No puedes modificar tu propia cuenta', child: Icon(Icons.lock_outline))
            : _procesando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : PopupMenuButton<String>(
                    onSelected: (accion) {
                      if (accion == 'rol') {
                        rolesAsync.whenData((roles) => _cambiarRol(roles));
                      } else if (accion == 'activo') {
                        _alternarActivo();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'rol', child: Text('Cambiar rol')),
                      PopupMenuItem(value: 'activo', child: Text(u.activo ? 'Desactivar' : 'Activar')),
                    ],
                  ),
      ),
    );
  }
}