import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../data/auth_repository.dart';
import '../domain/perfil_usuario.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Perfil con rol del usuario autenticado
final perfilActualProvider = FutureProvider<PerfilUsuario?>((ref) async {
  final authState = ref.watch(authStateChangesProvider).value;
  final client = ref.watch(supabaseClientProvider);
  final session = authState?.session ?? client.auth.currentSession;

  if (session == null) return null;

    final data = await client
      .from('usuarios')
      .select('id, nombre_completo, correo, activo, alias, telefono, avatar_url, roles(nombre)')
      .eq('id', session.user.id)
      .single();
      
  return PerfilUsuario.fromMap(data);
});