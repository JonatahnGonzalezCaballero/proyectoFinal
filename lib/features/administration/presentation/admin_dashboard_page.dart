import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      (Icons.fact_check_outlined, 'Revisar propuestas', '/admin/proposals'),
      (Icons.how_to_vote_outlined, 'Gestionar votaciones', '/admin/votings'),
      (Icons.construction_outlined, 'Convertir propuesta en proyecto', '/admin/projects/create'),
      (Icons.people_outline, 'Gestión de usuarios', '/admin/users'),
      (Icons.category_outlined, 'Gestión de categorías', '/admin/categories'),
      (Icons.bar_chart_outlined, 'Métricas y reportes', '/admin/metrics'),
      (Icons.history_outlined, 'Auditoría', '/admin/audit'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Panel administrativo')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 2 : 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: opciones
            .map((o) => Card(
                  child: InkWell(
                    onTap: () => context.push(o.$3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(o.$1, size: 32),
                          const SizedBox(height: 8),
                          Text(o.$2, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}