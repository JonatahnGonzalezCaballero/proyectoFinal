import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilActualProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authRepositoryProvider).cerrarSesion(),
          ),
        ],
      ),
      body: Center(
        child: perfilAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('No se pudo cargar tu perfil: $error'),
          data: (perfil) {
            if (perfil == null) return const Text('No hay sesión activa.');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bienvenido, ${perfil.nombreCompleto}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Rol: ${perfil.rolNombre}'),
                                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => context.push('/proposals'),
                  child: const Text('Ver propuestas'),
                ),
                if (perfil.esAdministrador) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/admin/proposals'),
                    child: const Text('Revisar propuestas'),
                  ),
                ],
                                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => context.push('/votings'),
                  child: const Text('Ver votaciones'),
                ),
                if (perfil.esAdministrador) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/admin/votings'),
                    child: const Text('Gestionar votaciones'),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => context.push('/projects'),
                  child: const Text('Ver proyectos'),
                ),
                if (perfil.esAdministrador) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/admin/projects/create'),
                    child: const Text('Convertir propuesta en proyecto'),
                  ),
                ],
                if (perfil.esAdministrador) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/admin'),
                    child: const Text('Ir al panel administrativo'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}