import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/proposals_providers.dart';
import '../domain/propuesta.dart';

class ProposalFormPage extends ConsumerStatefulWidget {
  const ProposalFormPage({super.key, this.propuestaExistente});
  final Propuesta? propuestaExistente;

  @override
  ConsumerState<ProposalFormPage> createState() => _ProposalFormPageState();
}

class _ProposalFormPageState extends ConsumerState<ProposalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  String? _categoriaId;
  final List<XFile> _imagenesNuevas = [];
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.propuestaExistente != null;

  @override
  void initState() {
    super.initState();
    final p = widget.propuestaExistente;
    if (p != null) {
      _tituloCtrl.text = p.titulo;
      _descripcionCtrl.text = p.descripcion;
      _ubicacionCtrl.text = p.ubicacion ?? '';
      _categoriaId = p.categoriaId;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagenes() async {
    final archivos = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (archivos.isNotEmpty) setState(() => _imagenesNuevas.addAll(archivos));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _categoriaId == null) {
      setState(() => _error = _categoriaId == null ? 'Selecciona una categoría' : null);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final repo = ref.read(proposalsRepositoryProvider);
      final String propuestaId;

      if (_esEdicion) {
        propuestaId = widget.propuestaExistente!.id;
        await repo.actualizarPropuesta(
          id: propuestaId,
          categoriaId: _categoriaId!,
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          ubicacion: _ubicacionCtrl.text.trim().isEmpty ? null : _ubicacionCtrl.text.trim(),
        );
      } else {
        propuestaId = await repo.crearPropuesta(
          categoriaId: _categoriaId!,
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          ubicacion: _ubicacionCtrl.text.trim().isEmpty ? null : _ubicacionCtrl.text.trim(),
        );
      }

      for (final imagen in _imagenesNuevas) {
        final Uint8List bytes = await imagen.readAsBytes();
        await repo.subirImagen(propuestaId: propuestaId, bytes: bytes, nombreArchivo: imagen.name);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_esEdicion ? 'Propuesta actualizada.' : 'Propuesta creada.')),
      );
      context.pop();
    } catch (e) {
      setState(() => _error = mapSupabaseError(e).message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar propuesta' : 'Nueva propuesta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => (v == null || v.trim().length < 5) ? 'Mínimo 5 caracteres' : null,
                  ),
                  const SizedBox(height: 16),
                  categoriasAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('No se pudieron cargar las categorías: $e'),
                    data: (categorias) => DropdownButtonFormField<String>(
                      initialValue: _categoriaId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: categorias
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoriaId = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 5,
                    validator: (v) =>
                        (v == null || v.trim().length < 20) ? 'Describe tu propuesta (mínimo 20 caracteres)' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ubicacionCtrl,
                    decoration: const InputDecoration(labelText: 'Ubicación (opcional)'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _seleccionarImagenes,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_imagenesNuevas.isEmpty
                        ? 'Adjuntar imágenes'
                        : '${_imagenesNuevas.length} imagen(es) seleccionada(s)'),
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
                        : Text(_esEdicion ? 'Guardar cambios' : 'Enviar propuesta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}