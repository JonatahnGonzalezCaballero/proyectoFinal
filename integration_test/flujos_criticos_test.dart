import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_final/core/config/supabase_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;
  final correoPrueba = 'prueba_${DateTime.now().millisecondsSinceEpoch}@example.com';
  const passwordPrueba = 'Prueba123456';

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
    client = Supabase.instance.client;

    await client.auth.signUp(
      email: correoPrueba,
      password: passwordPrueba,
      data: {'nombre_completo': 'Test QA'},
    );
    await client.auth.signInWithPassword(email: correoPrueba, password: passwordPrueba);
  });

  tearDownAll(() async {
    await client.auth.signOut();
  });

  testWidgets('Registro y login', (tester) async {
    expect(client.auth.currentSession, isNotNull);
  });

  testWidgets('Un ciudadano puede crear una propuesta', (tester) async {
    final categorias = await client.from('categorias').select('id').limit(1);
    expect(categorias, isNotEmpty);

    final propuesta = await client.from('propuestas').insert({
      'usuario_id': client.auth.currentUser!.id,
      'categoria_id': categorias.first['id'],
      'titulo': 'Propuesta de prueba automatizada',
      'descripcion': 'Descripción de prueba con más de veinte caracteres.',
    }).select('id, estado').single();

    expect(propuesta['estado'], 'pendiente');

    // Esta prueba sí puede borrar lo que ella misma creó.
    await client.from('propuestas').delete().eq('id', propuesta['id']);
  });

  testWidgets('Evitar doble voto: el segundo intento falla', (tester) async {
    const votacionIdPrueba = '59feb752-7745-4c71-bcb4-8d64b77d0388';
    const opcionIdPrueba = '58f19a40-d08b-4efe-8373-17f0ea28aca7';

    await client.rpc('emitir_voto', params: {'p_votacion_id': votacionIdPrueba, 'p_opcion_id': opcionIdPrueba});

    expect(
      () => client.rpc('emitir_voto', params: {'p_votacion_id': votacionIdPrueba, 'p_opcion_id': opcionIdPrueba}),
      throwsA(anything),
    );
  });

  testWidgets('Consultar un proyecto existente', (tester) async {
    final proyectos = await client.from('proyectos').select('id, titulo, porcentaje_avance').limit(1);
    expect(proyectos, isNotEmpty);
  });
}