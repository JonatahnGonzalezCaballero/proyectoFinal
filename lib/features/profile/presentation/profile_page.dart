import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/error_mapper.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _aliasCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _inicializado = false;
  bool _guardando = false;
  bool _subiendoAvatar = false;
  String? _error;

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiarAvatar() async {
    final archivo = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (archivo == null) return;
    setState(() => _subiendoAvatar = true);
    try {
      final Uint8List bytes = await archivo.readAsBytes();
      final extension = archivo.name.contains('.') ? archivo.name.split('.').last : 'jpg';
      await ref.read(profileRepositoryProvider).subirAvatar(bytes: bytes, extension: extension);
      ref.invalidate(perfilActualProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapSupabaseError(e).message)));
      }
    } finally {
      if (mounted) setState(() => _subiendoAvatar = false);
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).actualizarPerfil(
            alias: _aliasCtrl.text.trim().isEmpty ? null : _aliasCtrl.text.trim(),
            telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
          );
      ref.invalidate(perfilActualProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
      }
    } catch (e) {
      setState(() => _error = mapSupabaseError(e).message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilActualProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar tu perfil: $e')),
        data: (perfil) {
          if (perfil == null) return const Center(child: Text('No hay sesión activa.'));

          if (!_inicializado) {
            _aliasCtrl.text = perfil.alias ?? '';
            _telefonoCtrl.text = perfil.telefono ?? '';
            _inicializado = true;
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundImage: perfil.avatarUrl != null ? NetworkImage(perfil.avatarUrl!) : null,
                          child: perfil.avatarUrl == null
                              ? Text(
                                  perfil.nombreCompleto.isNotEmpty ? perfil.nombreCompleto[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                        if (_subiendoAvatar)
                          const Positioned.fill(
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.black45,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton.filled(
                            onPressed: _subiendoAvatar ? null : _cambiarAvatar,
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(perfil.nombreCompleto, style: Theme.of(context).textTheme.titleLarge),
                    Text(perfil.rolNombre, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(perfil.correo),
                      subtitle: const Text('Correo (no editable)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aliasCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alias público',
                        helperText: 'Así aparecerás en tus propuestas. Vacío = se usa tu nombre completo.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}