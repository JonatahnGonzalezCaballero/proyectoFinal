import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/projects_providers.dart';

class AdminProjectCreatePage extends ConsumerStatefulWidget {
  const AdminProjectCreatePage({super.key});

  @override
  ConsumerState<AdminProjectCreatePage> createState() => _AdminProjectCreatePageState();
}

class _AdminProjectCreatePageState extends ConsumerState<AdminProjectCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String? _propuestaId;
  DateTime? _fechaInicio;
  DateTime? _fechaFinEstimada;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora.subtract(const Duration(days: 30)),
      lastDate: ahora.add(const Duration(days: 1825)),
    );
    if (fecha == null) return;
    setState(() => esInicio ? _fechaInicio = fecha : _fechaFinEstimada = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _propuestaId == null) {
      setState(() => _error = _propuestaId == null ? 'Selecciona la propuesta de origen' : null);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(projectsRepositoryProvider).crearProyectoDesdePropuesta(
            propuestaId: _propuestaId!,
            titulo: _tituloCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
            fechaInicio: _fechaInicio,
            fechaFinEstimada: _fechaFinEstimada,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proyecto creado.')));
      context.pop();
    } catch (e) {
      setState(() => _error = mapSupabaseError(e).message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final propuestasAsync = ref.watch(propuestasConvertiblesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo proyecto')),
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
                  Text('Propuesta de origen (aprobada)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  propuestasAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('No se pudieron cargar: $e'),
                    data: (propuestas) {
                      if (propuestas.isEmpty) {
                        return const Text('No hay propuestas aprobadas disponibles para convertir.');
                      }
                      return Column(
                        children: propuestas
                            .map((p) => RadioListTile<String>(
                                  title: Text(p.titulo),
                                  subtitle: Text(p.categoriaNombre),
                                  value: p.id,
                                  groupValue: _propuestaId,
                                  onChanged: (v) => setState(() {
                                    _propuestaId = v;
                                    if (_tituloCtrl.text.isEmpty) _tituloCtrl.text = p.titulo;
                                  }),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título del proyecto'),
                    validator: (v) => (v == null || v.trim().length < 5) ? 'Mínimo 5 caracteres' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _elegirFecha(esInicio: true),
                          child: Text(_fechaInicio == null ? 'Fecha de inicio' : _fmt(_fechaInicio!)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _elegirFecha(esInicio: false),
                          child: Text(_fechaFinEstimada == null ? 'Fin estimado' : _fmt(_fechaFinEstimada!)),
                        ),
                      ),
                    ],
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
                        : const Text('Crear proyecto'),
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