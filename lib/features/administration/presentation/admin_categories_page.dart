import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/administration_providers.dart';
import '../domain/categoria_admin.dart';

class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  Future<void> _abrirFormulario(BuildContext context, WidgetRef ref, {CategoriaAdmin? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: existente?.descripcion ?? '');
    bool activo = existente?.activo ?? true;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existente == null ? 'Nueva categoría' : 'Editar categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
              if (existente != null)
                SwitchListTile(
                  title: const Text('Activa'),
                  value: activo,
                  onChanged: (v) => setState(() => activo = v),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (guardar != true || nombreCtrl.text.trim().isEmpty) return;

    try {
      final repo = ref.read(administrationRepositoryProvider);
      if (existente == null) {
        await repo.crearCategoria(nombre: nombreCtrl.text.trim(), descripcion: descripcionCtrl.text.trim());
      } else {
        await repo.actualizarCategoria(
          id: existente.id,
          nombre: nombreCtrl.text.trim(),
          descripcion: descripcionCtrl.text.trim(),
          activo: activo,
        );
      }
      ref.invalidate(categoriasAdminProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapSupabaseError(e).message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriasAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (categorias) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            final c = categorias[index];
            return Card(
              child: ListTile(
                title: Text(c.nombre),
                subtitle: Text(c.descripcion ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!c.activo) const Chip(label: Text('Inactiva')),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _abrirFormulario(context, ref, existente: c),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
    );
  }
}