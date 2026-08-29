import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/providers/supabase_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _resultado = 'Aún no se ha probado la conexión.';
  bool _cargando = false;

  Future<void> _probarConexion() async {
    setState(() => _cargando = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final data = await client.from('roles').select();
      setState(() => _resultado =
          'Conexión con Supabase exitosa. Filas visibles sin sesión: '
          '${data.length} (0 es lo esperado: RLS oculta los datos hasta '
          'que inicies sesión, eso se prueba en la Fase 3).');
    } catch (e) {
      setState(() => _resultado = ' ${mapSupabaseError(e).message}');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad BGA — Fase 2')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width < 600 ? width * 0.9 : 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Entorno base configurado correctamente.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _probarConexion,
                  child: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Probar conexión con Supabase'),
                ),
                const SizedBox(height: 16),
                Text(_resultado, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}