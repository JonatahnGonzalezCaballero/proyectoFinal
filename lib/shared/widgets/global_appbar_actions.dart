import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/notifications/application/notifications_providers.dart';

class GlobalAppBarActions extends ConsumerWidget {
  const GlobalAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noLeidasAsync = ref.watch(notificacionesNoLeidasProvider);
    final perfilAsync = ref.watch(perfilActualProvider);
    final perfil = perfilAsync.value;
    final count = noLeidasAsync.value ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Notificaciones',
          icon: Badge(label: Text('$count'), isLabelVisible: count > 0, child: const Icon(Icons.notifications_outlined)),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión', onPressed: () => ref.read(authRepositoryProvider).cerrarSesion()),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.violeta,
              backgroundImage: perfil?.avatarUrl != null ? NetworkImage(perfil!.avatarUrl!) : null,
              child: perfil?.avatarUrl == null
                  ? Text((perfil?.nombreCompleto.isNotEmpty ?? false) ? perfil!.nombreCompleto[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12))
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}