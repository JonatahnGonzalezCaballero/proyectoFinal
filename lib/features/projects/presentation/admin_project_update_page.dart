import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/projects_providers.dart';

class AdminProjectUpdatePage extends ConsumerStatefulWidget {
  const AdminProjectUpdatePage({super.key, required this.proyectoId});
  final String proyectoId;

  @override
  ConsumerState<AdminProjectUpdatePage> createState() => _AdminProjectUpdatePageState();
}

class _AdminProjectUpdatePageState extends ConsumerState<AdminProjectUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  double _porcentaje = 0;
  bool _actualizarPorcentaje = false;
  final List<XFile> _evidencias = [];
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarEvidencias() async {
    final archivos = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (archivos.isNotEmpty) setState(() => _evidencias.addAll(archivos));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final repo = ref.read(projectsRepositoryProvider);
      final actualizacionId = await repo.registrarAvance(
        proyectoId: widget.proyectoId,
        descripcion: _descripcionCtrl.text.trim(),
        porcentajeAvance: _actualizarPorcentaje ? _porcentaje.round() : null,
      );

      for (final evidencia in _evidencias) {
        final Uint8List bytes = await evidencia.readAsBytes();
        await repo.subirEvidencia(
          proyectoId: widget.proyectoId,
          actualizacionId: actualizacionId,
          bytes: bytes,
          nombreArchivo: evidencia.name,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avance registrado.')));
      context.pop();
    } catch (e) {
      setState(() => _error = mapSupabaseError(e).message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar avance')),
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
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción del avance'),
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().length < 10) ? 'Describe el avance realizado' : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Actualizar porcentaje de avance'),
                    value: _actualizarPorcentaje,
                    onChanged: (v) => setState(() => _actualizarPorcentaje = v),
                  ),
                  if (_actualizarPorcentaje) ...[
                    Text('${_porcentaje.round()}%'),
                    Slider(
                      value: _porcentaje,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${_porcentaje.round()}%',
                      onChanged: (v) => setState(() => _porcentaje = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _seleccionarEvidencias,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_evidencias.isEmpty
                        ? 'Adjuntar evidencias'
                        : '${_evidencias.length} imagen(es) seleccionada(s)'),
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
                        : const Text('Guardar avance'),
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