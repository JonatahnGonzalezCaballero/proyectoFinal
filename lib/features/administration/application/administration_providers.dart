import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../data/administration_repository.dart';
import '../domain/categoria_admin.dart';
import '../domain/rol.dart';
import '../domain/usuario_admin.dart';

final administrationRepositoryProvider = Provider<AdministrationRepository>((ref) {
  return AdministrationRepository(ref.watch(supabaseClientProvider));
});

final usuariosAdminProvider = FutureProvider.autoDispose<List<UsuarioAdmin>>((ref) {
  return ref.watch(administrationRepositoryProvider).listarUsuarios();
});

final rolesProvider = FutureProvider.autoDispose<List<Rol>>((ref) {
  return ref.watch(administrationRepositoryProvider).listarRoles();
});

final categoriasAdminProvider = FutureProvider.autoDispose<List<CategoriaAdmin>>((ref) {
  return ref.watch(administrationRepositoryProvider).listarCategorias();
});