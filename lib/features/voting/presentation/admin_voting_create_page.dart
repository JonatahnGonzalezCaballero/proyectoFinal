import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/voting_providers.dart';

class AdminVotingCreatePage extends ConsumerStatefulWidget {
  const AdminVotingCreatePage({super.key});

  @override
  ConsumerState<AdminVotingCreatePage> createState() => _AdminVotingCreatePageState();
}

class _AdminVotingCreatePageState extends ConsumerState<AdminVotingCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final Set<String> _propuestasSeleccionadas = {};
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
      firstDate: ahora.subtract(const Duration(days: 1)),
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (hora == null) return;
    final fechaCompleta = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    setState(() => esInicio ? _fechaInicio = fechaCompleta : _fechaFin = fechaCompleta);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _error = 'Selecciona fecha de inicio y de fin');
      return;
    }
    if (!_fechaFin!.isAfter(_fechaInicio!)) {
      setState(() => _error = 'La fecha de fin debe ser posterior a la de inicio');
      return;
    }
    if (_propuestasSeleccionadas.length < 2) {
      setState(() => _error = 'Selecciona al menos dos propuestas');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(votingRepositoryProvider).crearVotacion(
            titulo: _tituloCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
            propuestaIds: _propuestasSeleccionadas.toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votación creada.')));
      context.pop();
    } catch (e) {
      setState(() => _error = mapSupabaseError(e).message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final propuestasAsync = ref.watch(propuestasAprobadasParaVotacionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva votación')),
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
                          child: Text(_fechaFin == null ? 'Fecha de fin' : _fmt(_fechaFin!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Propuestas aprobadas disponibles', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  propuestasAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('No se pudieron cargar: $e'),
                    data: (propuestas) {
                      if (propuestas.isEmpty) {
                        return const Text('No hay propuestas aprobadas todavía para incluir en una votación.');
                      }
                      return Column(
                        children: propuestas
                            .map((p) => CheckboxListTile(
                                  title: Text(p.titulo),
                                  subtitle: Text(p.categoriaNombre),
                                  value: _propuestasSeleccionadas.contains(p.id),
                                  onChanged: (marcado) => setState(() {
                                    if (marcado == true) {
                                      _propuestasSeleccionadas.add(p.id);
                                    } else {
                                      _propuestasSeleccionadas.remove(p.id);
                                    }
                                  }),
                                ))
                            .toList(),
                      );
                    },
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
                        : const Text('Crear votación'),
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