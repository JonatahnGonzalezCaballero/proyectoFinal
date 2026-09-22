import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/voting_providers.dart';
import '../../../shared/widgets/estado_pill.dart';
import '../../../shared/widgets/global_appbar_actions.dart';
import '../../../shared/widgets/info_row.dart';
import 'resultado_barra.dart';

class VotingDetailPage extends ConsumerStatefulWidget {
  const VotingDetailPage({super.key, required this.votacionId});
  final String votacionId;

  @override
  ConsumerState<VotingDetailPage> createState() => _VotingDetailPageState();
}

class _VotingDetailPageState extends ConsumerState<VotingDetailPage> {
  bool _votando = false;
  String? _error;

  Future<void> _votar(String opcionId) async {
    setState(() {
      _votando = true;
      _error = null;
    });
    try {
      await ref.read(votingRepositoryProvider).emitirVoto(votacionId: widget.votacionId, opcionId: opcionId);
      ref.invalidate(yaVotoProvider(widget.votacionId));
      ref.invalidate(resultadosVotacionProvider(widget.votacionId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Voto registrado. ¡Gracias por participar!')));
      }
    } catch (e) {
      setState(() => _error = mapSupabaseError(e).message);
    } finally {
      if (mounted) setState(() => _votando = false);
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final votacionAsync = ref.watch(votacionProvider(widget.votacionId));
    final opcionesAsync = ref.watch(opcionesVotacionProvider(widget.votacionId));
    final yaVotoAsync = ref.watch(yaVotoProvider(widget.votacionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Votación'), actions: const [GlobalAppBarActions()]),
      body: votacionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (votacion) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(votacion.titulo, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              EstadoPill(estado: votacion.estado, etiqueta: votacion.estadoLegible),
              const SizedBox(height: 8),
              InfoRow(icono: Icons.calendar_today_outlined, texto: 'Del ${_fmt(votacion.fechaInicio)} al ${_fmt(votacion.fechaFin)}'),
              InfoRow(icono: Icons.label_outline, texto: votacion.esSiNo ? 'Votación Sí/No' : 'Selección múltiple'),
              if (votacion.descripcion != null && votacion.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(votacion.descripcion!),
              ],
              const SizedBox(height: 24),
              yaVotoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('No se pudo verificar tu participación: $e'),
                data: (yaVoto) {
                  final mostrarResultados = yaVoto || votacion.estado == 'finalizada';
                  final permiteVotar = !yaVoto && votacion.estaAbierta;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (yaVoto)
                        const Text('Ya registraste tu voto en esta votación.',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      if (permiteVotar)
                        opcionesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('No se pudieron cargar las opciones: $e'),
                          data: (opciones) {
                            if (opciones.isEmpty) return const SizedBox.shrink();

                            if (votacion.esSiNo) {
                              final propuestaTitulo = opciones.first.propuestaTitulo;
                              final propuestaDescripcion = opciones.first.propuestaDescripcion;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('¿Está de acuerdo con la siguiente propuesta?',
                                      style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(propuestaTitulo, style: Theme.of(context).textTheme.titleSmall),
                                          if (propuestaDescripcion != null && propuestaDescripcion.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(propuestaDescripcion),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_votando)
                                    const Center(child: CircularProgressIndicator())
                                  else
                                    Row(
                                      children: opciones
                                          .map((o) => Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: FilledButton(
                                                    onPressed: () => _votar(o.id),
                                                    child: Text(o.tituloMostrado),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Elige una opción:', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                ...opciones.map((o) => Card(
                                      child: ListTile(
                                        title: Text(o.tituloMostrado),
                                        trailing: _votando
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2))
                                            : FilledButton(
                                                onPressed: () => _votar(o.id), child: const Text('Votar')),
                                      ),
                                    )),
                              ],
                            );
                          },
                        ),
                      if (!permiteVotar && !yaVoto)
                        Text(votacion.estado == 'programada'
                            ? 'Esta votación aún no ha iniciado.'
                            : 'Esta votación no está abierta actualmente.'),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      if (mostrarResultados) ...[
                        const SizedBox(height: 24),
                        Text('Resultados', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Consumer(builder: (context, ref, _) {
                          final resultadosAsync = ref.watch(resultadosVotacionProvider(widget.votacionId));
                          return resultadosAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => Text('No se pudieron cargar los resultados: $e'),
                            data: (resultados) {
                              final total = resultados.fold<int>(0, (s, r) => s + r.totalVotos);
                              final maxVotos = resultados.isEmpty
                                  ? 0
                                  : resultados.map((r) => r.totalVotos).reduce((a, b) => a > b ? a : b);
                              return Column(
                                children: resultados
                                    .map((r) => ResultadoBarra(
                                          etiqueta: r.opcionTitulo,
                                          votos: r.totalVotos,
                                          totalVotos: total,
                                          esLider: maxVotos > 0 && r.totalVotos == maxVotos,
                                        ))
                                    .toList(),
                              );
                            },
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}