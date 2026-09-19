import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(color: AppColors.periwinkle, borderRadius: BorderRadius.circular(24)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.groups_2_outlined, size: 96, color: AppColors.violeta),
                  ),
                  const SizedBox(height: 40),
                  Text('Participa en tu comunidad', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Propón, vota y da seguimiento a los proyectos que transforman tu barrio en Bucaramanga.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.pizarra),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: () => context.go('/register'), child: const Text('Comienza ahora'))),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.go('/login'), child: const Text('Ya tengo una cuenta'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}